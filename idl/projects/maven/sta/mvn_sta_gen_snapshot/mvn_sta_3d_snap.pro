;+
;
;PROCEDURE:       MVN_STA_3D_SNAP
;
;PURPOSE:         Plots 3D (angular) snapshots in a separate window
;                 for times selected with the cursor in a tplot window.
;                 Hold down the left mouse button and slide for a movie effect.
;                 This version uses 'plot3d' (or 'spec3d') on packaged 3D data.
;
;INPUTS:          None. 
;                 But the specified time (or [tmin, tmax]) is set, it
;                 automatically show the snapshot. In this case, the
;                 cursor does not appear in a tplot window. 
;
;KEYWORDS:
;
;   EBINS:        Energy bins to plot (passed to plot3d). 
;                 Default = ddd.nenergy.
;
;   CENTER:       Longitude and latitude of the center [lon, lat].
;
;   MAP:          Mapping projection. See 'plot3d_options' for details.
;
;   SPEC:         Plots energy spectra using 'spec3d'.
;                 (Not working yet.)
;
;   UNITS:        Units for the 'spec3d'.
;                 (Not working yet.)
;
;   ENERGY:       One or more energies to plot.  Overrides "EBINS".
;
;   DDD:          Named variable to hold a 3D structure including mass
;                 at the last time selected.
;
;   SUM:          If set, use cursor to specify time ranges for averaging.
;
;   SMO:          Sets smoothing in energy and angle.  Since there are only
;                 4 theta bins depending APIDs, smoothing in that dimension is not recommended.
;
;                 smo = [n_energy, n_phi, n_theta]  ; default = [1,1,1]
;
;                 This routine takes into account the 360-0 degree wrap when 
;                 smoothing (But not working yet).
;
;   SUNDIR:       Plots the direction of the Sun in STATIC coordinates.
;                 (Not working yet.)
;
;   LABEL:        If set, label the 3D angle bins.
;
;   KEEPWINS:     If set, then don't close the snapshot window(s) on exit.
;
;   ARCHIVE:      If set, show snapshots of archive data.
;
;   BURST:        Synonym for "ARCHIVE".
;
;   MASK_SC:      Masks solid angle bins that are blocked by the spacecraft.
;                 (Not working yet.)
;
;   MASS:         Selects ion mass/charge range to show. Default is all.
;
;   MMIN:         Defines the minimum ion mass/charge to use.
; 
;   MMAX:         Defines the maximum ion mass/charge to use.
;
;   M_INT:        Assumes ion mass/charge. Default = 1.
;
;   ERANGE:       If set, plots energy ranges for averaging.
;
;   WINDOW:       Sets the window number to show. Default = 0.
;
;   MSODIR:       Plots the direction of the MSO axes in STATIC coordinates. 
;
;   APPDIR:       Plots the direction of the APP boom in STATIC coordinates.  
;
;   APID:         If set, specifies the APID data product to use. 
;
;   PLOT_SC:      Overplots the projection of the spacecraft body.
;
;   SWIA:         Overplots the SWIA FOV in STATIC coordidates in
;                 order to make sure the FOV overlap each other.
;
;   ZLOG:         Sets a logarithmic color bar scaling. 
;
;NOTE:            This routine is written based on partially 'swe_3d_snap'
;                 created by Dave Mitchell.
;
;USAGE EXAMPLES: 
;                 1.
;                 mvn_sta_3d_snap, erange=[0.1, 1.d4], wi=1, /mso, /app, /label, /plot_sc
;
;                 2.
;                 ctime, t ; Clicks once or twice on the tplot window.
;                 mvn_sta_3d_snap, t, erange=[0.1, 1.d4], wi=1, /mso, /app, /label, /plot_sc
;
;                 3.
;                 ctime, routine='mvn_sta_3d_snap'
;
;CREATED BY:      Takuya Hara on  2015-02-11.
;
; $LastChangedBy: hara $
; $LastChangedDate: 2015-03-25 02:55:34 -0700 (Wed, 25 Mar 2015) $
; $LastChangedRevision: 17182 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_3d_snap.pro $
;
;-
PRO mvn_sta_3d_snap, var1, var2, spec=spec, keepwins=keepwins, archive=archive, ebins=ebins,  $
                     center=center, units=units, ddd=ddd, sum=sum, energy=energy, $
                     label=label, smo=smo, sundir=sundir, map=map, $
                     abins=abins, dbins=dbins, obins=obins, mask_sc=mask_sc, burst=burst, $
                     mass=mass, m_int=mq, erange=erange, window=window, msodir=mso, apid=id, $
                     appdir=app, mmin=mmin, mmax=mmax, plot_sc=plot_sc, swia=swia, $
                     _extra=extra, $ ; for 'plot3d_new' options.
                     zlog=zlog

  COMMON mvn_c6
  tplot_options, get_option=topt
  IF SIZE(var1, /type) NE 0 AND SIZE(var2, /type) EQ 0 THEN var2 = var1
  IF SIZE(var2, /type) NE 0 THEN BEGIN
     trange = time_double(var2)
     IF SIZE(window, /type) EQ 0 THEN $
        IF !d.window EQ topt.window THEN window = !d.window + 1 ELSE window = !d.window
     IF SIZE(mso, /type) EQ 0 THEN mso = 1
     IF SIZE(app, /type) EQ 0 THEN app = 1
     IF SIZE(label, /type) EQ 0 THEN label = 1
  ENDIF 
  IF keyword_set(archive) THEN aflg = 1 ELSE aflg = 0
  IF keyword_set(burst) THEN aflg = 1

