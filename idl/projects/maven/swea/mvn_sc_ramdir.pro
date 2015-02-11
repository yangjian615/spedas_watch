;+
;PROCEDURE:   mvn_sc_ramdir
;PURPOSE:
;  Determines the velocity vector relative to the body-fixed rotating
;  Mars frame (IAU_MARS), rotated into either spacecraft or APP
;  coordinates.
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
;       PANS:     Named variable to hold the tplot variables created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-02-09 14:33:00 -0800 (Mon, 09 Feb 2015) $
; $LastChangedRevision: 16924 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sc_ramdir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_sc_ramdir, trange, dt=dt, pans=pans, app=app

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

  mk = spice_test('*')
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]
  
  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
  if keyword_set(app) then to_frame = 'MAVEN_APP' $
                      else to_frame = 'MAVEN_SPACECRAFT'

  if (size(state,/type) eq 0) then maven_orbit_tplot, /loadonly, /current

; Spacecraft velocity in IAU_MARS frame
  
  store_data,'V_sc',data={x:state.time, y:state.geo_v}
  options,'V_sc',spice_frame='IAU_MARS',spice_master_frame='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot,'V_sc',to_frame,trange=[tmin,tmax]

  vname = 'V_sc_' + to_frame
  options,vname,'labels',['X','Y','Z']
  options,vname,'labflag',1

; Rotate to Spacecraft or APP frame

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
