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
;  Assumes charge neutrality.
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
;       EXTRAPOLATE:  If set, extrapolate the calibration polynomial
;                     outside the range of measurements.  Otherwise,
;                     use the last measurement.
;
;       SILENT:       Don't print any warnings or messages.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-09-19 17:10:15 -0700 (Mon, 19 Sep 2016) $
; $LastChangedRevision: 21876 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crosscal.pro $
;
;CREATED BY:    David L. Mitchell  05-04-16
;FILE: mvn_swe_crosscal.pro
;-
function mvn_swe_crosscal, time, on=on, off=off, extrapolate=extrapolate, silent=silent

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
  
  indx = where(t lt t_mcp[1], count)
  if (count gt 0L) then cc[indx] = 2.6     ; best overall value
  
  indx = where((t ge t_mcp[1]) and (t lt t_mcp[2]), count)
  if (count gt 0L) then cc[indx] = 2.3368  ; match polynomial starting at t_mcp[2]
  
  indx = where((t ge t_mcp[2]) and (t lt t_mcp[3]), count)
  if (count gt 0L) then cc[indx] = 4.0071D - day[indx]*(1.3221d-2 - day[indx]*2.6014d-5)
  
  indx = where((t ge t_mcp[3]) and (t lt t_mcp[4]), count)
  if (count gt 0L) then cc[indx] = 1.2379D + day[indx]*1.5413d-3
  
  indx = where((t ge t_mcp[4]) and (t lt t_mcp[5]), count)
  if (count gt 0L) then cc[indx] = 4.0071D - day[indx]*(1.3221d-2 - day[indx]*2.6014d-5)
  
  indx = where((t ge t_mcp[5]) and (t lt t_mcp[6]), count)
  if (count gt 0L) then cc[indx] = 7.5293D - day[indx]*(1.7454d-2 - day[indx]*1.4300d-5)
  
  indx = where(t ge t_mcp[6], count)
  if (count gt 0L) then begin
    if keyword_set(extrapolate) then begin
      cc[indx] = 7.5293D - day[indx]*(1.7454d-2 - day[indx]*1.4300d-5)
      if (domsg) then print,"Warning: SWE-SWI cross calibration extrapolated after ", $
                             time_string(t_mcp[6],prec=-3)
    endif else begin
      day = (t_mcp[6] - t_mcp[0])/86400D
      cc[indx] = 7.5293D - day[indx]*(1.7454d-2 - day[indx]*1.4300d-5)
      if (domsg) then print,"Warning: SWE-SWI cross calibration factor fixed after ", $
                             time_string(t_mcp[6],prec=-3)
    endelse
  endif

  return, cc

end
