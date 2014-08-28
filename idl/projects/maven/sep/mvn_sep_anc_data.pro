; This file will eventually calculate all of the necessary ancillary data that does not go into the SEP level II CDF files

function mvn_sep_anc_data, trange = trange, delta_t = delta_t ,load_kernels=load_kernels,maven_kernels = maven_kernels

  if not keyword_set (delta_t) then delta_t = 32
   
  tr = timerange(trange)
  total_time = tr[1] - tr[0]
  ntimes =ceil(total_time/delta_t)
  times = tr[0] + delta_t*dindgen(ntimes)
  et = time_ephemeris(times)

;here we define the tags for the ancillary/ephemeris data structure.  This should have exactly the same
; format as the same structure in mvn_sep_read_l2_anc_cdf

; note here that 'r' stands for reverse and 'f' stands for forward

  SEP_ancillarya = {time_UNIX: 0d, time_ephemeris:0d,$
                    look_direction_MSO_SEP1_forward:fltarr(3),$
                    look_direction_MSO_SEP1_reverse:fltarr(3),$
                    look_direction_MSO_SEP2_forward:fltarr(3),$
                    look_direction_MSO_SEP2_reverse:fltarr(3),$
                    look_direction_SSO_SEP1_forward:fltarr(3),$
                    look_direction_SSO_SEP1_reverse:fltarr(3),$
                    look_direction_SSO_SEP2_forward:fltarr(3),$
                    look_direction_SSO_SEP2_reverse:fltarr(3),$
                    look_direction_GEO_SEP1_forward:fltarr(3),$
                    look_direction_GEO_SEP1_reverse:fltarr(3),$
                    look_direction_GEO_SEP2_forward:fltarr(3),$
                    look_direction_GEO_SEP2_reverse:fltarr(3),$
                    sun_angle_SEP1_forward: 0d, $
                    sun_angle_SEP1_reverse: 0d, $
                    sun_angle_SEP2_forward: 0d, $
                    sun_angle_SEP2_reverse: 0d, $
                    ram_angle_SEP1_forward: 0d, $
                    ram_angle_SEP1_reverse: 0d, $
                    ram_angle_SEP2_forward: 0d, $
                    ram_angle_SEP2_reverse: 0d, $
                    fraction_FOV_Mars_SEP1_forward:0d, $
                    fraction_FOV_Mars_SEP1_reverse:0d, $
                    fraction_FOV_Mars_SEP2_forward:0d, $
                    fraction_FOV_Mars_SEP2_reverse:0d, $
                    fraction_FOV_sunlit_Mars_SEP1_forward:0d, $
                    fraction_FOV_sunlit_Mars_SEP1_reverse:0d, $
                    fraction_FOV_sunlit_Mars_SEP2_forward:0d, $
                    fraction_FOV_sunlit_Mars_SEP2_reverse:0d, $
                    fraction_sky_filled_by_Mars:0d, $
                    qrot_SEP1_to_MSO:fltarr(4), $
                    qrot_SEP1_to_SSO:fltarr(4), $
                    qrot_SEP1_to_GEO:fltarr(4), $
                    qrot_SEP2_to_MSO:fltarr(4), $
                    qrot_SEP2_to_SSO:fltarr(4), $
                    qrot_SEP2_to_GEO:fltarr(4), $
                    spacecraft_position_MSO:fltarr(3), $
                    spacecraft_position_GEO:fltarr(3), $
                    spacecraft_position_EclipJ2000:fltarr(3), $
                    Earth_position_EclipJ2000:fltarr(3), $
                    Mars_position_EclipJ2000:fltarr(3), $
                    spacecraft_latitude_GEO:0d, $
                    spacecraft_east_longitude_GEO:0d, $
                    spacecraft_solar_zenith_angle:0d, $
                    spacecraft_local_time:0d}
                    
  SEP_ancillary = replicate (SEP_ancillarya,ntimes)
  if keyword_set(load_kernels) then maven_kernels = mvn_spice_kernels(trange = tr,/load,/valid) 
  

  tmp_MSO = mvn_sep_anc_look_directions(utc = times, coordinate_frame = 'MAVEN_MSO')
  tmp_SSO = mvn_sep_anc_look_directions(utc = times, coordinate_frame = 'MAVEN_SSO')
  tmp_GEO = mvn_sep_anc_look_directions(utc = times, coordinate_frame = 'IAU_MARS')
  
