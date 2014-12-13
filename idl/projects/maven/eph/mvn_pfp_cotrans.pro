;+
;PROCEDURE: 
;	MVN_PFP_COTRANS
;
;PURPOSE:
;       Performs the coordinate transformation from the MAVEN PFP
;       instrument cooridnate system to that of you set.
;       Now SWIA, SWEA, STATIC coordinate systems are applicable.
;
;CALLING SEQUENCE: 
;	mvn_pfp_cotrans, data, from='MAVEN_STATIC', to='MAVEN_MSO', $
;                        vx=vx, vy=vy, vz=vz, theta=theta, phi=phi, $
;                        px=px, py=py, pz=pz
;
;INPUTS: 
;   Any SWIA, SWEA, and STATIC data.
;   These data should be derived from the following functions:
;      - SWIA: mvn_swia_get_3dc(), mvn_swia_get_3df(), mvn_swia_get_3ds().
;      - SWEA: mvn_swe_get3d(), mvn_swe_getpad(), mvn_swe_getspec().   
;      - STATIC: mvn_sta_get_**(); (** corresponds to any apid modes).
;
;KEYWORDS:
;   FROM:      Defines the initial coordinate system as string. 
;
;   TO:        Defines the coordinate system to which you want to convert. 
;             
;              Both "from" and "to" keywords must be defined the
;              coordinate system written in the MAVEN SPICE frame kernels.
;              It means that the coordinate system(s) derived from the 
;              SPICE/Kernels can be utilized, such as 'MAVEN_MSO', 'IAU_MARS', 
;              or so on in the present version.
;
;              In additions, this procedure can convert to the 2 new
;              useful coordinate system.  
;
;              One is the local geographic coordinate system, which is
;              defined as 'LGEO'.
;              The coordinate system is centered at the spacecraft and
;              decomposes into zonal(East-West), meridional(North-South), 
;              and radial components:
;                  - X: Positive toward the local East.
;                  - Y: Positive toward the local North.
;                  - Z: Positive away from the planetary surface.        
;              This coordinate system has been utilized in MGS IMF
;              draping direction proxy.     
;
;              The other is the streamline-aligned geographic coordinate system,
;              which is defined as 'SGEO'.
;              The coordinate system is centered at the spacecraft.
;              The streamline direction is determined under the assumption
;              that flow is symmetrical both the Mars-Sun line and mainly 
;              tangential(horizontal) to the obstracle.
;                  - X: Streamline flown from the dayside to nightside.
;                  - Y: Z x X (Completes right-handed system; horizontal).
;                  - Z: Positive away from the planetary surface.  
;              The detailed definision and useful figure are shown in  
;              Strangeway and Russell [1996, JGR].
;
;   Vi:        (i=X, Y, Z). 
;              Returns unit vector compnents in the new coordinate system. 
;
;   THETA:     Returns the polar angle in the new coordinate system.
;
;   PHI:       Returns the azimuth angle in the new coordinate system.
;
;   Pi:        (i=X, Y, Z). 
;              Returns the instrument axis direction in the new coordinate system. 
;
;   STATUS:    Returns the conversion result (0:Fail/1:Success). 
;
;   SPICE_LOAD: Loads the MAVEN SPICE/kernels. 
; 
;CREATED BY: 
;	Takuya Hara  on 2014-11-24.
;
; $LastChangedBy: hara $
; $LastChangedDate: 2014-12-09 17:51:20 -0800 (Tue, 09 Dec 2014) $
; $LastChangedRevision: 16430 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/mvn_pfp_cotrans.pro $
;
;MODIFICATION LOG:
;(YYYY-MM-DD)
; 2014-11-24: Starts to prepare this routine.
; 2014-12-09: Header description is written up.
;
;-
PRO mvn_pfp_cotrans, var, from=from, to=to, verbose=verbose, $
                     vx=vxn, vy=vyn, vz=vzn, $
                     theta=thetan, phi=phin, status=status, $
                     spice_load=spice_load, $
                     px=px, py=py, pz=pz;, no_ignore=no_ignore
  dat = var
  time = (dat.time + dat.end_time)/2.d0 
  theta = dat.theta
  phi = dat.phi
  
  IF ~keyword_set(from) THEN from = 'MAVEN_SPACECRAFT'
  IF keyword_set(spice_load) THEN $
     mk = mvn_spice_kernels(/load, /all, trange=time, verbose=verbose)

  IF ~keyword_set(to) THEN BEGIN
     dprint, 'You must specify a coordinate system to which you want to convert.'
     status = 0
     RETURN
  ENDIF ELSE BEGIN
     to = STRUPCASE(to)
     IF (to EQ 'SGEO') THEN BEGIN ; 
        to2 = to
        to = 'IAU_MARS'
     ENDIF 
     IF (to EQ 'LGEO') THEN BEGIN
        to2 = to
        to = 'MAVEN_MSO'
     ENDIF 
  ENDELSE 

  sphere_to_cart, 1.d0, dat.theta, dat.phi, vx, vy, vz
  et = time_ephemeris(time)
  objects = ['MARS', 'MAVEN_SPACECRAFT']
