;+
;FUNCTION:   mvn_swe_esuppress
;PURPOSE:
;  Calculates the SWEA electron suppression constant (Ke).  The correction is
;  based on monthly calibration sequences, during which the sweep table
;  alternates between table 5 (V0 disabled) and table 6 (V0 enabled) several
;  times.
;
;  Empirically, the energy dependence of the suppression behaves as if there
;  is a slightly different work function near the entrance aperture (top cap 
;  and entrance to concentric hemispheres) compared with the hemispheres closer 
;  to the MCP.  This is modeled as two ESA's in series that have different 
;  analyzer constants.  The functional form of the correction factor is then an 
;  exponential:
;
;      correction factor = exp(-(Ke/E_in)^2.)
;
;  where E_in is the energy of the electron interior to the toroidal grids.
;  When Ke = 0, the correction factor is unity.  Otherwise, there is a steep 
;  drop in sensitivity for E_in <~ Ke.
;
;  This is the same functional form as observed for STATIC ion suppression.
;  For STATIC, there is a clear time dependence over the mission and a 
;  directionality (mainly in RAM) that points to the influence of atomic O
;  on internal STATIC surfaces, which are coated with CuO (commonly known by
;  the trade name "Ebonol C").  The hypothesis is that atomic oxygen is 
;  altering the work function of CuO near the aperture.
;
;  However, SWEA internal surfaces are coated with Cu2S instead of CuO, and 
;  there is no clear variation of the electron suppression with time.  This
;  suggests that exposure to atomic O does not affect SWEA significantly, and
;  consequently that the suppression has been present since launch.
;
;USAGE:
;  Ke = mvn_swe_esuppress(time)
;
;INPUTS:
;       time:         A single time or an array of times in any format 
;                     accepted by time_double().
;
;KEYWORDS:
;       ON:           Enable suppression correction.
;
;       OFF:          Disable suppression correction.
;
;       SET:          Set the suppression constant to any fixed value > 0.
;                     (This also enables the suppression correction.)  This 
;                     value remains persistent until you override it with a
;                     different value or disable it altogether with SET = 0.
;                     Note that SET = 0 reverts to the nominal suppression
;                     constant; it does not disable the correction.
;
;                     This is useful for fine tuning the suppression, 
;                     especially outside of the calibrated time range
;                     (2015-03-01 to 2016-09-01).
;
;       EXTRAPOLATE:  If set, extrapolate the calibration polynomial
;                     outside the range of measurements.  Otherwise, use
;                     the closest measurement.  This remains persistent
;                     until you disable it with EXTRAPOLATE = 0.
;                     Default = 1.
;
;       SILENT:       Don't print any warnings or messages.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-10-05 13:56:19 -0700 (Wed, 05 Oct 2016) $
; $LastChangedRevision: 22045 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_esuppress.pro $
;
;CREATED BY:    David L. Mitchell  2016-09-13
;FILE: mvn_swe_esuppress.pro
;-
function mvn_swe_esuppress, time, on=on, off=off, set=set, extrapolate=extrapolate, silent=silent

  @mvn_swe_com

  common swe_esuppress, setflg, setval, domsg, doext, a

; Initialize the common block on first call

  if (size(setflg,/type) eq 0) then begin
    setflg = 0
    setval = 0.
    domsg = 1
    doext = 1
    a = [2.9037D, -2.3956d-4]
  endif

; Process keywords to determine configuration

  if keyword_set(silent) then domsg = 0

  if keyword_set(on) then begin
    swe_es_switch = 1
    print,"Electron suppression correction ON"
    domsg = 1
  endif
  
  if keyword_set(off) then begin
    swe_es_switch = 0
    print,"Electron suppression correction OFF"
    domsg = 1
  endif

  if (size(set,/type) ne 0) then begin
    swe_es_switch = 1
    if (set gt 0) then begin
      setflg = 1
      setval = float(set)
      print,"Using fixed suppression constant: ",setval
    endif else begin
      setflg = 0
      setval = 0.
      print,"Using nominal suppression constant"
    endelse
    domsg = 1
  endif

  if (size(extrapolate,/type) ne 0) then begin
    doext = keyword_set(extrapolate)
    if (doext) then print,"Extrapolate suppression constant: YES" $
               else print,"Extrapolate suppression constant: NO"
    domsg = 1
  endif

; If electron suppression switch is off, then return zero

  swe_Ke = replicate(0., (n_elements(time) > 1L))
  if (~swe_es_switch) then return, swe_Ke

; If there is a set value, then return that.  Note that the electron
; suppression switch must also be turned on.

  if (setflg) then begin
    swe_Ke = replicate(setval, (n_elements(time) > 1L))
    return, swe_Ke
  endif

; Otherwise return the value based on in-flight calibrations

  if (size(time,/type) eq 0) then return, 0.

  t = time_double(time)
  day = (t - t_sup[0])/86400D
  
  indx = where(t lt t_sup[0], count)
  if (count gt 0L) then begin
    if (doext) then begin
      swe_Ke[indx] = a[0] + a[1]*day[indx]
      if (domsg) then print,"Warning: SWEA electron suppression constant extrapolated before ", $
                             time_string(t_sup[0],prec=-3)
      domsg = 0
    endif else begin
      swe_Ke[indx] = a[0]
      if (domsg) then print,"Warning: SWEA electron suppression constant fixed before ", $
                             time_string(t_sup[0],prec=-3)
      domsg = 0
    endelse
  endif
  
  indx = where((t ge t_sup[0]) and (t le t_sup[1]), count)
  if (count gt 0L) then swe_Ke[indx] = a[0] + a[1]*day[indx]
    
  indx = where(t gt t_sup[1], count)
  if (count gt 0L) then begin
    if (doext) then begin
      swe_Ke[indx] = a[0] + a[1]*day[indx]
      if (domsg) then print,"Warning: SWEA electron suppression constant extrapolated after ", $
             time_string(t_mcp[6],prec=-3)
      domsg = 0
    endif else begin
      day = (t_sup[1] - t_sup[0])/86400D
      swe_Ke[indx] = a[0] + a[1]*day
      if (domsg) then print,"Warning: SWEA electron suppression constant fixed after ", $
                             time_string(t_sup[1],prec=-3)
      domsg = 0
    endelse
  endif

  return, swe_Ke

end
