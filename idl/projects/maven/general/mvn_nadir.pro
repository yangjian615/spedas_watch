;+
;PROCEDURE:   mvn_nadir
;PURPOSE:
;  Determines the direction of nadir in spacecraft coordinates.
;  Optionally, calculates the direction of nadir in additional 
;  frames specified by keyword.  The results are stored in TPLOT 
;  variables.
;
;  Spacecraft frame:
;    X --> APP boom axis
;    Y --> +Y solar array axis
;    Z --> HGA axis
;
;USAGE:
;  mvn_nadir, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating the Nadir direction.
;                 If not specified, then use current range set by timespan.
;
;                 Note: the user is responsible for making sure SPICE
;                 kernels are loaded for the desired time range.
;                 (See mvn_swe_spice_init for an example.)
;
;KEYWORDS:
;       PANS:     Named variable to hold the tplot variables created.
;
;       FRAME:    Also calculate the Nadir direction in one or more 
;                 frames specified by this keyword.  Set this keyword to
;                 a single string or an array of strings.  Some possible
;                 frames are: 'MAVEN_SWEA', 'MAVEN_SWIA', 'MAVEN_STATIC', 
;                 'MAVEN_APP', etc.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-03-01 14:53:29 -0800 (Wed, 01 Mar 2017) $
; $LastChangedRevision: 22889 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_nadir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_nadir, trange, pans=pans, frame=frame

  @maven_orbit_common

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)
  
  if (size(state,/type) eq 0) then maven_orbit_tplot,/load

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]

  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
  if (size(frame,/type) ne 7) then frame = ''

; First store the nadir direction in the IAU_MARS frame

  x = state.time
  y = -(state.geo_x)  ; IAU_MARS direction of nadir
  ymag = sqrt(total(y*y,2)) # replicate(1.,3)
  store_data,'Nadir',data={x:x, y:y/ymag, v:indgen(3)}
  options,'Nadir','ytitle','Nadir (PL)'
  options,'Nadir','labels',['X','Y','Z']
  options,'Nadir','labflag',1
  options,'Nadir',spice_frame='IAU_MARS',spice_master_frame='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot,'Nadir','MAVEN_SPACECRAFT',trange=[tmin,tmax],check='MAVEN_SPACECRAFT'
  pans = 'Nadir'

; Next calculate the nadir direction in frame(s) specified by keyword FRAME
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'Nadir',to_frame,trange=[tmin,tmax],check='MAVEN_SPACECRAFT'
    pname = 'Nadir_' + to_frame
    j = strpos(to_frame,'_')
    options,pname,'ytitle','Nadir (' + strmid(to_frame,j+1) + ')'
    pans = [pans, pname]
  endfor
  
  return

end
