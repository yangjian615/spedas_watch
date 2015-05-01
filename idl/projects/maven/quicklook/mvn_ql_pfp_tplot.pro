;+
;
;PROCEDURE:       MVN_QL_PFP_TPLOT
;
;PURPOSE:         Creates quicklook summary tplot(s) of MAVEN PF packages. 
;
;INPUTS:          
;
;      TRANGE:    An array in any format accepted by time_double().
;                 The minimum and maximum values in this array specify
;                 the time range to load.
;
;KEYWORDS:
;
;       ORBIT:    Specifies the time range to show by using
;                 orbit number or range of orbit numbers (trange is ignored).
;                 Orbits are numbered using the NAIF convention, where
;                 the orbit number increments at periapsis. Data are
;                 loaded from the apoapsis preceding the first orbit
;                 (periapsis) number to the apoapsis following the
;                 last orbit number.
;
;   NO_DELETE:    Not deleting pre-exist tplot variable(s).
;
;         PAD:    Restores the SWEA resampling PAD tplot save files by
;                 using 'mvn_swe_pad_restore'. 
;   
;       TPLOT:    Plots the summary tplots.
;
;      WINDOW:    Sets the window number to show tplots.
;                 Default is 0.
;
;       TNAME:    Returns the tplot names to plot (or defines the
;                 tplot names to plot if user knows the precise names).
;
;      PHOBOS:    Computes the MAVEN and Phobos distance by 'mvn_phobos_tplot'.
;
;      BCRUST:    Defines to execute calculating the crustal magnetic
;                 field model, if tplot save files are not available. 
;
;   BURST_BAR:    Draw a color bar during the time intervals when the burst
;                 (archive) PFP data has been already downlinked and available.  
;
;NOTE:            This routine is assumed to be used when there are
;                 no tplot variables.
;
;CREATED BY:      Takuya Hara on 2015-04-09.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-04-29 23:59:26 -0700 (Wed, 29 Apr 2015) $
; $LastChangedRevision: 17454 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_ql_pfp_tplot.pro $
;
;-
; Subroutine
FUNCTION mvn_ql_pfp_tplot_exponent, axis, index, number
  times = 'x'
  ; A special case.
  IF number EQ 0 THEN RETURN, '0'

  ; Assuming multiples of 10 with format.
  ex = String(number, Format='(e8.0)')
  pt = StrPos(ex, '.')
  
  first = StrMid(ex, 0, pt)
  sign = StrMid(ex, pt+2, 1)
  thisExponent = StrMid(ex, pt+3)

  ; Shave off leading zero in exponent
  WHILE StrMid(thisExponent, 0, 1) EQ '0' DO thisExponent = StrMid(thisExponent, 1)

  ; Fix for sign and missing zero problem.
  IF (Long(thisExponent) EQ 0) THEN BEGIN
     sign = ''
     thisExponent = '0'
  ENDIF
  
  IF (first EQ '  1') OR (first EQ ' 1') THEN BEGIN
     first = ''
     times = ''
  ENDIF
  
  ; Make the exponent a superscript.
  IF sign EQ '-' THEN BEGIN
     RETURN, first + times + '10!U' + sign + thisExponent + '!N'
  ENDIF ELSE BEGIN
     RETURN, first + times + '10!U' + thisExponent + '!N'
  ENDELSE
END

