;+
;PROCEDURE:   mvn_sc_ramdir
;PURPOSE:
;  Determines the spacecraft orbital velocity vector relative to
;  the body-fixed rotating Mars frame (IAU_MARS), rotated into either
;  spacecraft or APP coordinates.
;
;  In the spacecraft frame, phi is the angle in the X-Y plane:
;      0 --> +X axis (APP boom)
;     90 --> +Y axis (+Y solar array and MAG1)
;    180 --> -X axis
;    270 --> -Y axis (-Y solar array and MAG2)
;
;  and theta is the angle out of the X-Y plane:
;    +90 --> +Z axis (HGA)
;      0 --> X-Y plane
;    -90 --> -Z axis
;
;  In the APP frame, phi is the angle in the i-j plane:
;      0 --> +i --> NGIMS boresight
;    +90 --> +j --> IUVS fields of regard (general direction)
;
;  and theta is the angle out of this plane:
;    +90 --> +k --> STATIC symmetry direction
;
;  This is the velocity vector -- the RAM flow is incident on the spacecraft
;  from the opposite direction.
;
;USAGE:
;  mvn_sc_ramdir, trange
;
;INPUTS:
;       trange:   Time range for calculating the RAM direction.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1.
;
;       APP:      Rotate to APP coordinates instead of Spacecraft coord.
;
;       FRAME:    Rotate to FRAME coordinates instead of Spacecraft coord.
;                 Any frame defined in the MAVEN frames kernel is allowed.
;
;       PANS:     Named variable to hold the tplot variables created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-24 12:36:35 -0700 (Sun, 24 May 2015) $
; $LastChangedRevision: 17693 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sc_ramdir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_sc_ramdir, trange, dt=dt, pans=pans, app=app, frame=frame

  common mav_orb_tplt, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
                       lon, lat, hgt, mex

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]
  
  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
  if keyword_set(app) then to_frame = 'MAVEN_APP' $
                      else to_frame = 'MAVEN_SPACECRAFT'

  if keyword_set(frame) then to_frame = strupcase(frame)

  if (size(state,/type) eq 0) then maven_orbit_tplot, /loadonly, /current

; Spacecraft velocity in IAU_MARS frame --> rotate to S/C or APP frame
  
  store_data,'V_sc',data={x:state.time, y:state.geo_v}
  options,'V_sc',spice_frame='IAU_MARS',spice_master_frame='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot,'V_sc',to_frame,trange=[tmin,tmax]

  vname = 'V_sc_' + to_frame
  options,vname,'labels',['X','Y','Z']
  options,vname,'labflag',1

; Calculate angles and create tplot variables

  tname = 'V_sc_' + to_frame
  
  get_data,tname,data=V_ram
  Vmag = sqrt(total(V_ram.y^2.,2))
  Vphi = atan(V_ram.y[*,1], V_ram.y[*,0])*!radeg
  indx = where(Vphi lt 0., count)
  if (count gt 0L) then Vphi[indx] = Vphi[indx] + 360.
  Vthe = asin(V_ram.y[*,2]/Vmag)*!radeg
  
  phiname = 'Vphi_' + to_frame
  thename = 'Vthe_' + to_frame

  store_data,phiname,data={x:V_ram.x, y:Vphi}
  store_data,thename,data={x:V_ram.x, y:Vthe}

  return

end