;;  valid = spice_valid_times(et, object=objects, /no_ignore)
  valid = spice_valid_times(et, object=objects)
  IF valid EQ 0B THEN BEGIN
     dprint, 'SPICE/kernels are invalid.'
     status = 0
     IF keyword_set(to2) THEN to = to2
     RETURN
  ENDIF 

  q = spice_body_att(from, to, time, $
                     /quaternion, verbose=verbose)
  
  t2 =   q[0]*q[1]              ;- cf. quaternion_rotation.pro
  t3 =   q[0]*q[2]
  t4 =   q[0]*q[3]
  t5 =  -q[1]*q[1]
  t6 =   q[1]*q[2]
  t7 =   q[1]*q[3]
  t8 =  -q[2]*q[2]
  t9 =   q[2]*q[3]
  t10 = -q[3]*q[3]
  
  vxn = 2*( (t8 + t10)*vx + (t6 -  t4)*vy + (t3 + t7)*vz ) + vx
  vyn = 2*( (t4 +  t6)*vx + (t5 + t10)*vy + (t9 - t2)*vz ) + vy
  vzn = 2*( (t7 -  t3)*vx + (t2 +  t9)*vy + (t5 + t8)*vz ) + vz

  thetan = 90. - ACOS(vzn)*!RADEG
  phin = ATAN(vyn, vxn) * !RADEG 
  px = FLTARR(3)
  py = px  &  pz = px
 
  px[0] = 2*( (t8 + t10)*1. + (t6 -  t4)*0. + (t3 + t7)*0. ) + 1.
  px[1] = 2*( (t4 +  t6)*1. + (t5 + t10)*0. + (t9 - t2)*0. ) + 0.
  px[2] = 2*( (t7 -  t3)*1. + (t2 +  t9)*0. + (t5 + t8)*0. ) + 0.
  py[0] = 2*( (t8 + t10)*0. + (t6 -  t4)*1. + (t3 + t7)*0. ) + 0.
  py[1] = 2*( (t4 +  t6)*0. + (t5 + t10)*1. + (t9 - t2)*0. ) + 1.
  py[2] = 2*( (t7 -  t3)*0. + (t2 +  t9)*1. + (t5 + t8)*0. ) + 0.
  pz[0] = 2*( (t8 + t10)*0. + (t6 -  t4)*0. + (t3 + t7)*1. ) + 0.
  pz[1] = 2*( (t4 +  t6)*0. + (t5 + t10)*0. + (t9 - t2)*1. ) + 0.
  pz[2] = 2*( (t7 -  t3)*0. + (t2 +  t9)*0. + (t5 + t8)*1. ) + 1.
  
  IF NOT keyword_set(to2) THEN BEGIN
     status = 1
     RETURN
  ENDIF 
  undefine, vx, vy, vz, theta, phi

  vx = vxn
  vy = vyn
  vz = vzn
  theta = thetan
  phi = phin
  undefine, vxn, vyn, vzn , thetan, phin

  get_mvn_eph, time, pos, /silent
  IF to2 EQ 'LGEO' THEN BEGIN
     lat = pos.lat
     lon = pos.elon

     mtx = DBLARR(3, 3)
     mtx[0, 0] = -SIN(lon)
     mtx[1, 0] =  COS(lon)
     mtx[2, 0] =  0.d0
     mtx[0, 1] = -COS(lon) * SIN(lat)
     mtx[1, 1] = -SIN(lon) * SIN(lat)
     mtx[2, 1] =  COS(lat)
     mtx[0, 2] =  COS(lon) * COS(lat)
     mtx[1, 2] =  SIN(lon) * COS(lat)
     mtx[2, 2] =  SIN(lat)
  ENDIF 
  IF to2 EQ 'SGEO' THEN BEGIN
     rvec = DOUBLE([pos.x_ss, pos.y_ss, pos.z_ss])

     xmso = [1D, 0D, 0D]
     pvec = crossp2(xmso, rvec) 
     pvec = pvec / SQRT(TOTAL(pvec*pvec))

     fvec = crossp2(pvec, rvec) 
     fvec = fvec / SQRT(TOTAL(fvec*fvec))
     rvec = rvec / SQRT(TOTAL(rvec*rvec))

     mtx = [ [fvec], [pvec], [rvec] ]
     undefine, fvec, pvec, rvec, xmso
  ENDIF 

  vxn = vx
  vyn = vy
  vzn = vz
  vxn[*] = 0.  &  vyn[*] = 0.  &  vzn[*] = 0.

  IF tag_exist(dat, 'nmass') THEN BEGIN
     FOR i=0, dat.nenergy-1 DO FOR j=0, dat.nbins-1 DO FOR k=0, dat.nmass-1 DO BEGIN
        vector  = [ vx[i, j, k], vy[i, j, k], vz[i, j, k] ]
        vectorp = TRANSPOSE(mtx ## TRANSPOSE(vector))
        vxn[i, j, k] = vectorp[0] 
        vyn[i, j, k] = vectorp[1]
        vzn[i, j, k] = vectorp[2]
        undefine, vector, vectorp
     ENDFOR 
  ENDIF ELSE BEGIN
     FOR i=0, dat.nenergy-1 DO FOR j=0, dat.nbins-1 DO BEGIN
        vector  = [ vx[i, j], vy[i, j], vz[i, j] ]
        vectorp = TRANSPOSE(mtx ## TRANSPOSE(vector))
        vxn[i, j] = vectorp[0] 
        vyn[i, j] = vectorp[1]
        vzn[i, j] = vectorp[2]
        undefine, vector, vectorp
     ENDFOR 
  ENDELSE 
  thetan = 90. - ACOS(vzn)*!RADEG
  phin = ATAN(vyn, vxn) * !RADEG 
  px = TRANSPOSE(mtx ## TRANSPOSE(px))
  py = TRANSPOSE(mtx ## TRANSPOSE(py))
  pz = TRANSPOSE(mtx ## TRANSPOSE(pz))
  status = 1
  to = to2
  RETURN
END
