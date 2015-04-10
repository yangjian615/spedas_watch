;+
;PROCEDURE:   mvn_mag_trace
;PURPOSE:
;  Given the spacecraft ephemeris and the mag vector in GEO coordinates,
;  determines whether or not a straight-line extension of the mag vector 
;  intersects the Mars atmosphere at 170 km (nominally), and if so the 
;  location of that intersection point in GEO coordinates.
;
;USAGE:
;  mvn_mag_trace
;INPUTS:
;       None: All data obtained from tplot variables.  The result is 
;             stored in tplot variables.
;  
;KEYWORDS:
;       ALT:       Electron absorption altitude.  Default = 170 km.
;
;       TRACE:     Named variable to hold result: [dist, lon, lat]
;                  Units: km, deg, deg
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-04-08 17:51:58 -0700 (Wed, 08 Apr 2015) $
; $LastChangedRevision: 17260 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_trace.pro $
;
;CREATED BY:	David L. Mitchell  2015-04-02
;-
pro mvn_mag_trace, alt=alt, trace=T

  common mav_orb_tplt, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
                       lon, lat, hgt, mex, rcols

  if not keyword_set(alt) then alt = 170.

  R_m = 3389.9D
  R_equ = 3396.2D
  R_pol = 3376.2D
  R_vol = (R_equ*R_equ*R_pol)^(1D/3D)
  R_exo = R_m + alt

  tplot_names,'mvn_B_*_iau_mars',names=mname
  if (mname eq '') then begin
    print,"You must first load MAG data in IAU_MARS coordinates."
    return
  endif
  get_data,mname,data=mag

; Unit vector in direction of B in GEO coordinates

  B = mag.y / (reform([sqrt(total(mag.y*mag.y,2))]) # replicate(1.,3))

; Spacecraft position at each MAG sample time in GEO coordinates

  if (size(state,/type) ne 8) then maven_orbit_tplot,/load
  nsam = n_elements(mag.x)
  S = fltarr(nsam,3)
  S[*,0] = spline(state.time, state.geo_x[*,0], mag.x)
  S[*,1] = spline(state.time, state.geo_x[*,1], mag.x)
  S[*,2] = spline(state.time, state.geo_x[*,2], mag.x)
  S2 = reform([total(S*S,2)])

; Determine if/where the projected magnetic field line intersects the
; atmosphere at 170 km altitude and the spacecraft is above 170 km.

  SdotB = reform([total(S*B,2)])
  SdotB2 = SdotB*SdotB

  S2mR2 = S2 - (R_exo*R_exo)

  indx = where((SdotB2 ge S2mR2) and (S2mR2 gt 0), count)

  if (count gt 0L) then begin
  
    T = replicate(!values.f_nan, nsam, 3)

    SdotB = SdotB[indx]
    SdotB2 = SdotB2[indx]
    S2mR2 = S2mR2[indx]

    S = S[indx,*]
    B = B[indx,*]

    sign = replicate(1., count)
    jndx = where(SdotB lt 0., jcnt)
    if (jcnt gt 0L) then sign[jndx] = -1.

    dist = -SdotB + sign*sqrt(SdotB2 - S2mR2)

    loc = S + (dist # replicate(1.,3))*B

    lon = atan(loc[*,1], loc[*,0])/!dtor
    jndx = where(lon lt 0., jcnt)
    if (jcnt gt 0L) then lon[jndx] = lon[jndx] + 360.
    lat = asin((loc[*,2] / R_exo) < 1.)/!dtor

    T[indx,0] = reform(dist)
    T[indx,1] = reform(lon)
    T[indx,2] = reform(lat)
    
    polarity = replicate(!values.f_nan, nsam, 2)
    jndx = where(dist lt 0., count)
    if (count gt 0L) then polarity[indx[jndx],*] = -1.
    jndx = where(dist ge 0., count)
    if (count gt 0L) then polarity[indx[jndx],*] = 1.
    store_data,'B_trace_pol',data={x:mag.x, y:polarity, v:[0,1]}
    ylim,'B_trace_pol',0,1,0
    zlim,'B_trace_pol',-1,1,0
    options,'B_trace_pol','spec',1
    options,'B_trace_pol','panel_size',0.1
    options,'B_trace_pol','ytitle',''
    options,'B_trace_pol','yticks',1
    options,'B_trace_pol','yminor',1
    options,'B_trace_pol','no_interp',1
    options,'B_trace_pol','xstyle',4
    options,'B_trace_pol','ystyle',4
    options,'B_trace_pol','no_color_scale',1
    
    store_data,'B_trace_dist',data={x:mag.x, y:abs(T[*,0])}
    options,'B_trace_dist','ytitle','Dist (km)'
    store_data,'B_trace_lon',data={x:mag.x, y:T[*,1]}
    options,'B_trace_lon','ytitle','Lon (deg)'
    ylim,'B_trace_lon',0,360,0
    options,'B_trace_lon','yticks',4
    options,'B_trace_lon','yminor',3
    store_data,'B_trace_lat',data={x:mag.x, y:T[*,2]}
    ylim,'B_trace_lat',-90,90,0
    options,'B_trace_lat','yticks',3
    options,'B_trace_lat','yminor',3

  endif

  return

end
