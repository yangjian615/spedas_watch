;+
;PROCEDURE:   mvn_sundir
;PURPOSE:
;  Determines the direction of the Sun in one or more SPICE
;  frames.  The results are stored in TPLOT variables.
;
;  If no frame is specified, the default is MAVEN_SPACECRAFT:
;    X --> APP boom axis
;    Y --> +Y solar array axis
;    Z --> HGA axis
;
;USAGE:
;  mvn_sundir, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating the Sun direction.
;                 If not specified, then use current range set by timespan.
;
;                 Note: the user is responsible for making sure SPICE
;                 kernels are loaded for the desired time range.
;                 (See mvn_swe_spice_init for an example.)
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1.
;
;       PANS:     Named variable to hold the tplot variables created.
;
;       FRAME:    Calculate the Sun direction in one or more frames
;                 specified by this keyword.  Set this keyword to a
;                 single string or an array of strings.  Some possible
;                 frames are: 'MAVEN_SWEA', 'MAVEN_SWIA', 'MAVEN_STATIC', 
;                 'MAVEN_APP', etc.  Default = 'MAVEN_SPACECRAFT'.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-03-13 11:29:50 -0700 (Mon, 13 Mar 2017) $
; $LastChangedRevision: 22951 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_sundir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_sundir, trange, dt=dt, pans=pans, frame=frame, polar=polar

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

; If SPICE is not initialized at all, then load kernels now.  Otherwise, use
; the kernels already loaded.

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]

  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  dopol = keyword_set(polar)
  
  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'

; First store the Sun direction in MAVEN_SSO coordinates

  npts = floor((tmax - tmin)/dt) + 1L
  x = tmin + dt*dindgen(npts)
  y = replicate(1.,npts) # [1.,0.,0.]
  store_data,'Sun',data={x:x, y:y, v:indgen(3)}
  options,'Sun','ytitle','Sun (MSO)'
  options,'Sun','labels',['X','Y','Z']
  options,'Sun','labflag',1
  options,'Sun',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'

; Next calculate the Sun direction in frame(s) specified by keyword FRAME

  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'Sun',to_frame,trange=[tmin,tmax],check='MAVEN_SPACECRAFT'
    pname = 'Sun_' + to_frame
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    if (fname eq 'SPACECRAFT') then fname = 'PL'
    options,pname,'ytitle','Sun (' + fname + ')'
    pans = [pans, pname]

    if (dopol) then begin
      get_data, pname, data=sun
      xyz_to_polar, sun, theta=the, phi=phi, /ph_0_360

      the_name = 'Sun_' + fname + '_The'
      store_data,the_name,data=the
      options,the_name,'ytitle','Sun The!c'+fname
      options,the_name,'ynozero',1
      options,the_name,'psym',3

      phi_name = 'Sun_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','Sun Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3

      if (fname eq 'SWEA') then begin
        options,the_name,'constant',[-10, 0, 17, 37, 77, 87]  ; see mvn_swe_sundir
        options,phi_name,'constant',[0, 45, 90, 135, 180, 225, 270, 315]  ; ribs
      endif

      pans = [pans, the_name, phi_name]
    endif

  endfor
  
  pans = pans[1:*]
  
  return

end
