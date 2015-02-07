;+
;FUNCTION:   mvn_swe_getspec
;PURPOSE:
;  Returns a SWEA SPEC data structure constructed from L0 data or extracted
;  from L2 data.  This routine automatically determines which data are loaded.
;  Optionally sums the data over a time range, propagating uncertainties.
;
;USAGE:
;  spec = mvn_swe_getspec(time)
;
;INPUTS:
;       time:          An array of times for extracting one or more SPEC data structure(s).
;                      Can be in any format accepted by time_double.  If more than one time
;                      is specified, then all spectra between the earliest and latest times
;                      in the array is returned.
;
;KEYWORDS:
;       ARCHIVE:       Get SPEC data from archive instead (APID A5).
;
;       SUM:           If set, then sum all spectra selected.
;
;       UNITS:         Convert data to these units.  (See mvn_swe_convert_units)
;
;       YRANGE:        Returns the data range, excluding zero counts.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-02-05 15:56:09 -0800 (Thu, 05 Feb 2015) $
; $LastChangedRevision: 16886 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getspec.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_getspec.pro
;-
function mvn_swe_getspec, time, archive=archive, sum=sum, units=units, yrange=yrange

  @mvn_swe_com  

  if (size(time,/type) eq 0) then begin
    print,"You must specify a time."
    return, 0
  endif
  
  npts = n_elements(time)
  tmin = min(time_double(time), max=tmax)

  if keyword_set(archive) then begin
    if (size(mvn_swe_engy_arc, /type) ne 8) then begin
      print, "No SPEC archive data."
      return, 0
    endif
    if (npts gt 1) then begin
      iref = where((mvn_swe_engy_arc.time ge tmin) and $
                   (mvn_swe_engy_arc.time le tmax), count)
    endif else begin
      dt = min(abs(mvn_swe_engy_arc.time - tmin), iref)
      count = 1
    endelse
    if (count eq 0L) then begin
        print,'No SPEC archive data within selected time range.'
        return, 0
    endif
    spec = mvn_swe_engy_arc[iref]
  endif else begin
    if (size(mvn_swe_engy, /type) ne 8) then begin
      print, "No SPEC survey data."
      return, 0
    endif
    if (npts gt 1) then begin
      iref = where((mvn_swe_engy.time ge tmin) and $
                   (mvn_swe_engy.time le tmax), count)
    endif else begin
      dt = min(abs(mvn_swe_engy.time - tmin), iref)
      count = 1
    endelse
    if (count eq 0L) then begin
      print,'No SPEC survey data within selected time range.'
      return, 0
    endif
    spec = mvn_swe_engy[iref]
  endelse

  mvn_swe_convert_units, spec, 'counts'

  if (keyword_set(sum) and (count gt 1)) then begin
    spec0 = spec[0]
    spec0.time = mean(spec.time)
    spec0.met = mean(spec.met)
    delta_t = minmax(spec.time)
    spec0.end_time = delta_t[1]
    spec0.delta_t = (delta_t[1] - delta_t[0]) > spec0.delta_t
    spec0.dt_arr = total(spec.dt_arr, 2)
    spec0.data = total(spec.data/spec.dtc, 2, /nan)
    spec0.var = total(spec.var/spec.dtc, 2, /nan)
    spec0.dtc = 1.  ; summing corrected counts is not reversible
    spec0.sc_pot = mean(spec.sc_pot)
    spec0.magf[0] = mean(spec.magf[0])
    spec0.magf[1] = mean(spec.magf[1])
    spec0.magf[2] = mean(spec.magf[2])
    spec = spec0
  endif

  indx = where(spec.data gt 0.)
  if (size(units,/type) eq 7) then mvn_swe_convert_units, spec, units

  yrange = minmax((spec.data)[indx])
  yrange[0] = 10.^(floor(alog10(yrange[0])))
  yrange[1] = 10.^(ceil(alog10(yrange[1])))

  return, spec

end