;  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
;  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
;  if (n_elements(obins) ne 96) then begin
;    obins = replicate(1B, 96, 2)
;    obins[*,0] = reform(abins # dbins, 96)
;    obins[*,1] = obins[*,0]
;  endif else obins = byte(obins # [1B,1B])
;  if (size(mask_sc,/type) eq 0) then mask_sc = 1
;  if keyword_set(mask_sc) then obins = swe_sc_mask * obins

;  omask = replicate(1.,96,2)
;  indx = where(obins eq 0B, count)
;  if (count gt 0L) then omask[indx] = !values.f_nan
;  omask = reform(replicate(1.,64) # reform(omask, 96*2), 64, 96, 2)

  IF (SIZE(units, /type) NE 7) THEN units = 'crate'
  IF (SIZE(map, /type) NE 7) THEN map = 'ait'
  IF keyword_set(mass) THEN mmin = MIN(mass, max=mmax)
  IF keyword_set(mmin) AND ~keyword_set(mmax) THEN mtit = STRING(mmin, '(F0.1)') + ' < m/q'
  IF keyword_set(mmax) AND ~keyword_set(mmin) THEN mtit = 'm/q < ' + STRING(mmax, '(F0.1)')
  IF keyword_set(mmin) AND  keyword_set(mmax) THEN mtit = STRING(mmin, '(F0.1)') + ' < m/q < ' + STRING(mmax, '(F0.1)')
  IF SIZE(mtit, /type) EQ 0 THEN mtit = 'm/q = all'
  plot3d_options, map=map
  
  case strupcase(units) of
    'COUNTS' : yrange = [1.,1.e5]
    'RATE'   : yrange = [1.,1.e5]
    'CRATE'  : yrange = [1.,1.e6]
    'FLUX'   : yrange = [1.,1.e8]
    'EFLUX'  : yrange = [1.e4,1.e9]
    'DF'     : yrange = [1.e-19,1.e-8]
    else     : yrange = [0.,0.]
  endcase

  case n_elements(center) of
    0 : begin
          lon = 180.
          lat = 0.
        end
    1 : begin
          lon = center[0]
          lat = 0.
        end
    else : begin
             lon = center[0]
             lat = center[1]
           end
  endcase

  if keyword_set(spec) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1

  if (n_elements(smo) gt 0) then begin
    nsmo = [1,1,1]
    for i=0,(n_elements(smo)-1) do nsmo[i] = round(smo[i])
    dosmo = 1
  endif else dosmo = 0

  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse

; Put up snapshot window(s)
  IF keyword_set(window) THEN wnum = window ELSE wnum = !d.window 
  wi, wnum, wsize=[800, 600]

; Select the first time, then get the 3D spectrum closest that time
  IF SIZE(var1, /type) EQ 0 THEN print,'Use button 1 to select time; button 3 to quit.'

  wset, wnum
  IF SIZE(var2, /type) EQ 0 THEN ctime2, trange, npoints=npts, /silent, button=button

  if (size(trange,/type) eq 2) then begin ; Abort before first time select.
     if (sflg) then wdelete, wnum+1
     wset, wnum
     return
  endif
  
  ok = 1
  IF ~keyword_set(id) THEN BEGIN
     mode = mvn_c6_dat.mode
     mtime = mvn_c6_dat.time
  ENDIF 
  func = 'mvn_sta_get'
  IF ~keyword_set(mmin) THEN mmin = 0
  IF ~keyword_set(mmax) THEN mmin = 100.

  init_swi = 1
  while (ok) do begin

; Put up a 3D spectrogram
 
     wset, wnum
     IF ~keyword_set(id) THEN BEGIN
        idx = nn(mtime, trange)
        emode = mode[idx]
        emode = emode[uniq(emode)]
        IF N_ELEMENTS(emode) EQ 1 THEN BEGIN
           CASE emode OF
              1: IF (aflg) THEN apid = 'cd' ELSE apid = 'cc'
              2: IF (aflg) THEN apid = 'cf' ELSE apid = 'ce'
              3: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
              5: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
              6: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
              ELSE: apid = 'ca'
           ENDCASE 
        ENDIF ELSE BEGIN
           dprint, 'The selected time interval includes multiple APID modes.'
           apid = 'ca'
        ENDELSE 
        undefine, idx, emode
     ENDIF ELSE apid = id 
     
     IF keyword_set(sum) THEN ddd = mvn_sta_get(apid, tt=trange) $
     ELSE ddd = CALL_FUNCTION(func + '_' + apid, trange)
     
     IF ddd.valid EQ 1 THEN BEGIN
        IF keyword_set(mass) THEN BEGIN
           idx = where(ddd.mass_arr LT mass[0] OR ddd.mass_arr GT mass[1], nidx)
           IF nidx GT 0 THEN ddd.data[idx] = 0.
           IF keyword_set(mq) THEN ddd.mass *= FLOAT(mq)
        ENDIF 
        ddd = conv_units(ddd, units)
        ddd = sum4m(ddd)
        IF SIZE(var2, /type) NE 0 THEN IF SIZE(erange, /type) EQ 0 THEN erange = minmax(ddd.energy)
        if (size(ddd,/type) eq 8) then begin
           data = ddd.data
           
           if keyword_set(energy) then begin
              n_e = n_elements(energy)
              ebins = intarr(n_e)
              for k=0,(n_e-1) do begin
                 de = min(abs(ddd.energy[*,0] - energy[k]), j)
                 ebins[k] = j
              endfor
           endif
           IF keyword_set(erange) THEN BEGIN
              idx = where(ddd.energy[*, 0] GE erange[0] AND ddd.energy[*, 0] LE erange[1], nidx)
              IF nidx GT 0 THEN BEGIN
                 ebins = idx[0]
                 sebins = nidx
              ENDIF ELSE RETURN
           ENDIF ELSE sebins = 1
           if (size(ebins, /type) eq 0) then ebins = reverse(indgen(ddd.nenergy))
           nbins = float(n_elements(ebins))
           
;      if (dosmo) then begin
;        ddat = reform(data*omask[*,*,boom],64,16,6)
;        dat = fltarr(64,32,6)
;        dat[*,8:23,*] = ddat
;        dat[*,0:7,*] = ddat[*,8:15,*]
;        dat[*,24:31,*] = ddat[*,0:7,*]
;        dats = smooth(dat,nsmo,/nan)
;        ddd.data = reform(dats[*,8:23,*],64,96)
;      endif else ddd.data = ddd.data*omask[*,*,boom]
      
           plot3d_new, ddd, lat, lon, ebins=ebins, sum_ebins=sebins, $
                       _extra=extra, log=zlog
           lab2 = ''
           IF keyword_set(mso) THEN BEGIN
              vec = [ [1., 0., 0.], [0., 1., 0.], [0., 0., 1.] ]
              IF TOTAL(ddd.quat_mso) EQ 0. THEN $
                 FOR i=0, 2 DO append_array, vmso, TRANSPOSE(spice_vector_rotate(vec[*, i], MEAN(trange), 'MAVEN_MSO', 'MAVEN_STATIC', verbose=-1)) $
              ELSE FOR i=0, 2 DO append_array, vmso, TRANSPOSE(quaternion_rotation(vec[*, i], qinv(ddd.quat_mso), /last_ind))
              xyz_to_polar, vmso, theta=tmso, phi=pmso, /ph_0_360
              plots, pmso, tmso, psym=1, color=[2, 4, 6], thick=2, symsize=1.5
              plots, pmso+180., -tmso, psym=4, color=[2, 4, 6], thick=2, symsize=1.5
              undefine, vec, vmso, tmso, pmso 
              lab2 += ' Xmso (b) Ymso (g) Zmso (r) '
           ENDIF 
           IF keyword_set(app) THEN BEGIN
              IF TOTAL(ddd.quat_sc) EQ 0. THEN $
                 xsc = TRANSPOSE(spice_vector_rotate([1., 0., 0.], MEAN(trange), 'MAVEN_SPACECRAFT', 'MAVEN_STATIC', verbose=-1)) $
              ELSE xsc = TRANSPOSE(quaternion_rotation([1., 0., 0.], qinv(ddd.quat_sc), /last_ind))
              xyz_to_polar, xsc, theta=tsc, phi=psc, /ph_0_360
              plots, psc, tsc, psym=7, color=1, thick=2, symsize=1.5
              undefine, xsc, tsc, psc 
              lab2 += 'APP (m) '
           ENDIF 
           IF keyword_set(plot_sc) THEN $
              mvn_spc_fov_blockage, trange=MEAN(trange), /static, clr=1, /invert_phi, /invert_theta
           
           if keyword_set(label) then begin
              lab=strcompress(indgen(ddd.nbins),/rem)
              xyouts,reform(ddd.phi[ddd.nenergy-1,*]),reform(ddd.theta[ddd.nenergy-1, *]),lab,align=.5
              xyouts, !x.window[1], !y.window[0]*1.2, lab2, charsize=!p.charsize, /normal, color=255, align=1.
              xyouts, !x.window[1], !y.window[1]-!y.window[0]*0.5, '(+: Plus / -: Diamond) ', charsize=!p.charsize, /normal, color=255, align=1.
           endif

           XYOUTS, !x.window[0]*1.2, !y.window[0]*1.2, mtit, charsize=!p.charsize, /normal, color=255

           IF keyword_set(swia) THEN BEGIN
              status = EXECUTE("swicom = SCOPE_VARNAME(common='mvn_swia_data')")
              IF status EQ 1 THEN BEGIN
                 IF (init_swi) THEN BEGIN
                    status = EXECUTE('COMMON mvn_swia_data')
                    init_swi = 0
                 ENDIF 
                 dcs = mvn_swia_get_3dc(MEAN(trange))

                 mk = spice_test('*')
                 idx = WHERE(mk NE '', count)
                 IF count EQ 0 THEN mk = mvn_spice_kernels(/load, /all, trange=trange, verbose=-1)
                 undefine, idx, count
                 mvn_pfp_cotrans, dcs, from='MAVEN_SWIA', to='MAVEN_STATIC', theta=tswi, phi=pswi, verbose=-1
                 ; Assuming that the color table is defined via 'loadct2'.
                 cswi = bytescale(dcs.phi, bottom=7, top=254, range=[0., 360.])
                 lswi = [0., 90., 180., 270., 360.]
                 clswi = bytescale(lswi, bottom=7, top=254, range=[0., 360.])
                 
                 idx = WHERE(dcs.theta[dcs.nenergy-1, *] GT 0., nidx, complement=jdx, ncomplement=njdx)
                 PLOTS, REFORM(pswi[dcs.nenergy-1, idx], nidx), REFORM(tswi[dcs.nenergy-1, idx], nidx), $
                        psym=6, color=REFORM(cswi[dcs.nenergy-1, idx], nidx)
                 PLOTS, REFORM(pswi[dcs.nenergy-1, jdx], njdx), REFORM(tswi[dcs.nenergy-1, jdx], njdx), $
                        psym=5, color=REFORM(cswi[dcs.nenergy-1, jdx], njdx)
                 undefine, dcs, tswi, pswi, cswi, idx, nidx, jdx, njdx

                 XYOUTS, !x.window[0]*1.2, !y.window[1]-!y.window[0]*0.5, '(SWIA, +: Square / -: Triangle)', charsize=!p.charsize, /normal, color=255
                 FOR i=0, N_ELEMENTS(lswi)-1 DO $
                    XYOUTS, !x.window[0]*1.2 + 0.04*i, !y.window[1]-!y.window[0]*1.1, STRING(lswi[i], '(I0)'), charsize=!p.charsize, /normal, color=clswi[i]
                 undefine, i, lswi, clswi 
              ENDIF ELSE dprint, 'No SWIA data loaded.'
              undefine, status, swicom
           ENDIF 
           
           if (sflg) then begin
              wset, wnum+1
              spec3d, ddd, units=units, limits={yrange:yrange, ystyle:1, ylog:1, psym:0}
           endif
        endif
        
; Get the next button press
    ENDIF ELSE dprint, 'Click again.'
     wset, wnum
     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        ctime2,trange,npoints=npts,/silent,button=button
        if (size(trange,/type) eq 5) then ok = 1 else ok = 0
     ENDIF ELSE ok = 0
  endwhile 
  
  if (kflg) then begin
     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        wdelete, wnum
        if (sflg) then wdelete, wnum+1 
     ENDIF 
  endif
  RETURN
END 
