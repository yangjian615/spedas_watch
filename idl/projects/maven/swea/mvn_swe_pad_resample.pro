;+
;PROCEDURE: 
;	MVN_SWE_PAD_RESAMPLE
;
;PURPOSE:
;	Resampling the pitch angle ditribution from SWEA PAD or 3D data.
;       Results are plotted or created as tplot variable.
;
;CALLING SEQUENCE: 
;	mvn_swe_pad_resample, nbins=128., erange=[100., 150.]
;
;INPUTS: 
;   none - PAD or 3D data are obtained from SWEA common block.
;   If you set the time interval, then the snapshot of the pitch
;   angle distribution at the specified time is plotted.
;   (Noted that it might take more than 10 minutes to resample pitch
;   angle distributions if you use PAD data for 1 day, depending on
;   your machine spec and data amount.)
;
;KEYWORDS:
;   SILENT:    Minimize to show the processing information in the terminal.
;   MASK:      Mask the expected angular bins whose field of view is
;              blocked by the spacecraft body and solar
;              paddles. Automatically identifying the mission phases
;              (cruise or science mapping).
;
;   STOW:      (A little bit obsolete keyword). Mask the angular bins
;              whose field of view is blocked during the cruise
;              phase. 
;
;   DDD:       Use 3D data to resample pitch angle distribution.
;
;   PAD:       Use PAD data to resample pitch angle distribution.
;              It is the default setting.
;
;   NBINS:     Specify resampling binning numbers. Default = 128.
;
;   ABINS:     Specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     Specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   ARCHIVE:   Use the archive data, instead of the survey data.
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   WINDOW:    Set the window number to show the snapshot. Default = 0.
;
;   RESULT:    Return the resampling pitch angle distribution data.
;
;   UNITS:     Set the units to prefer to use. Default = 'EFLUX'.
;
;   ERANGE:    Energy range over which to plot the pitch angle distribution.
;              For tplot case, default = 280 eV, based on the L0 tplot setting.
;
;   NORMAL:    If set, then normalize each pad spectrum to have an
;              average value of unity.
;
;   SNAP:      Explicitly set to plot the snapshot.
;
;   TPLOT:     Explicitly set to make a tplot variable.
;
;   MAP3D:     Take into account the pitch angle width even for 3D
;              data. This keyword only works 3D data. The mapping
;              method is based on 'mvn_swe_padmap'.
;
;CREATED BY: 
;	Takuya Hara
;
; $LastChangedBy: hara $
; $LastChangedDate: 2014-09-30 16:31:10 -0700 (Tue, 30 Sep 2014) $
; $LastChangedRevision: 15890 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pad_resample.pro $
;
;-
FUNCTION mvn_swe_pad_resample_map3d, var
  @mvn_swe_com
  ddd = var
  str_element, ddd, 'magf', success=ok
  
  IF (ok) THEN BEGIN
     magf = ddd.magf
     magf /= SQRT(TOTAL(magf*magf))
     
     group = ddd.group
     Baz = ATAN(magf[1], magf[0])
     IF Baz LT 0. THEN Baz += 2.*!DPI
     Bel = ASIN(magf[2])
     
     FOR jel=0, 5 DO BEGIN
        append_array, i, INDGEN(16)
        append_array, j, REPLICATE(jel, 16)
     ENDFOR 
     k = j*16 + i
     
     ddtor = !dpi/180D
     ddtors = REPLICATE(ddtor, 64)
     n = 17                     ; patch size - odd integer
     
     daz = DOUBLE((INDGEN(n*n) MOD n) - (n-1)/2)/DOUBLE(n-1) # DOUBLE(swe_daz[i])
     Saz = REFORM(REPLICATE(1D,n*n) # DOUBLE(swe_az[i]) + daz, n*n*96) # ddtors
     
     Sel = dblarr(n*n*96, 64)
     FOR m=0,63 DO BEGIN
        del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,m,group])
        Sel[*,m] = reform(replicate(1D,n*n) # double(swe_el[j,m,group]) + del, n*n*96)
     ENDFOR
     Sel = Sel*ddtor
     
     Saz = REFORM(Saz, n*n, 96, 64) ; nxn az-el patch, 96 pitch angle bins, 64 energies
     Sel = REFORM(Sel, n*n, 96, 64)
     pam = ACOS(COS(Saz - Baz)*COS(Sel)*COS(Bel) + SIN(Sel)*SIN(Bel))
     
     pa = TOTAL(pam, 1)/FLOAT(n*n) ; mean pitch angle
     pa_min = MIN(pam, dim=1)      ; minimum pitch angle
     pa_max = MAX(pam, dim=1)      ; maximum pitch angle
     dpa = pa_max - pa_min         ; pitch angle range
     
; Package the result
     
     pam = { pa     : FLOAT(pa)     , $ ; mean pitch angles (radians)
             dpa    : FLOAT(dpa)    , $ ; pitch angle widths (radians)
             pa_min : FLOAT(pa_min) , $ ; minimum pitch angle (radians)
             pa_max : FLOAT(pa_max) , $ ; maximum pitch angle (radians)
             iaz    : i             , $ ; anode bin (0-15)
             jel    : j             , $ ; deflector bin (0-5)
             k3d    : k             , $ ; 3D angle bin (0-95)
             Baz    : FLOAT(Baz)    , $ ; Baz in SWEA coord. (radians)
             Bel    : FLOAT(Bel)      } ; Bel in SWEA coord. (radians)
     
     str_element, ddd, 'pa', TRANSPOSE(FLOAT(pa)), /add
     str_element, ddd, 'dpa', TRANSPOSE(FLOAT(dpa)), /add
     str_element, ddd, 'pa_min', TRANSPOSE(FLOAT(pa_min)), /add
     str_element, ddd, 'pa_max', TRANSPOSE(FLOAT(pa_max)), /add
     str_element, ddd, 'iaz', i, /add
     str_element, ddd, 'jel', j, /add
     str_element, ddd, 'k3d', k, /add
     str_element, ddd, 'Baz', FLOAT(Baz), /add
     str_element, ddd, 'Bel', FLOAT(Bel), /add
  ENDIF ELSE pam = 0
  RETURN, ddd
END

PRO mvn_swe_pad_resample, var, silent=silent, mask=mask, stow=stow, ddd=ddd, pad=pad,  $
                          nbins=nbins, abins=abins, dbins=dbins, archive=archive, $
                          pans=pans, window=wnum, result=result, $
                          units=units, erange=erange, normal=normal, _extra=extra, $
                          snap=plot, tplot=tplot, map3d=map3d
  COMPILE_OPT idl2
  @mvn_swe_com

  nan = !values.f_nan 
  ;; fifb = fifteenb()
  fifb = string("15b) ;"

  IF SIZE(mvn_swe_engy, /type) NE 8 THEN BEGIN
     print, ptrace()
     print, '  No SWEA data loaded.  Use mvn_swe_load_l0 first.'
     RETURN
  ENDIF 
  IF SIZE(swe_mag1, /type) NE 8 THEN BEGIN
     print, ptrace()
     print, '  No MAG1 data loaded.  Use swe_getmag_ql first.'
     RETURN
  ENDIF 

  IF keyword_set(ddd) THEN dtype = 1
  IF keyword_set(pad) THEN dtype = 0
  IF SIZE(dtype, /type) EQ 0 THEN dtype = 0

  IF NOT keyword_set(dtype) THEN BEGIN
     IF NOT keyword_set(archive) THEN dat = a2 ELSE dat = a3
     IF SIZE(dat, /type) NE 8 THEN BEGIN
        PRINT, ptrace()
        IF keyword_set(archive) THEN BEGIN
           PRINT, '  No PAD archive data. Instead, PAD survey data is used.'
           dat = a2
           archive = 0
        ENDIF
     ENDIF  
  ENDIF ELSE BEGIN
     IF NOT keyword_set(archive) THEN dat = swe_3d ELSE dat = swe_3d_arc
     IF SIZE(dat, /type) NE 8 THEN BEGIN
        PRINT, ptrace()
        IF keyword_set(archive) THEN BEGIN
           PRINT, '  No 3D archive data. Instead, 3D survey data is used'
           dat = swe_3d
           archive = 0
        ENDIF 
     ENDIF   
  ENDELSE

  IF SIZE(var, /type) NE 0 THEN BEGIN
     trange = var
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
     IF SIZE(plot, /type) EQ 0 THEN plot = 1
     CASE N_ELEMENTS(trange) OF
        1: BEGIN
           ndat = 1
           idx = nn(dat.time, trange)
        END 
        2: BEGIN
           idx = WHERE(dat.time GE MIN(trange) AND dat.time LE MAX(trange), ndat)
           IF ndat EQ 0 THEN BEGIN
              PRINT, ptrace()
              PRINT, '  No data during the specified time you set.'
              RETURN
           ENDIF 
        END 
        ELSE: BEGIN
           PRINT, ptrace()
           PRINT, '  You must input 1 or 2 element(s) of the time interval.'
           RETURN
        END 
     ENDCASE 
  ENDIF ELSE BEGIN
     trange = minmax(dat.time)
     ndat = N_ELEMENTS(dat)
     idx = INDGEN(ndat)

     IF SIZE(tplot, /type) EQ 0 THEN tplot = 1
  ENDELSE 

  IF NOT keyword_set(units) THEN units = 'eflux'
  IF NOT keyword_set(nbins) THEN nbins = 128.
  IF NOT keyword_set(wnum) THEN wnum = 0
  IF NOT keyword_set(erange) AND keyword_set(tplot) THEN erange = 280.

  IF NOT keyword_set(abins) THEN abins = REPLICATE(1., 16)
  IF NOT keyword_set(dbins) THEN dbins = REPLICATE(1., 6)
  obins = REFORM(abins # dbins, 96)
  IF keyword_set(mask) THEN BEGIN
     IF MAX(trange) LT t_mtx[2] THEN stow = 1

     IF keyword_set(stow) THEN BEGIN
        mdbins = [0., 0., 0., 1., 1., 1.]
        mabins = REPLICATE(1., 16)
     ENDIF ELSE BEGIN
        ;; Need to modify.
     ENDELSE 
     
     mobins = REFORM(mabins # mdbins, 96)
  ENDIF ELSE mobins = REPLICATE(1., 96)
  obins *= mobins

  i = WHERE(obins EQ 0., cnt)
  IF cnt GT 0 THEN obins[i] = nan
  undefine, i, cnt

  plim = {noiso: 1, zlog: 1, charsize: 1.3, xticks: 6, xminor: 3, xrange: [0., 180.], ylog: 1}
  start = SYSTIME(/sec)
  cet = 0.d0
  IF keyword_set(silent) THEN prt = 0 ELSE prt = 1
  FOR i=0L, ndat-1L DO BEGIN
     IF keyword_set(dtype) THEN BEGIN
        ddd = mvn_swe_get3d(dat[idx[i]].time, units=units, archive=archive)
        dname = ddd.data_name
        magf = ddd.magf
        magf /= SQRT(TOTAL(magf * magf))
        
        energy = average(ddd.energy, 2)
        ddd.data *= REBIN(TRANSPOSE(obins), ddd.nenergy, ddd.nbins)
        IF keyword_set(map3d) THEN $
           ddd = mvn_swe_pad_resample_map3d(ddd)
     ENDIF ELSE BEGIN
        pad = mvn_swe_getpad(dat[idx[i]].time, units=units, archive=archive)
        dname = pad.data_name
        energy = average(pad.energy, 2)
        pad.data *= REBIN(TRANSPOSE(obins[pad.k3d]), pad.nenergy, pad.nbins)
     ENDELSE 
        
     IF keyword_set(erange) THEN BEGIN
        CASE N_ELEMENTS(erange) OF
           1: BEGIN
              nene = 1
              edx = NN(energy, erange)
           END 
           2: BEGIN
              edx = WHERE(energy GE MIN(erange) AND energy LE MAX(erange), nene)
              IF nene EQ 0 THEN BEGIN
                 PRINT, ptrace()
                 PRINT, '  There is no energy step in the energy range you set.'
                 RETURN
              ENDIF
           END 
           ELSE: BEGIN
              PRINT, ptrace()
              PRINT, '  You must input 1 or 2 element(s) of energy range.'
              RETURN
           END 
        ENDCASE 
     ENDIF ELSE BEGIN
        IF keyword_set(ddd) THEN nene = ddd.nenergy ELSE nene = pad.nenergy
        edx = INDGEN(nene)
     ENDELSE 

     IF i EQ 0L THEN BEGIN
        t0 = SYSTIME(/sec)
        dformat = {time: 0.d0, xax: FLTARR(nbins), $
                   index: FLTARR(nene, nbins), $
                   avg: FLTARR(nene, nbins), $
                   std: FLTARR(nene, nbins), $
                   nbins: FLTARR(nene, nbins)}
        
        result = REPLICATE(dformat, ndat)
        dt = SYSTIME(/sec) - t0
        undefine, t0
     ENDIF 

     pa = dformat
     IF keyword_set(map3d) THEN BEGIN
        pad = ddd
        GOTO, pad_resample
     ENDIF 
     IF keyword_set(dtype) THEN BEGIN
        angle = FLTARR(nene, ddd.nbins)
        FOR j=0, nene-1 DO FOR k=0, ddd.nbins-1 DO BEGIN
           vec = [COS(ddd.theta[edx[j], k]*!DTOR) * COS(ddd.phi[edx[j], k]*!DTOR), $
                  COS(ddd.theta[edx[j], k]*!DTOR) * SIN(ddd.phi[edx[j], k]*!DTOR), $
                  SIN(ddd.theta[edx[j], k]*!DTOR) ]
           angle[j, k] = ACOS(magf ## TRANSPOSE(vec)) * !RADEG
           undefine, vec
        ENDFOR 
        undefine, j, k
        
        pa.time = ddd.time
        ; Resampling 
        FOR j=0, nene-1 DO BEGIN
           k = WHERE(FINITE(ddd.data[edx[j], *]))
           bin1d, REFORM(angle[j, k]), REFORM(ddd.data[edx[j], k]), 0., 180., (180./nbins), kinbin, xax, avg, std
           pa.avg[j, *] = avg
           pa.std[j, *] = std
           pa.nbins[j, *] = kinbin
           undefine, kinbin, avg, std, k
        ENDFOR 
        undefine, j

        data = pa.avg
        data[*] = 0.d
     
        pa.index = 0.
        FOR j=0, nene-1 DO BEGIN
           jdx = WHERE(pa.nbins[j, *] GT 0, cnt)
           IF cnt GT 0 THEN BEGIN
              data[j, MIN(jdx):MAX(jdx)] = INTERPOL(REFORM(pa.avg[j, jdx]), xax[jdx], xax[MIN(jdx):MAX(jdx)])
              pa.index[j, MIN(jdx):MAX(jdx)] = 1.
           ENDIF 
           undefine, jdx, cnt
           jdx = WHERE(data[j, *] LT 0., cnt)
           IF cnt GT 0 THEN data[j, jdx] = 0.
           undefine, jdx, cnt
        ENDFOR 
        undefine, j
        pa.avg = data
        pa.xax = xax
     ENDIF ELSE BEGIN
        pad_resample:
        pa.time = pad.time
        xax = (0.5*(180./nbins) + FINDGEN(nbins) * (180./nbins)) * !DTOR
        tot = DBLARR(nbins)
        index = tot
        ; Resampling
        FOR j=0, nene-1 DO BEGIN
           FOR k=0, pad.nbins-1 DO BEGIN
              l = WHERE(~FINITE(pad.data[edx[j], k]), cnt)
              IF cnt EQ 0 THEN BEGIN
                 l = WHERE(xax GE pad.pa[edx[j], k] - (pad.dpa[edx[j], k]/2.) AND $
                           xax LE pad.pa[edx[j], k] + (pad.dpa[edx[j], k]/2.), cnt)
                 IF cnt GT 0 THEN BEGIN
                    tot[l] = tot[l] + pad.data[edx[j], k]
                    index[l] = index[l] + 1.
                 ENDIF 
              ENDIF 
              undefine, l, cnt
           ENDFOR 
           undefine, k
           pa.avg[j, *] = tot / index
           pa.nbins[j, *] = index
           k = WHERE(index LE 0., cnt)

           pa.index[j, *] = LONG(index / index)
           IF cnt GT 0 THEN pa.index[j, k] = 0
           undefine, k, cnt
        ENDFOR  
        pa.xax = xax * !RADEG
        undefine, tot, index
     ENDELSE  
     result[i] = pa
     undefine, pa, data, xax
     undefine, ddd, pad, magf

     IF ndat GT 1 THEN BEGIN
        IF keyword_set(silent) THEN BEGIN
           IF i GT 0L THEN IF SYSTIME(/sec)-start GT cet THEN BEGIN
              prt = 1
              cet += dcet
           ENDIF 
        ENDIF
        IF i EQ ndat-1L THEN prt = 1
        IF i EQ 0L THEN BEGIN
           dcet = ((SYSTIME(/sec)-start-dt)*DOUBLE(ndat-1L))/5.
           cet = +dcet
           print, ptrace()
           print, '  Resampling Start (Expected time needed to complete: ' + $
                  STRING(5.*dcet, '(f0.1)') + ' sec).'
        ENDIF ELSE BEGIN
           IF prt EQ 1 THEN $
              print, format='(a, a, a, f6.2, a, f5.1, a, $)', $
                     '      ', fifb, '  Resampling pitch angle distribution from ' + $
                     dname + ' data is ', FLOAT(i)/FLOAT(ndat-1L)*100., ' % complete (Elapsed time: ', $
                     SYSTIME(/sec)-start, ' sec).' 
        ENDELSE 
        IF keyword_set(silent) THEN prt = 0
     ENDIF  
  ENDFOR
  undefine, i
  IF ndat GT 1 THEN PRINT, ' '

  CASE units OF
     'counts': ztit = 'Counts / Samples'
     'crate' : ztit = 'CRATE'
     'eflux' : ztit = 'EFLUX'
     'flux'  : ztit = 'FLUX'
     'df'    : ztit = 'Distribution Function'
     ELSE    : ztit = 'Unknown Units' 
  ENDCASE 
  IF keyword_set(normal) THEN $
     ztit = 'Normalized ' + ztit

  IF keyword_set(plot) THEN BEGIN
     tit = dname + '!C' + time_string(MIN(result.time))
     IF ndat GT 1 THEN BEGIN
        tit += ' - ' + time_string(MAX(result.time))
        zdata = TRANSPOSE(TOTAL(result.avg, 3, /nan) / TOTAL(result.index, 3, /nan)) 
        xax = average(result.xax, 2)
        
        index = TRANSPOSE(TOTAL(result.index, 3, /nan))
        i = WHERE(index GE 1, cnt)
        IF cnt GT 0 THEN index[i] = 1
        undefine, i, cnt
     ENDIF ELSE BEGIN
        zdata = TRANSPOSE(result.avg / result.index)
        xax = result.xax
        
        index = TRANSPOSE(result.index)
     ENDELSE 

     IF keyword_set(normal) THEN BEGIN
        zdata /= REBIN(TRANSPOSE(average(zdata, 1, /nan)), nbins, nene)
        
        i = WHERE(index EQ 0, cnt)
        IF cnt GT 0 THEN zdata[i] = nan
        undefine, i, cnt

        str_element, plim, 'zrange', [0.1, 10.], /add        
     ENDIF

     plotxyz, xax, energy[edx], zdata, wi=wnum, _extra=plim, $
              xtit='Pitch Angle [deg]', ytit='Energy [eV]', ztit=ztit, $
              yrange=minmax(energy), title=tit
  ENDIF 

  IF keyword_set(tplot) THEN BEGIN
     ytit = 'SWE PAD!C('
     IF nene EQ 1 THEN ytit += STRING(energy[edx[0]], '(f0.1)') + ' eV)' $
     ELSE ytit += STRING(MIN(energy[edx]), '(f0.1)') + ' - ' + STRING(MAX(energy[edx]), '(f0.1)') + ' eV)' 

     data = TRANSPOSE(average(result.avg, 1, /nan))
     IF keyword_set(normal) THEN BEGIN
        data /= REBIN(average(data, 2, /nan), ndat, nbins)
        index = TRANSPOSE(average(result.index, 1))
        index[WHERE(index EQ 0.)] = nan
        index[WHERE(FINITE(index))] = 1.
        data *= index
        zrange = [0.5, 1.5]
        zlog = 0
     ENDIF ELSE BEGIN
        zlog = 1

        davg = MEAN(ALOG10(data[WHERE(data GT 0.)]))
        dstd = STDDEV(ALOG10(data[WHERE(data GT 0.)]))

        zrange = [10.^(davg - dstd*2.), 10.^(davg + dstd*2.)]
     ENDELSE 

     IF NOT keyword_set(pans) THEN pans = 'mvn_swe_pad_resample'
     store_data, pans, $
                 data={x: result.time, y: data, v: TRANSPOSE(result.xax)}, $
                 dlim={spec: 1, yrange: [0., 180.], ystyle: 1, yticks: 6, yminor: 3, $
                       ytitle: ytit, ysubtitle: '[deg]', ztitle: ztit, zlog: zlog, zrange: zrange}
  ENDIF 
  RETURN
END