; calculate the angle of each the fields of view with respect to the sun line
  sun_angle_SEP1_forward = acos(tmp_SSO.look_direction_SEP1_forward[0,*])/!dtor
  sun_angle_SEP1_reverse = acos(tmp_SSO.look_direction_SEP1_reverse[0,*])/!dtor
  sun_angle_SEP2_forward = acos(tmp_SSO.look_direction_SEP2_forward[0,*])/!dtor
  sun_angle_SEP2_reverse = acos(tmp_SSO.look_direction_SEP2_reverse[0,*])/!dtor
  
; now calculate the angle between the center of the field of view and the RAM direction
  MAVEN_velocity_MSO = spice_body_vel('MAVEN','MARS',utc=times,et=et,frame='MAVEN_MSO',check_objects='MAVEN_SC_BUS')
  
  ram_angle_SEP1_forward = separation_angle(MAVEN_velocity_MSO,tmp_MSO.look_direction_SEP1_forward)
  ram_angle_SEP1_reverse = separation_angle(MAVEN_velocity_MSO,tmp_MSO.look_direction_SEP1_reverse)
  ram_angle_SEP2_forward = separation_angle(MAVEN_velocity_MSO,tmp_MSO.look_direction_SEP2_forward)
  ram_angle_SEP2_reverse = separation_angle(MAVEN_velocity_MSO,tmp_MSO.look_direction_SEP2_reverse)

; calculate the quaternions for the rotations between the SEP coordinate systems and the relevant Mars ones
   qrot_SEP1_to_MSO =  spice_body_att('MAVEN_SEP1','MAVEN_MSO',times,/quaternion,check_object='MAVEN_SC_BUS') 
   qrot_SEP1_to_SSO =  spice_body_att('MAVEN_SEP1','MAVEN_SSO',times,/quaternion,check_object='MAVEN_SC_BUS') 
   qrot_SEP1_to_GEO =  spice_body_att('MAVEN_SEP1','IAU_MARS',times,/quaternion,check_object='MAVEN_SC_BUS') 
  
   qrot_SEP2_to_MSO =  spice_body_att('MAVEN_SEP2','MAVEN_MSO',times,/quaternion,check_object='MAVEN_SC_BUS') 
   qrot_SEP2_to_SSO =  spice_body_att('MAVEN_SEP2','MAVEN_SSO',times,/quaternion,check_object='MAVEN_SC_BUS') 
   qrot_SEP2_to_GEO =  spice_body_att('MAVEN_SEP2','IAU_MARS',times,/quaternion,check_object='MAVEN_SC_BUS') 
 
; also load up MAVEN position.
   spacecraft_position_MSO = spice_body_pos('MAVEN','MARS',utc=times,et=et,frame='MAVEN_MSO',check_objects='MAVEN_SC_BUS')
   spacecraft_position_GEO = spice_body_pos('MAVEN','MARS',utc=times,et=et,frame='IAU_MARS',check_objects='MAVEN_SC_BUS')
   spacecraft_position_EclipJ2000 = spice_body_pos('MAVEN','SUN',utc=times,et=et,frame='ECLIPJ2000',check_objects='MAVEN_SC_BUS')
   Earth_position_EclipJ2000 = spice_body_pos('EARTH','SUN',utc=times,et=et,frame='ECLIPJ2000')
   Mars_position_EclipJ2000 = spice_body_pos('MARS','SUN',utc=times,et=et,frame='ECLIPJ2000')
  