; Main Routine
PRO mvn_ql_pfp_tplot, var, orbit=orbit, verbose=verbose, no_delete=no_delete, $
                      pad=pad, tplot=tplot, window=window, tname=ptname, phobos=phobos, $
                      bcrust=bcrust, burst_bar=bbar

  oneday = 24.d0 * 3600.d0
  nan = !values.f_nan
  IF ~keyword_set(no_delete) THEN store_data, '*', /delete, verbose=verbose
  IF keyword_set(window) THEN wnum = window ELSE wnum = 0
  IF SIZE(bcrust, /type) NE 0 THEN bflg = bcrust
  @mvn_swe_com

  tplot_options, get_options=topt
  IF SIZE(var, /type) NE 0 THEN BEGIN
     trange = time_double(var)
     IF N_ELEMENTS(trange) NE 2 THEN BEGIN
        dprint, 'The time range must be two elements array like [tmin, tmax].'
        RETURN
     ENDIF
  ENDIF ELSE BEGIN
     IF keyword_set(orbit) THEN BEGIN
        imin = MIN(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5, imax+0.5])
        undefine, imin, imax
     ENDIF ELSE BEGIN
        tspan_exists = (MAX(topt.trange_full) GT time_double('2014-09-22'))
        IF (tspan_exists) THEN trange = topt.trange_full
        undefine, tspan_exists
     ENDELSE 
  ENDELSE
  
  IF SIZE(trange, /type) EQ 0 THEN BEGIN
     dprint, 'You must set the specified time interval to load.'
     RETURN
  ENDIF

  mvn_spice_load, trange=trange, /download_only, verbose=verbose

  ; SWEA
  mvn_swe_load_l2, trange, /spec
  IF (SIZE(mvn_swe_engy, /type) NE 8) THEN BEGIN
     dprint, 'No SWEA data found.'
     RETURN
  ENDIF
  vswe = swe_swp[*, 0]
  emin = MIN(vswe, max=emax)

  mvn_swe_convert_units, mvn_swe_engy, 'EFLUX'
  xswe = mvn_swe_engy.time
  yswe = TRANSPOSE(mvn_swe_engy.data)

  idx = WHERE(xswe GE trange[0] AND xswe LE trange[1], nidx)
  IF nidx GT 0 THEN BEGIN
     xswe = xswe[idx]
     yswe = yswe[idx, *]
  ENDIF ELSE BEGIN
     dprint, 'There is no data in the specified time interval.'
     RETURN
  ENDELSE
  undefine, idx, nidx

  store_data, 'mvn_swe_etspec', data={x:xswe, y:yswe, v:vswe}, $
              dlimits={spec: 1, ytitle: 'SWEA', ysubtitle: 'Energy [eV]', yticks: 0, $
                       yminor: 0, y_no_interp: 1, x_no_interp: 1, $
                       ztitle: 'EFlux', datagap: 300}, limit={ytickformat: 'mvn_ql_pfp_tplot_exponent'}
  ylim, 'mvn_swe_etspec', emin, emax, 1, /def
  zlim, 'mvn_swe_etspec', 0, 0, 1, /def
  undefine, xswe, yswe, vswe
  undefine, emin, emax
  IF keyword_set(pad) THEN mvn_swe_pad_restore, trange 

  ; SWIA
  trange_full = time_double( time_string(trange, tformat='YYYY-MM-DD') )
  IF time_string(trange[1], tformat='hh:mm:ss') NE '00:00:00' THEN $
     trange_full[1] += oneday
  IF MEAN(trange - trange_full) NE 0.d0 THEN clip = 1 ELSE clip = 0
  mvn_swia_load_l2_data, trange=trange_full, /tplot, /loadspec, /loadcoarse, /eflux

  undefine, trange_full
  tname = tnames('mvn_swis_en_eflux', ntplot)
  IF ntplot EQ 0 THEN BEGIN
     dprint, 'There is no SWIA tplot variables.'
     RETURN
  ENDIF ELSE BEGIN
     aname = tnames('mvn_swi*')
     idx = WHERE(aname NE tname)
     store_data, aname[idx], /delete, verbose=verbose
     undefine, aname, idx
  ENDELSE

  get_data, tname, data=d, dlim=dl, lim=lim
  extract_tags, d2, d, tags=['x', 'y', 'v']
  extract_tags, dl, d, except=['x', 'y', 'v']
     
  store_data, tname, data=d2, dlim=dl, lim=lim
  IF (clip) THEN time_clip, tname, trange[0], trange[1], /replace
  undefine, d, d2, dl, lim
  
  options, tname, ztitle='EFlux', ytitle='SWIA', ysubtitle='Energy [eV]', ytickformat='mvn_ql_pfp_tplot_exponent'
  undefine, tname, ntplot, clip

  ; STATIC
  mvn_sta_l2_load, trange=trange, sta_apid=['c0', 'c6'] 
  mvn_sta_l2_tplot
  tname = tnames('mvn_sta*', ntplot, index=n)
  statn = 'mvn_sta_c' + ['0_E', '0_H_E', '6_M']
  statn = tnames(statn, index=m)

  IF ntplot EQ 0 THEN BEGIN
     dprint, 'There is no STATIC tplot variables.'
     RETURN
  ENDIF
  state = 'idx = WHERE('
  FOR i=0, N_ELEMENTS(m)-1 DO BEGIN
     state += '(n eq m[' + string(i, '(I0)') + '])'
     IF i NE N_ELEMENTS(m)-1 THEN state += ' OR '
  ENDFOR 
  undefine, i
  state += ', nidx, complement=jdx, ncomplement=njdx)'

  status = EXECUTE(state)
  IF status EQ 1 THEN IF njdx GT 0 THEN store_data, n[jdx], /delete, verbose=verbose
  undefine, idx, jdx, nidx, njdx
  undefine, state, status
  undefine, statn, tname, n, m
  
  tname = tnames('mvn_sta*', ntplot)
  options, tname, ytickformat='mvn_ql_pfp_tplot_exponent', ztitle='EFlux'
  options, tname[0], ysubtitle='Energy [eV]' 
  options, tname[1], ysubtitle='Energy [eV]!CM/q > 12' 
  options, tname[2], ysubtitle='Mass [amu]'

  suffix = STRARR(ntplot)
  product = STRARR(ntplot)
  FOR i=0, ntplot-1 DO BEGIN
     get_data, tname[i], data=d, dl=dl, lim=lim
     extract_tags, dall, dl
     extract_tags, dall, lim
     lim = 0
     IF SIZE(d, /type) EQ 8 THEN $
        store_data, tname[i], data=d, dl=dall, lim=lim $
     ELSE store_data, tname[i], data=STRLOWCASE(d), dl=dall, lim=lim
     IF tname[i] NE STRLOWCASE(tname[i]) THEN $
        store_data, tname[i], newname=STRLOWCASE(tname[i])

     suffix[i] = STRMID(STRLOWCASE(tname[i]), STRLEN(tname[i])-2)
     product[i] = (STRSPLIT(STRLOWCASE(tname[i]), '_', /extract))[2]
     undefine, d, dall, dl, lim
  ENDFOR
  undefine, tname, ntplot

  tname = tnames('mvn_sta*') 
  apid = ['2a','c0','c2','c4','c6','c8', $
          'ca','cc','cd','ce','cf','d0', $
          'd1','d2','d3','d4','d6','d7', $
          'd8','d9','da','db']
  napid = N_ELEMENTS(apid)
  FOR i=0, napid-1 DO BEGIN
     idx = WHERE(product EQ apid[i], cnt)
     IF cnt GT 0 THEN options, tname[idx], ytitle='STA ' + STRUPCASE(apid[i])
     undefine, idx, cnt
  ENDFOR
  undefine, apid, napid
  undefine, tname, suffix, product

  ; SEP
  mvn_sep_load, trange=trange
  store_data, 'mvn_pfdpu*', /delete, verbose=verbose
  store_data, ['APIDS', 'mvn_DPU_TEMP', 'mvn_SEPS_TEMP', 'mvn_pfp_TEMPS', $
               'mvn_SEPS_hkp_VCMD_CNTR', 'mvn_SEPS_hkp_MEM_CHECKSUM',     $
               'mvn_SEPS_svy_ATT', 'mvn_SEPS_svy_COUNTS_TOTAL', 'mvn_SEPS_svy_ALLTID', $
               'mvn_SEPS_QL'], /delete, verbose=verbose

  options, 'mvn_sep1_B-O_Eflux_Energy', ytitle='SEP 1F!CIon', ysubtitle='Energy [keV]', /def
  options, 'mvn_sep2_B-O_Eflux_Energy', ytitle='SEP 2F!CIon', ysubtitle='Energy [keV]', /def
  options, 'mvn_sep1_A-F_Eflux_Energy', ytitle='SEP 1F!Ce!E-!N', ysubtitle='Energy [keV]', /def
  options, 'mvn_sep2_A-F_Eflux_Energy', ytitle='SEP 2F!Ce!E-!N', ysubtitle='Energy [keV]', /def

  tname = tnames('mvn_sep*', index=n)
  septn = 'mvn_sep' + ['1_B-O', '2_B-O', '1_A-F', '2_A-F'] + '_Eflux_Energy'
  septn = tnames(septn, index=m)
  options, septn, panel_size=1., ytickformat='mvn_ql_pfp_tplot_exponent', /def 

  state = 'idx = WHERE('
  FOR i=0, N_ELEMENTS(m)-1 DO BEGIN
     state += '(n eq m[' + string(i, '(I0)') + '])'
     IF i NE N_ELEMENTS(m)-1 THEN state += ' OR '
  ENDFOR 
  undefine, i
  state += ', nidx, complement=jdx, ncomplement=njdx)'

  status = EXECUTE(state)
  IF status EQ 1 THEN IF njdx GT 0 THEN store_data, n[jdx], /delete, verbose=verbose
  undefine, idx, jdx, nidx, njdx
  undefine, state, status
  undefine, septn, tname, n, m

  ; MAG 
  mvn_mag_load, trange=trange
  status = EXECUTE("spice_vector_rotate_tplot, 'mvn_B_1sec', 'MAVEN_MSO', trange=trange, verbose=verbose")
  IF status EQ 1 THEN BEGIN 
     store_data, 'mvn_B_1sec', /delete, verbose=verbose
     store_data, 'mvn_B_1sec_MAVEN_MSO', newname='mvn_mag_l1_bmso_1sec'
     bvec = 'mvn_mag_l1_bmso_1sec'
     frame = 'MSO'
     options, bvec, ysubtitle='Bmso [nT]', def
  ENDIF ELSE BEGIN
     store_data, 'mvn_B_1sec', newname='mvn_mag_l1_bpl_1sec'
     bvec = 'mvn_mag_l1_bpl_1sec'
     frame = 'PL'
     options, bvec, ysubtitle='Bpl [nT]', /def
  ENDELSE 
  options, bvec, labels=['Bx', 'By', 'Bz'], colors='bgr', $
           labflag=1, constant=0, ytitle='MAG', /def
  get_data, bvec, data=b
  undefine, status
  store_data, 'mvn_mag_l1_bamp_1sec', $
              data={x: b.x, y: SQRT(TOTAL(b.y*b.y, 2))}, $
              dlimits={ytitle: 'MAG', ysubtitle: '|B| [nT]'}
  
  mvn_model_bcrust_load, trange, verbose=verbose, calc=bflg
  store_data, 'mvn_mag_bamp', data=['mvn_mag_l1_bamp_1sec', 'mvn_mod_bcrust_amp'], $
              dlimits={labels: ['Bobs.', 'Bmod.'], colors: [0, 2], labflag: 1, ytitle: 'MAG', ysubtitle: '|B| [nT]'} 
  bmax = MAX(SQRT(TOTAL(b.y*b.y, 2)), /nan)
  IF bmax GT 100. THEN blog = 1 ELSE blog = 0 ; It means B field Log scale or not.
  IF (blog) THEN BEGIN
     ylim, 'mvn_mag_bamp', 0.5, bmax*1.1, blog
     options, 'mvn_mag_bamp', ytickformat='mvn_ql_pfp_tplot_exponent'
  ENDIF 
  undefine, bmax, blog

  bphi = ATAN(b.y[*, 1], b.y[*, 0])
  bthe = ASIN(b.y[*, 2] / SQRT(TOTAL(b.y*b.y, 2)))
  idx = WHERE(bphi LT 0., nidx)
  IF nidx GT 0 THEN bphi[idx] += 2. * !pi
  undefine, idx, nidx

  ; In case for author's personal arranged tplot packages:
  ;store_data, 'mvn_mag_l1_bang_1sec', data={x: b.x, y: [ [ 2.*(bthe*!RADEG + 90.) ], [bphi*!RADEG]]}, $
  ;            dlimits={psym: 3, colors: [2, 0], ytitle: 'MAG!CPhi [deg]'}, $
  ;            limits={yticks: 4, yminor: 3, y2axis: 1, y2range: 90.*[-1., 1.], y2ticks: 4, y2minor: 3, $
  ;                    y2color: 2, y2title: 'Theta [deg]', constant: 180.}

  store_data, 'mvn_mag_l1_bang_1sec', data={x: b.x, y: [ [bthe*!RADEG + 180.], [bphi*!RADEG]]}, $
              dlimits={psym: 3, colors: [2, 0], ytitle: 'MAG (' + frame + ')', ysubtitle: 'Angle [deg]', $
                       yticks: 4, yminor: 3, labels: ['Bthe + 180.', 'Bphi'], labflag: 1, constant: 180}
  ylim, 'mvn_mag_l1_bang_1sec', 0., 360., 0., /def
  undefine, bphi, bthe, b

  ; Ephemeris
  maven_orbit_tplot, /current, /load, timecrop=[-2.d0, 2.d0]*oneday + trange ; +/- 2 day is buffer.
  options, 'alt2', panel_size=2./3., ytitle='Alt. [km]'
  
  IF keyword_set(phobos) THEN $
     mvn_phobos_tplot, trange=trange

  IF keyword_set(bbar) THEN BEGIN
     status = EXECUTE("swica = SCOPE_VARFETCH('swica', common='mvn_swia_data')")
     IF status EQ 1 THEN BEGIN
        btime = swica.time_unix + 4.d0 * swica.num_accum/2.d0
        bdata = FLTARR(N_ELEMENTS(btime))
        bdata[*] = 1.
        ; Forward survey
        dt = btime[1:N_ELEMENTS(btime)-1] - btime[0:N_ELEMENTS(btime)-2]
        gap = FLOAT(ROUND(MIN(dt))) 
        idx = WHERE(dt GT 600., ndat)
        IF ndat GT 0 THEN BEGIN
           btime = [btime, btime[idx] + gap/2.d0]
           bdata = [bdata, REPLICATE(nan, ndat)]
           idx = SORT(btime)
           btime = btime[idx]
           bdata = bdata[idx]
        ENDIF 
        undefine, idx, ndat, dt
        ; Backward survey
        dt = ABS((REVERSE(btime))[1:N_ELEMENTS(btime)-1] - (REVERSE(btime))[0:N_ELEMENTS(btime)-2])
        idx = WHERE(dt GT 600., ndat)
        IF ndat GT 0 THEN BEGIN
           btime = [btime, (REVERSE(btime))[idx] - gap/2.d0]
           bdata = [bdata, REPLICATE(nan, ndat)]
           idx = SORT(btime)
           btime = btime[idx]
           bdata = bdata[idx]
        ENDIF 
        undefine, idx, ndat, dt
     ENDIF ELSE BEGIN
        btime = trange
        bdata = [nan, nan]
     ENDELSE 
     store_data, 'burst_flag', data={x: btime, y: [ [bdata], [bdata] ], v: [0, 1]}, $
                 dlim={ytitle: 'BST', yticks: 1, yminor: 1, ytickname: [' ', ' '], spec: 1, $
                       no_color_scale: 1, panel_size: 0.2, xticklen: 0.5}
;     IF status EQ 1 THEN tdegap, 'mvn_arcflag', /overwrite, dt=600.0
     options, 'burst_flag', bottom=0, top=6 
     zlim, 'burst_flag', 0, 1, /def
  ENDIF 
  
  tplot_options, opt=topt 
  IF keyword_set(tplot) THEN BEGIN
     IF SIZE(ptname, /type) EQ 0 THEN $
        ptname = ['mvn_sep1_B-O_Eflux_Energy', 'mvn_sep2_B-O_Eflux_Energy', $
                  'mvn_sta_c0_e', 'mvn_sta_c6_m', 'mvn_swis_en_eflux', $
                  'mvn_swe_etspec', 'mvn_mag_bamp', bvec, 'alt2']

     IF keyword_set(bbar) THEN ptname = [ptname, 'burst_flag'] 
     tplot, ptname, wi=wnum 
  ENDIF 
  RETURN
END
