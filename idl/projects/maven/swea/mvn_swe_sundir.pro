;+
;PROCEDURE:   mvn_swe_sundir
;PURPOSE:
;  Determines the direction of the Sun in SWEA coordinates.  The result is
;  stored in TPLOT variables.
;
;USAGE:
;  mvn_swe_sundir, trange
;
;INPUTS:
;       trange:   Time range for calculating the Sun direction.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1.
;
;       PANS:     Named variable to hold the tplot variables created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-11-26 17:13:26 -0800 (Wed, 26 Nov 2014) $
; $LastChangedRevision: 16317 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sundir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_sundir, trange, dt=dt, pans=pans

  @mvn_swe_com

  if (size(trange,/type) eq 0) then begin
    if (size(mvn_swe_engy,/type) ne 8) then begin
      print,"You must specify a time range or load data first."
      return
    endif
    tmin = min(mvn_swe_engy.time, max=tmax)
  endif else tmin = min(time_double(trange), max=tmax)
  
  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
  if (tmax lt t_mtx[2]) then begin
    print,"Using stowed SWEA frame."
    swe_frame = 'MAVEN_SWEA_STOW'
  endif else begin
    print,"Using deployed SWEA frame."
    swe_frame = 'MAVEN_SWEA'
  endelse

  npts = floor((tmax - tmin)/dt) + 1L
  x = tmin + dt*dindgen(npts)
  y = replicate(1.,npts) # [1.,0.,0.]  ; MAVEN_SSO direction of Sun
  store_data,'Sun',data={x:x, y:y, v:indgen(3)}
  options,'Sun','labels',['X','Y','Z']
  options,'Sun','labflag',1
  options,'Sun',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot,'Sun','MAVEN_SPACECRAFT',trange=[tmin,tmax]
  spice_vector_rotate_tplot,'Sun',swe_frame,trange=[tmin,tmax]

  get_data,('Sun_' + swe_frame),data=sun
  xyz_to_polar, sun, theta=the, phi=phi, /ph_0_360
  store_data,'Sun_The',data=the
  store_data,'Sun_Phi',data=phi
  options,'Sun_The','ynozero',1
  options,'Sun_Phi','ynozero',1
  options,'Sun_The','psym',3
  options,'Sun_Phi','psym',3
  
  pans = ['Sun_The','Sun_Phi']
  
  return

end
