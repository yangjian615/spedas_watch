;+
;PROCEDURE:   MVN_EPH_RESAMPLE
;PURPOSE:
;  Samples MAVEN ephemeris data at times specified by user.  Uses
;  spline interpolation.
;
;USAGE:
;  mvn_eph_resample, time, eph_in, eph_out
;
;INPUTS:
;       time:      An array of times at which ephemeris data are
;                  desired.  Can be in any format accepted by
;                  time_double().
;
;       eph_in:    An MAVEN ephemeris structure obtained from 'get_mvn_eph'.
;                  These data should have at least some overlap with 
;                  the input time array (obviously).
;
;                     *** This routine WILL NOT extrapolate. ***
;
;       eph_out:   The ephemeris data sampled at the input times.  
;
;KEYWORDS:
;
;CREATED BY:	Takuya Hara  on 2014-10-07.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2014-11-26 11:42:32 -0800 (Wed, 26 Nov 2014) $
; $LastChangedRevision: 16310 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/mvn_eph_resample.pro $
;
;MODIFICATION LOG:
;(YYYY-MM-DD)
; 2014-10-07: Initial procedure is made. This procedure is based on
;             the MGS routine written by David L. Mitchell. The
;             original routine name is 'mgs_eph_resample' (created on
;             2003-01-28, and the last version is 1.1 on 2011-03-06).
; 2014-11-25: Minor revision and header description is written. 
;
;-
pro mvn_eph_resample, time, eph_in, eph_out

; Process the inputs, make sure they are reasonable

  time = time_double(time)
  nsam = n_elements(time)

  eph_out = 0

  str_element,eph_in,'x_ss',success=ok
  if (not ok) then begin
    print, "Second input does not appear to be an MGS EPH structure."
    print, "Use get_mgs_eph to obtain data in the proper format."
    return
  endif
  npts = n_elements(eph_in)

; Make sure EPH data have some overlap with input time array

  tmin = eph_in[0L].time
  tmax = eph_in[npts-1L].time
  k = where((time ge tmin) and (time le tmax), count)

  if (count eq 0L) then begin
    print, "EPH data have no overlap with input time array."
    return
  endif

; Initialize constants and output structure

  badval = !values.f_nan

  eph_out = mvn_eph_struct(nsam,init=badval)
  eph_out.time = time

; Deal with pathological EPH structure (1 point)

  if (n_elements(eph_in) lt 2L) then begin
    print, "EPH data have only 1 point!  ", format='(a,$)'
    delta_t = min(abs(time - eph_in.time), i)
    if (delta_t lt dt[i]/2D) then begin
      eph_out[i] = eph_in
      print, "Using nearest neighbor."
    endif else print, "No overlap."
    return
  endif

; Resample the EPH data

  eph_out[k].x_ss = spline(eph_in.time, eph_in.x_ss, time[k])
  eph_out[k].y_ss = spline(eph_in.time, eph_in.y_ss, time[k])
  eph_out[k].z_ss = spline(eph_in.time, eph_in.z_ss, time[k])
  eph_out[k].vx_ss = spline(eph_in.time, eph_in.vx_ss, time[k])
  eph_out[k].vy_ss = spline(eph_in.time, eph_in.vy_ss, time[k])
  eph_out[k].vz_ss = spline(eph_in.time, eph_in.vz_ss, time[k])

  x = spline(eph_in.time, eph_in.x_pc, time[k])
  y = spline(eph_in.time, eph_in.y_pc, time[k])
  z = spline(eph_in.time, eph_in.z_pc, time[k])
  r = sqrt(x*x + y*y + z*z)

  eph_out[k].x_pc = x
  eph_out[k].y_pc = y
  eph_out[k].z_pc = z
  eph_out[k].Elon = atan(y,x)
  eph_out[k].lat  = asin(z/r)

  eph_out[k].alt  = spline(eph_in.time, eph_in.alt, time[k])
  eph_out[k].sza  = spline(eph_in.time, eph_in.sza, time[k])

  ;; x = spline(eph_in.time, cos(eph_in.lst), time[k])
  ;; y = spline(eph_in.time, sin(eph_in.lst), time[k])
  ;; lst = atan(y,x)

  ;; indx = where(lst lt 0., count)
  ;; if (count gt 0L) then lst[indx] = lst[indx] + (2.*!pi)

  ;; eph_out[k].lst = lst

  ;; sun = interpol(double(eph_in.sun), eph_in.time, time[k])
  ;; eph_out[k].sun = byte(round(sun))

  return

end
