;+
;FUNCTION:   mvn_swe_crosscal
;PURPOSE:
;  Calculates SWEA-SWIA cross calibration factor as a function of time.
;  Based on polynomial fits to numerous cross calibrations between SWEA
;  and SWIA in the upstream solar wind, when both instruments were 
;  measuring the complete electron and ion distributions, respectively.
;  Only periods of steady solar wind, when the spacecraft potential can
;  be reliably estimated from SWEA data are used.
;
;  Assumptions:
;
;    (1) Charge neutrality.
;
;    (2) SWIA is measuring the entire ion distribution.  This is safe 
;        in the upstream solar wind, as long as the spacecraft is Sun
;        pointed,  which is most of the time.  Watch out for times of
;        Earth point.
;
;    (3) The energy flux in SWEA's blind spots is the same as the 
;        average energy flux over the rest of the field of view.  This
;        can be very much in error for the solar wind halo distribution;
;        however, most of the density is in the core distribution, which
;        is not strongly directional.
;
;USAGE:
;  factor = mvn_swe_crosscal(time)
;
;INPUTS:
;       time:         A single time or an array of times in any format 
;                     accepted by time_double().
;
;KEYWORDS:
;       ON:           Turn cross calibation switch on.
;
;       OFF:          Turn cross calibration switch off.
;
;       SILENT:       Don't print any warnings or messages.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-01-23 17:11:38 -0800 (Mon, 23 Jan 2017) $
; $LastChangedRevision: 22650 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crosscal.pro $
;
;CREATED BY:    David L. Mitchell  05-04-16
;FILE: mvn_swe_crosscal.pro
;-
function mvn_swe_crosscal, time, on=on, off=off, silent=silent

  @mvn_swe_com

  domsg = ~keyword_set(silent)
  
  if keyword_set(on) then begin
    swe_cc_switch = 1
    if (domsg) then print,"SWE-SWI crosscal enabled."
    return, 0.
  endif
  
  if keyword_set(off) then begin
    swe_cc_switch = 0
    if (domsg) then print,"SWE-SWI crosscal disabled."
    return, 0.
  endif

  cc = replicate(1., n_elements(time))
  if (~swe_cc_switch) then return, cc

  t = time_double(time)
  day = (t - t_mcp[0])/86400D

  indx = where(t lt t_mcp[1], count)                        ; MCPHV = 2500 V
  if (count gt 0L) then cc[indx] = 2.6     ; best overall value

  indx = where((t ge t_mcp[1]) and (t lt t_mcp[2]), count)  ; MCPHV = 2600 V
  if (count gt 0L) then cc[indx] = 2.3368  ; match polynomial starting at t_mcp[2]
  
  indx = where((t ge t_mcp[2]) and (t lt t_mcp[3]), count)  ; MCPHV = 2600 V
  if (count gt 0L) then begin
    day = (t - time_double('2014-11-12'))/86400D
    cc[indx] = 2.3368D - day[indx]*(9.9426d-4 - day[indx]*2.6014d-5)
  endif
  
  indx = where((t ge t_mcp[3]) and (t lt t_mcp[4]), count)  ; MCPHV = 2700 V
  if (count gt 0L) then begin
    day = (t - time_double('2015-12-20'))/86400D
    cc[indx] = 2.2143D + day[indx]*(7.9280D-4 + day[indx]*1.4300D-5)
  endif
  
  indx = where((t ge t_mcp[4]) and (t lt t_mcp[5]), count)  ; MCPHV = 2600 V
  if (count gt 0L) then begin
    day = (t - time_double('2014-11-12'))/86400D
    cc[indx] = 2.3368D - day[indx]*(9.9426d-4 - day[indx]*2.6014d-5)
  endif
  
  indx = where((t ge t_mcp[5]) and (t lt t_mcp[6]), count)  ; MCPHV = 2700 V
  if (count gt 0L) then begin
    day = (t - time_double('2015-12-20'))/86400D
    cc[indx] = 2.2143D + day[indx]*(7.9280D-4 + day[indx]*1.4300D-5)
  endif

  indx = where((t ge t_mcp[6]) and (t lt t_mcp[7]), count)  ; MCPHV = 2750 V
  if (count gt 0L) then begin
    day = (t - time_double('2016-10-25'))/86400D
    cc[indx] = 2.2573D + day[indx]*(2.0204D-4 + day[indx]*3.6708D-5)
  endif

  indx = where(t ge t_mcp[7], count)  ; last SWE-SWI cross calibration
  if (count gt 0L) then begin
    day = (t_mcp[7] - time_double('2016-10-25'))/86400D
    cc[indx] = 2.2573D + day[indx]*(2.0204D-4 + day[indx]*3.6708D-5)
    if (domsg) then print,"Warning: SWE-SWI cross calibration factor fixed after ", $
                           time_string(t_mcp[7],prec=-3)
  endif

  return, cc

end