; fraction of 4Pi taken up by Mars (assuming spherical planet)
  spacecraft_radius = sqrt(total (spacecraft_position_MSO^ 2.0,1))
  Mars_mean_radius = 3389.5
  ;half_angle = asin( Mars_mean_radius/spacecraft_radius)
  fraction_4pi = 0.5*(1.0 - sqrt(1.0 - (Mars_mean_radius/spacecraft_radius)^ 2.0))
  
; fraction of each FOV taken up by Mars and sunlit Mars.  Don't bother when during cruise
  if mean(fraction_4pi,/nan) gt 1e-3 then fraction = mvn_sep_anc_fov_mars_fraction(times,dang = 1.0) else $
  fraction = {fraction_FOV_Mars: fltarr(ntimes, 4), fraction_FOV_sunlit_Mars: fltarr(ntimes, 4)}
  
; calculate geographic longitude, latitude
  ; cspice_subpnt, 'Intercept: ellipsoid', 'MARS', et, 
   cart2latlong, spacecraft_position_GEO [0,*], spacecraft_position_GEO [1,*], spacecraft_position_GEO [2,*], $
      spacecraft_radius, spacecraft_latitude_GEO, spacecraft_east_longitude_GEO
; calculate solar Zenith angle
   spacecraft_solar_zenith_angle = sza(spacecraft_position_MSO [0,*], spacecraft_position_MSO [1,*], spacecraft_position_MSO [2,*])
