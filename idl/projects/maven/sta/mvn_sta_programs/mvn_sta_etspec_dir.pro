;+
;
;PROCEDURE:  
;       MVN_STA_ETSPEC_DIR
;
;PURPOSE:
;       Makes directional Energy-time spectrograms in the specified frame from STATIC data.
;       6 tplot variables will be generated: +X, -X, +Y, -Y, +Z, and -Z.
;
;CALLING SEQUENCE:
;       mvn_sta_etspec_dir
;
;INPUTS:
;   APID:       Not necessary, but you can explicitly specify STATIC
;               APID to use. Default is 'd0'.
;               (Note that STATIC data and SPICE kernels need to be
;                loaded beforehand).
;
;KEYWORDS:      (all keywords are optional.)
;   FRAME:      Specifies the frame (Def: 'MSO').
;
;   UNITS:      Specifies the units ('eflux', 'counts', etc.).
;               (Def: 'eflux')
;
;   THLD_THETA: theta_v > thld_theta => +Z,
;               theta_v < -thld_theta => -Z (Def: 45).
;
;   ATTVEC:     Generates tplot variables showing STATIC XYZ vectors
;               in the specified frame.
;
;   TRANGE:     Time range to compute directional spectra (Def: all).
;
;   MASS:       Specifies mass per charge ranges which you want to use.
;               Default is optimized to be O+ (atomic oxygen ions).      
;
;CREATED BY:    Takuya Hara  on 2014-11-25.
;
; $LastChangedBy: hara $
; $LastChangedDate: 2015-01-21 16:52:44 -0800 (Wed, 21 Jan 2015) $
; $LastChangedRevision: 16702 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_programs/mvn_sta_etspec_dir.pro $
;
;MODIFICATION LOG:
;(YYYY-MM-DD)
; 2014-11-25: Initial procedure is prepared. This routine originally
;             developed by Yuki Harada for the SWIA data on 2014-11-20. 
;             Based on his routine, this routine is made.
;
;-

