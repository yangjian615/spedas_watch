;+
;PROCEDURE:   GET_MVN_EPH
;PURPOSE:
;  Locates and reads MAVEN spacecraft ephemeris data.  The result is
;  packaged into a common block structure and returned.
;
;  The available coordinate frames are:
;
;   GEO = body-fixed Mars geographic coordinates (non-inertial) = IAU_MARS
;         (sometimes called planetocentric (PC) coordinates)
;              X ->  0 deg E longitude, 0 deg latitude
;              Y -> 90 deg E longitude, 0 deg latitude
;              Z -> 90 deg N latitude (= X x Y)
;              origin = center of Mars
;              units = kilometers
;
;   MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;              X -> from center of Mars to center of Sun
;              Y -> opposite to Mars' orbital angular velocity vector
;              Z = X x Y
;              origin = center of Mars
;              units = kilometers
;
;USAGE:
;  get_mvn_eph, trange, eph
;
;INPUTS:
;       tvar:       An array in any format accepted by time_double().
;                   You explicitly input the specified time you want to get.
;
;       eph:        A named variable to hold the result.
;
;KEYWORDS:
;       resolution: The time resolution with which you want to get
;                   the ephemeris data can be determined.
;
;       silent:     Minimizes the information shown in the terminal.
;
;       make_array: Even if you do not use the "resolution" keyword,  
;                   10,000 elements structure array is automatically returned.
;
;       status:     Returns the calculation status:
;                      0 = no data found
;                      1 = partial data found
;                      2 = complete data found
;
;CREATED BY:	Takuya Hara  on 2014-10-07.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2014-11-26 11:42:32 -0800 (Wed, 26 Nov 2014) $
; $LastChangedRevision: 16310 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/get_mvn_eph.pro $
;
;MODIFICATION LOG:  
;(YYYY-MM-DD)
; 2014-10-07: Initial version. Usage is very limited.
; 2014-10-13: Enables to directly load SPICE/kernels information. 
; 2014-10-21: Added "vss" keyword. It can restore the spacecraft
;             velocity in the MSO coordinate system. But the data
;             format has not been confirmed yet. It's just TBD now.
; 2014-11-24: No longer using IDL save files utilized by 'maven_orbit_tplot'.
;             Hence, "sav", "date" and "extended" keywords are removed.
;             Removed "vss" keyword. Information about spacecraft
;             velocity is included in default.   
; 2014-11-25: Header description is completely written up.
;             Results are stored into common blocks. 
;
;-
PRO get_mvn_eph, tvar, eph, resolution=res, silent=silent, load=load, $
                 make_array=make_array, status=status, verbose=verbose

  @mvn_eph_com
  R_m = 3389.9d0
  nan = !values.f_nan
  IF ~keyword_set(silent) THEN silent = 0
  IF ~keyword_set(verbose) THEN verbose = - silent

;  IF (SIZE(tvar, /type) EQ 2) OR (SIZE(tvar, /type) EQ 3) THEN BEGIN
;     trange = minmax(mvn_read_orbit_times(tvar))
;     IF N_ELEMENTS(trange) NE 2 THEN BEGIN
;        dprint, 'Time interval cannot be obtained from the orbit number.'
;        status = 0
;        RETURN
;     ENDIF ELSE BEGIN
;        print, ptrace()
;        print, '  Time interval: ' + time_string(MIN(trange)) + $
;               ' - ' + time_string(MAX(trange))
;     ENDELSE 
;  ENDIF  
  IF SIZE(trange, /type) EQ 0 THEN trange = tvar
  IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)

  IF (SIZE(res, /type) EQ 0) AND (keyword_set(make_array)) THEN $
     res = 1 > (trange[1]-trange[0])/10000d < 86400
  IF SIZE(res, /type) NE 0 THEN $     
     utc = dgen(range=trange, resolution=res) $
  ELSE utc = trange

  lflg = 0
  IF SIZE(mvn_eph_dat, /type) NE 8 THEN lflg = 1 $
  ELSE IF (MIN(utc) LT MIN(mvn_eph_dat.time)) OR $
     (MAX(utc) GT MAX(mvn_eph_dat.time)) THEN lflg = 1
  IF keyword_set(load) THEN lflg = 1
  IF (lflg) THEN BEGIN
     mvn_eph_dat = 0.
     mk = mvn_spice_kernels(/load, /all, trange=trange, verbose=verbose)

     dformat = {t: 0D, x: 0D,  y: 0D, z: 0D, vx: 0D, vy: 0D, vz: 0D}

     object = ['MARS', 'MAVEN_SPACECRAFT'] 
     valid = spice_valid_times(time_ephemeris(utc), object=object)
     idx = WHERE(valid NE 0, ndat)
     dprint, dlevel=2, verbose=verbose, ndat, ' Valid times from:', object
     IF ndat EQ 0 THEN BEGIN
        dprint, 'Insufficient SPICE/kernels data.'
        status = 0
        RETURN
     ENDIF 

     IF ndat NE N_ELEMENTS(utc) THEN BEGIN
        dprint, 'SPICE/kernels data is partially available.'
        status = 1
     ENDIF 
     undefine, idx, ndat 
     pos_ss = spice_body_pos('MAVEN', 'MARS', utc=utc, frame='MSO')
     vss    = spice_body_vel('MAVEN', 'MARS', utc=utc, frame='MSO')
     pos_pc = spice_body_pos('MAVEN', 'MARS', utc=utc, frame='IAU_MARS')

     maven = REPLICATE(dformat, N_ELEMENTS(utc))
     maven_g = maven
  
     maven.t = utc
     maven.x = REFORM(pos_ss[0, *])
     maven.y = REFORM(pos_ss[1, *])
     maven.z = REFORM(pos_ss[2, *])
     maven.vx = REFORM(vss[0, *])
     maven.vy = REFORM(vss[1, *])
     maven.vz = REFORM(vss[2, *])
     maven_g.t = utc
     maven_g.x = REFORM(pos_pc[0, *])
     maven_g.y = REFORM(pos_pc[1, *])
     maven_g.z = REFORM(pos_pc[2, *])
     undefine, pos_ss, pos_pc, vss, dformat
     
     time = maven.t
     xss = maven.x
     yss = maven.y
     zss = maven.z
     vx  = maven.vx
     vy  = maven.vy
     vz  = maven.vz

     r = SQRT(xss*xss + yss*yss + zss*zss)
     s = SQRT(yss*yss + zss*zss)
     sza = ATAN(s, xss)
     
     xpc = maven_g.x
     ypc = maven_g.y
     zpc = maven_g.z
     lon = ATAN(ypc, xpc)
     lat = ASIN(zpc / r)
     hgt = r - R_m
    
     idx = WHERE(lon LE 0., count)
     IF (count GT 0L) THEN lon[idx] += 2.*!DPI
     undefine, idx

     ndat = N_ELEMENTS(time)
     eph = mvn_eph_struct(ndat, init=nan)
     eph.time = time
     eph.x_ss = xss
     eph.y_ss = yss
     eph.z_ss = zss
     eph.vx_ss = vx
     eph.vy_ss = vy
     eph.vz_ss = vz
     eph.x_pc = xpc
     eph.y_pc = ypc
     eph.z_pc = zpc
     eph.elon = lon
     eph.lat = lat
     eph.alt = hgt
     eph.sza = sza
     mvn_eph_dat = eph
  ENDIF ELSE $
     mvn_eph_resample, utc, mvn_eph_dat, eph 

  IF SIZE(status, /type) EQ 0 THEN status = 2
  RETURN
END 