;  calculate subsolar latitude and longitude
   subsolar_point_GEO = spice_vector_rotate(replicate (1.0, ntimes)##[3390.0,0,0],times,et=et,'MAVEN_MSO','IAU_Mars')
   cart2latlong, subsolar_point_Geo [0,*], subsolar_point_Geo [1,*], subsolar_point_Geo [2,*], $
      tmp,subsolar_latitude, subsolar_longitude
; calculate local time. '499' is the NAIF ID code for Mars
 ;  cspice_et2lst, et, 499, reform (spacecraft_East_longitude_GEO[544]), 'PLANETOCENTRIC', hr, mn, sc, time, ampm   
   mso2lt,spacecraft_position_MSO [0,*], spacecraft_position_MSO [1,*], spacecraft_position_MSO [2,*], $
      subsolar_latitude, spacecraft_local_time
   
   
   SEP_ancillary.time_UNIX = time_double (times)
   SEP_ancillary.time_ephemeris = et
   
   SEP_ancillary.look_direction_MSO_SEP1_forward = tmp_MSO.look_direction_SEP1_forward
   SEP_ancillary.look_direction_MSO_SEP1_reverse = tmp_MSO.look_direction_SEP1_reverse
   SEP_ancillary.look_direction_MSO_SEP2_forward = tmp_MSO.look_direction_SEP2_forward
   SEP_ancillary.look_direction_MSO_SEP2_reverse = tmp_MSO.look_direction_SEP2_reverse
   
   SEP_ancillary.look_direction_SSO_SEP1_forward = tmp_SSO.look_direction_SEP1_forward
   SEP_ancillary.look_direction_SSO_SEP1_reverse = tmp_SSO.look_direction_SEP1_reverse
   SEP_ancillary.look_direction_SSO_SEP2_forward = tmp_SSO.look_direction_SEP2_forward
   SEP_ancillary.look_direction_SSO_SEP2_reverse = tmp_SSO.look_direction_SEP2_reverse
   
   SEP_ancillary.look_direction_GEO_SEP1_forward = tmp_GEO.look_direction_SEP1_forward
   SEP_ancillary.look_direction_GEO_SEP1_reverse = tmp_GEO.look_direction_SEP1_reverse
   SEP_ancillary.look_direction_GEO_SEP2_forward = tmp_GEO.look_direction_SEP2_forward
   SEP_ancillary.look_direction_GEO_SEP2_reverse = tmp_GEO.look_direction_SEP2_reverse
   
   SEP_ancillary.sun_angle_SEP1_forward = reform (sun_angle_SEP1_forward)            
   SEP_ancillary.sun_angle_SEP1_reverse = reform (sun_angle_SEP1_reverse)              
   SEP_ancillary.sun_angle_SEP2_forward = reform (sun_angle_SEP2_forward)              
   SEP_ancillary.sun_angle_SEP2_reverse = reform (sun_angle_SEP2_reverse)     
            
   SEP_ancillary.ram_angle_SEP1_forward = reform (ram_angle_SEP1_forward)            
   SEP_ancillary.ram_angle_SEP1_reverse = reform (ram_angle_SEP1_reverse)              
   SEP_ancillary.ram_angle_SEP2_forward = reform (ram_angle_SEP2_forward)              
   SEP_ancillary.ram_angle_SEP2_reverse = reform (ram_angle_SEP2_reverse)              

   SEP_ancillary.fraction_FOV_Mars_SEP1_forward = fraction.fraction_FOV_Mars [*, 0]
   SEP_ancillary.fraction_FOV_Mars_SEP1_reverse = fraction.fraction_FOV_Mars [*, 1]
   SEP_ancillary.fraction_FOV_Mars_SEP2_forward = fraction.fraction_FOV_Mars [*, 2]
   SEP_ancillary.fraction_FOV_Mars_SEP2_reverse = fraction.fraction_FOV_Mars [*, 3]
   
   SEP_ancillary.fraction_FOV_sunlit_Mars_SEP1_forward = fraction.fraction_FOV_sunlit_Mars [*, 0]
   SEP_ancillary.fraction_FOV_sunlit_Mars_SEP1_reverse = fraction.fraction_FOV_sunlit_Mars [*, 1]
   SEP_ancillary.fraction_FOV_sunlit_Mars_SEP2_forward = fraction.fraction_FOV_sunlit_Mars [*, 2]
   SEP_ancillary.fraction_FOV_sunlit_Mars_SEP2_reverse = fraction.fraction_FOV_sunlit_Mars [*, 3]
   
   SEP_ancillary.fraction_sky_filled_by_Mars =   fraction_4pi
   
   SEP_ancillary.qrot_SEP1_to_MSO = qrot_SEP1_to_MSO
   SEP_ancillary.qrot_SEP1_to_SSO = qrot_SEP1_to_SSO
   SEP_ancillary.qrot_SEP1_to_GEO = qrot_SEP1_to_GEO
           
   SEP_ancillary.qrot_SEP2_to_MSO = qrot_SEP2_to_MSO
   SEP_ancillary.qrot_SEP2_to_SSO = qrot_SEP2_to_SSO
   SEP_ancillary.qrot_SEP2_to_GEO = qrot_SEP2_to_GEO
           
   SEP_ancillary.spacecraft_position_MSO = spacecraft_position_MSO              
   SEP_ancillary.spacecraft_position_GEO = spacecraft_position_GEO              
   SEP_ancillary.spacecraft_position_EclipJ2000 = spacecraft_position_EclipJ2000              
   SEP_ancillary.Earth_position_EclipJ2000 = Earth_position_EclipJ2000              
   SEP_ancillary.Mars_position_EclipJ2000 = Mars_position_EclipJ2000              

   SEP_ancillary.spacecraft_latitude_GEO = reform (spacecraft_latitude_GEO)
   SEP_ancillary.spacecraft_east_longitude_GEO = reform (spacecraft_east_longitude_GEO)
   SEP_ancillary.spacecraft_solar_zenith_angle = reform (spacecraft_solar_zenith_angle)
   SEP_ancillary.spacecraft_local_time = reform (spacecraft_local_time)

  return, SEP_ancillary
end
  
        
                 