PRO mvn_sta_etspec_dir, apid, frame=frame, units=units, thld_theta=thld_theta, attvec=attvec, $
                        trange=trange, verbose=verbose, mass=mass, suffix=suffix
  nan = !values.f_nan
  IF ~keyword_set(apid) THEN apid = 'd0' 
  IF ~keyword_set(frame) THEN frame='MSO'
  IF ~keyword_set(units) THEN units='eflux'
  IF ~keyword_set(suffix) THEN suffix = '' 
  IF ~keyword_set(mass) THEN mass = [12., 20.] ; for O+ 
  fun_name = 'mvn_sta_get_' + apid
  time = call_function(fun_name, /times)
  if keyword_set(thld_theta) then thld_theta = abs(thld_theta) else thld_theta = 45
  if keyword_set(trange) then begin
     idx = where(time ge trange[0] and time le trange[1], idx_cnt)
     if idx_cnt gt 0 then time = time[idx] else begin
        dprint,dlevel=1,verbose=verbose,'No data in the specified time range.'
        return
     endelse
  endif

  center_time = dblarr(n_elements(time))

  for i=0ll,n_elements(time)-1 do begin ;- time loop

     if i mod 100 eq 0 then dprint,dlevel=1,verbose=verbose,i,' /',n_elements(time)
      d = call_function(fun_name, time[i]) 
      d = conv_units(d,units)
      center_time[i] = (d.time+d.end_time)/2.d


      IF i EQ 0LL THEN BEGIN
         energy = fltarr(n_elements(time),d.nenergy)
         
         eflux_pX = fltarr(n_elements(time), d.nenergy)
         eflux_mX = fltarr(n_elements(time), d.nenergy)
         eflux_pY = fltarr(n_elements(time), d.nenergy)
         eflux_mY = fltarr(n_elements(time), d.nenergy)
         eflux_pZ = fltarr(n_elements(time), d.nenergy)
         eflux_mZ = fltarr(n_elements(time), d.nenergy)
         
         pX_new = fltarr(n_elements(time), 3)
         pY_new = fltarr(n_elements(time), 3)
         pZ_new = fltarr(n_elements(time), 3)
      ENDIF 

      ind = where(d.mass_arr lt mass[0] or d.mass_arr gt mass[1], count)
      if count ne 0 then d.data[ind] = 0.
      undefine, ind, count

      mvn_pfp_cotrans, d, from='MAVEN_STATIC', to=frame, vx=vxnew, vy=vynew, vz=vznew, $
                       theta=thetanew, phi=phinew, px=px, py=py, pz=pz, verbose=-1, status=status

      energy[i, *] = average(average(d.energy, 3), 2)
      IF status EQ 0 THEN BEGIN
         vxnew[*] = nan
         vynew[*] = nan
         vznew[*] = nan
         thetanew[*] = nan
         phinew[*] = nan
         
         px[*] = nan
         py[*] = nan
         pz[*] = nan
         undefine, status
      ENDIF
 
      IF keyword_set(attvec) THEN BEGIN
         pX_new[i, *] = px
         pY_new[i, *] = py
         pZ_new[i, *] = pz
      ENDIF 

      weight = FLTARR(d.nenergy, d.nbins, d.nmass)
      weight[*] = 0.
      idx = WHERE( abs(thetanew) LE thld_theta $ ;- +X
                   AND abs(phinew) LE 45, idx_cnt )      
      IF idx_cnt GT 0 THEN BEGIN
         weight[idx] = 1.
         IF STRLOWCASE(units) NE 'counts' THEN $
            eflux_pX[i, *] = TOTAL( TOTAL( (d.data*weight) * (d.domega*weight), 3), 2) $
                             / TOTAL(TOTAL((d.domega * weight), 3), 2) $
         ELSE eflux_pX[i, *] = TOTAL(TOTAL((d.data*weight), 3), 2)
      ENDIF ELSE eflux_pX[i, *] = nan  

      undefine, weight, idx, idx_cnt
      weight = FLTARR(d.nenergy, d.nbins, d.nmass)
      weight[*] = 0.
      idx = WHERE( ABS(thetanew) LE thld_theta $ ;- -X
                   AND ABS(phinew) GE 135, idx_cnt )         
      IF idx_cnt GT 0 THEN BEGIN
         weight[idx] = 1.
         IF STRLOWCASE(units) NE 'counts' THEN $
            eflux_mX[i, *] = TOTAL( TOTAL( (d.data*weight) * (d.domega*weight), 3), 2) $
                             / TOTAL(TOTAL((d.domega * weight), 3), 2) $
         ELSE eflux_mX[i, *] = TOTAL(TOTAL((d.data*weight), 3), 2)
      ENDIF ELSE eflux_mX[i, *] = nan  

      undefine, weight, idx, idx_cnt
      weight = FLTARR(d.nenergy, d.nbins, d.nmass)
      weight[*] = 0.
      idx = WHERE( ABS(thetanew) LE thld_theta $ ;- +Y
                   AND phinew GT 45 AND phinew LT 135, idx_cnt )
      IF idx_cnt GT 0 THEN BEGIN
         weight[idx] = 1.
         IF STRLOWCASE(units) NE 'counts' THEN $
            eflux_pY[i, *] = TOTAL( TOTAL( (d.data*weight) * (d.domega*weight), 3), 2) $
                             / TOTAL(TOTAL((d.domega * weight), 3), 2) $
         ELSE eflux_pY[i, *] = TOTAL(TOTAL((d.data*weight), 3), 2)
      ENDIF ELSE eflux_pY[i, *] = nan  

      undefine, weight, idx, idx_cnt
      weight = FLTARR(d.nenergy, d.nbins, d.nmass)
      weight[*] = 0.
      idx = WHERE( ABS(thetanew) LE thld_theta $ ;- -Y
                   AND phinew GT -135 AND phinew LT -45, idx_cnt )
      IF idx_cnt GT 0 THEN BEGIN
         weight[idx] = 1.
         IF STRLOWCASE(units) NE 'counts' THEN $
            eflux_mY[i, *] = TOTAL( TOTAL( (d.data*weight) * (d.domega*weight), 3), 2) $
                             / TOTAL(TOTAL((d.domega * weight), 3), 2) $
         ELSE eflux_mY[i, *] = TOTAL(TOTAL((d.data*weight), 3), 2)
      ENDIF ELSE eflux_mY[i, *] = nan  

      undefine, weight, idx, idx_cnt
      weight = FLTARR(d.nenergy, d.nbins, d.nmass)
      weight[*] = 0.
      idx = WHERE( thetanew GT thld_theta, idx_cnt ) ;- +Z
      IF idx_cnt GT 0 THEN BEGIN
         weight[idx] = 1.
         IF STRLOWCASE(units) NE 'counts' THEN $
            eflux_pZ[i, *] = TOTAL( TOTAL( (d.data*weight) * (d.domega*weight), 3), 2) $
                             / TOTAL(TOTAL((d.domega * weight), 3), 2) $
         ELSE eflux_pZ[i, *] = TOTAL(TOTAL((d.data*weight), 3), 2)
      ENDIF ELSE eflux_pZ[i, *] = nan  

      undefine, weight, idx, idx_cnt
      weight = FLTARR(d.nenergy, d.nbins, d.nmass)
      weight[*] = 0.
      idx = WHERE( thetanew LT -thld_theta, idx_cnt ) ;- -Z
      IF idx_cnt GT 0 THEN BEGIN
         weight[idx] = 1.
         IF STRLOWCASE(units) NE 'counts' THEN $
            eflux_mZ[i, *] = TOTAL( TOTAL( (d.data*weight) * (d.domega*weight), 3), 2) $
                             / TOTAL(TOTAL((d.domega * weight), 3), 2) $
         ELSE eflux_mZ[i, *] = TOTAL(TOTAL((d.data*weight), 3), 2)
      ENDIF ELSE eflux_mZ[i, *] = nan  

      undefine, weight, idx, idx_cnt
   ENDFOR                        ;- time loop end

  type = 'sta_' + apid
  yname = 'STA ' + STRUPCASE(apid)
  frame = STRLOWCASE(frame)
  store_data, 'mvn_'+type+'_en_'+units+'_'+frame+'_px'+suffix, $
              data={x: center_time, y:eflux_pX, v:energy}, $
              dlim={spec:1, zlog:1, ylog:1, yrange:minmax(energy), ystyle:1, $
                    ytitle: yname + '!C+X' + STRLOWCASE(frame) + '!CEnergy [eV]', $
                    ztitle: units}, verbose=verbose
  store_data, 'mvn_'+type+'_en_'+units+'_'+frame+'_mx'+suffix, $
              data={x: center_time, y:eflux_mX, v:energy}, $
              dlim={spec:1, zlog:1, ylog:1, yrange:minmax(energy), ystyle:1, $
                    ytitle: yname + '!C-X' + STRLOWCASE(frame) + '!CEnergy [eV]', $
                    ztitle: units}, verbose=verbose
  store_data, 'mvn_'+type+'_en_'+units+'_'+frame+'_py'+suffix, $
              data={x: center_time, y:eflux_pY, v:energy}, $
              dlim={spec:1, zlog:1, ylog:1, yrange:minmax(energy), ystyle:1, $
                    ytitle: yname + '!C+Y' + STRLOWCASE(frame) + '!CEnergy [eV]', $
                    ztitle: units}, verbose=verbose
  store_data, 'mvn_'+type+'_en_'+units+'_'+frame+'_my'+suffix, $
              data={x: center_time, y: eflux_mY, v: energy}, $
              dlim={spec:1, zlog:1, ylog:1, yrange:minmax(energy), ystyle:1, $
                    ytitle: yname + '!C-Y' + STRLOWCASE(frame) + '!CEnergy [eV]', $
                    ztitle: units}, verbose=verbose
  store_data, 'mvn_'+type+'_en_'+units+'_'+frame+'_pz'+suffix, $
              data={x: center_time, y: eflux_pZ, v: energy}, $
              dlim={spec:1, zlog:1, ylog:1, yrange:minmax(energy), ystyle:1, $
                    ytitle: yname + '!C+Z' + STRLOWCASE(frame) + '!CEnergy [eV]', $
                    ztitle: units}, verbose=verbose
  store_data, 'mvn_'+type+'_en_'+units+'_'+frame+'_mz'+suffix, $
              data={x: center_time, y: eflux_mZ, v: energy}, $
              dlim={spec:1, zlog:1, ylog:1, yrange:minmax(energy), ystyle:1, $
                    ytitle: yname + '!C-Z' + STRLOWCASE(frame) + '!CEnergy [eV]', $
                    ztitle: units}, verbose=verbose
  options, 'mvn_'+type+'_en_'+units+'_'+frame+'_*', datagap=600.

  FOR i=0, 1 DO $
     IF mass[i] GE 1. THEN append_array, mf, '(I0)' ELSE append_array, mf, '(F0.1)'
  options, 'mvn_'+type+'_en_'+units+'_'+frame+'_*', ysubtitle='m/q: ' + STRING(mass[0], mf[0]) + '-' + STRING(mass[1], mf[1]), /def

  IF keyword_set(attvec) THEN BEGIN
     store_data,'mvn_'+type+'_'+frame+'_xvec'+suffix, $
                data={x:center_time,y:pX_new}, $
                dlim={yrange:[-1.25,1.25],ystyle:1,labflag:1, $
                      ytitle:'X!c'+frame, constant: 0, yminor: 4, ytickinterval: 1, $
                      labels:['x','y','z'],colors:'bgr'},verbose=verbose
     store_data,'mvn_'+type+'_'+frame+'_yvec'+suffix, $
                data={x:center_time,y:pY_new}, $
                dlim={yrange:[-1.25,1.25],ystyle:1,labflag:1, $
                      ytitle:'Y!c'+frame, constant: 0, yminor: 4, ytickinterval: 1, $
                      labels:['x','y','z'],colors:'bgr'},verbose=verbose
     store_data,'mvn_'+type+'_'+frame+'_zvec'+suffix, $
                data={x:center_time,y:pZ_new}, $
                dlim={yrange:[-1.25,1.25],ystyle:1,labflag:1, $
                      ytitle:'Z!c'+frame, constant: 0, yminor: 4, ytickinterval: 1, $
                      labels:['x','y','z'],colors:'bgr'},verbose=verbose
  ENDIF
  RETURN
END
