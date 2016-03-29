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
;
;   MASK:      Mask the expected angular bins whose field of view (FOV)
;              is blocked by the spacecraft body and solar
;              paddles. Automatically identifying the mission phases
;              (cruise or science mapping). Default = 1. 
;
;   NO_MASK:   If set, not masking the expected angular bins whose FOV is blocked.
;              This keyword is identical to mask = 0.
;
;   STOW:      (Obsolete). Mask the angular bins whose field of view
;              is blocked before the boom deploy. 
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
;   SWIA:      Resampling PAD in the plasma rest frame, assuming to
;              the charge nuetrality. Shifted velocity is taken from
;              the SWIA Course data. So this keyword only works after
;              loading (restoring) the SWIA data into the memory.  
;
;   MBINS:     Specify which angular (both anode and deflection) bins
;              to include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1, 96)
;
;   SC_POT:    Account for the spacecraft potential correction.
;              (Not completely activated yet)
;  
;   SYMDIR:    Instead of the observed magnetic field vector, use the
;              symmetry direction of the (strahl) electron distribution.
;              The symmetry direction is calculated via 'swe_3d_strahl_dir'.
;
;   INTERPOLATE: When you try to resample the pitch angle distribtion
;                in the plasma rest frame, it calculates non-zero
;                value to have the data evaluated (interpolated) at
;                the original energy steps. This keyword is associated
;                with 'convert_vframe'.
;
;   CUT:       Plot the pitch-angle-sorted 1d spectra for each energy step.
;              It is an optional plot.
;
;   SPEC:      Plot the pitch-angle-selected 1d energy spectra. 
;              In the default settings, 5 pitch angle bands are selected.
;                 - quasi-parallel (0-30 deg),
;                 - quasi-perpendicular (75-105 deg),
;                 - quasi-antiparallel (150-180 deg),
;                 - 2 obliquenesses (30-75, 105-150 deg).
;              It is also an optional plot.
;
;   PSTYLE:    It means "plot style". This keyword allows
;              specification which plots you want to show.
;              Each option is described as follows:
;              - 1: Plots the snapshot(, equivalent to the "snap" keyword.)
;              - 2: Generates the tplot variable(, equivalent to the "tplot" keyword.)
;              - 4: Plots the pitch-angle-sorted 1d spectra(, equivalent to the "cut" keyword.)
;              - 8: Plots the pitch-angle-selected 1d energy spectra(, equivalent to the "spec" keyword.)
;              Note that this keyword is set bitwise, so multiple
;              effects can be achieved by adding values together. For
;              example, to plot the snapshot (value 1) and to generate
;              the tplot variable (value 2), set the PSTYLE keyword to
;              1+2, or 3. This basic idea is same as that
;              [x][y][z]style keyword included in default PLOT options.
;
;CREATED BY:      Takuya Hara on 2014-09-24.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-03-28 17:09:22 -0700 (Mon, 28 Mar 2016) $
; $LastChangedRevision: 20611 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pad_resample.pro $
;
;-
FUNCTION mvn_swe_pad_resample_map3d, var, prf=prf
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
     
     k = indgen(96)
     i = k mod 16
     j = k / 16
     
     ddtor = !dpi/180D
     ddtors = REPLICATE(ddtor, 64)
     n = 17                     ; patch size - odd integer

     IF NOT keyword_set(prf) THEN BEGIN
        daz = DOUBLE((INDGEN(n*n) MOD n) - (n-1)/2)/DOUBLE(n-1) # DOUBLE(swe_daz[i])
        Saz = REFORM(REPLICATE(1D,n*n) # DOUBLE(swe_az[i]) + daz, n*n*96) # ddtors
     ENDIF ELSE BEGIN
        Saz = DBLARR(n*n*96, 64)
        daz = DOUBLE((INDGEN(n*n) MOD n) - (n-1)/2)/DOUBLE(n-1) # DOUBLE(swe_daz[i])
        ;; daz = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_daz[i])
        FOR m=0, 63 DO $
           Saz[*, m] = reform(replicate(1D,n*n) # double(REFORM(ddd.phi[m, *])) + daz, n*n*96)
        Saz *= ddtor
     ENDELSE 

     Sel = dblarr(n*n*96, 64)
     FOR m=0,63 DO BEGIN
        del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,m,group])
        IF NOT keyword_set(prf) THEN $
           Sel[*,m] = reform(replicate(1D,n*n) # double(swe_el[j,m,group]) + del, n*n*96) $
        ELSE Sel[*,m] = reform(replicate(1D,n*n) # double(REFORM(ddd.theta[m, *])) + del, n*n*96)
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

; Resampling PAD in the plasma rest frame.
FUNCTION mvn_swe_pad_resample_prf, var, type, archive=archive, silent=silent, energy=energy, $
                                   map3d=map3d, dformat=dformat, nbins=nbins, nene=nene, edx=edx
  nan = !values.f_nan
  swe = var
  dtype = type
  ;; energy = average(swe.energy, 2)
  result = dformat

  ;; swe = mvn_swe_3d_shift(swe, silent=silent, archive=archive, /swia)
  ;; IF (dtype EQ 1) AND (keyword_set(map3d)) THEN BEGIN
  ;;    swe = mvn_swe_pad_resample_map3d(swe, /prf)
  ;;    dtype = 0
  ;; ENDIF 
  IF (dtype EQ 1) AND (keyword_set(map3d)) THEN dtype = 0
  result.time = swe.time
  ;; xax = (0.5*(180./nbins) + FINDGEN(nbins) * (180./nbins))*!DTOR

  dx = (180./nbins) * !DTOR
  dy = MEAN(ALOG10(energy[0:swe.nenergy-2]) - ALOG10(energy[1:swe.nenergy-1]))

  xrange = [0., 180.] * !DTOR
  yrange = minmax(ALOG10(energy)) + (dy/2.)*[-1., 1.]
  IF NOT keyword_set(dtype) THEN BEGIN
     tot = DBLARR(nbins, swe.nenergy)
     tot[*] = 0.
     index = tot
     
     idx = WHERE(FINITE(swe.data), cnt)
     IF cnt GT 0 THEN BEGIN
        ; ! Causion ! 
        ; Energy order is from low to high through 'histbins2d'.
        hist = histbins2d(REFORM(swe.pa), REFORM(ALOG10(swe.energy)), xax, yax,    $
                          xrange=xrange, yrange=yrange, xbinsize=dx, ybinsize=dy, reverse=ri )
        undefine, cnt
        FOR i=0L, nbins*swe.nenergy-1L DO BEGIN
           it = ARRAY_INDICES(hist, i)
           IF ri[i] NE ri[i+1L] THEN BEGIN
              j = ARRAY_INDICES(swe.data, ri[ri[i]:ri[i+1L]-1L])
              
              npts = N_ELEMENTS(j[0, *])
              FOR k=0L, npts-1L DO BEGIN
                 idx = WHERE(FINITE(swe.data[j[0, k], j[1, k]]), cnt)
                 IF cnt GT 0 THEN BEGIN
                    undefine, cnt
                    l = WHERE(xax GE swe.pa_min[j[0, k], j[1, k]] AND $
                              xax LE swe.pa_max[j[0, k], j[1, k]], cnt)
                    IF cnt GT 0 THEN BEGIN
                       tot[l, it[1]] = tot[l, it[1]] + swe.data[j[0, k], j[1, k]]
                       index[l, it[1]] = index[l, it[1]] + 1.
                    ENDIF 
                    undefine, l
                 ENDIF 
                 undefine, idx, cnt
              ENDFOR 
              undefine, j, k, npts
           ENDIF 
           undefine, it
        ENDFOR
        undefine, i
     ENDIF ELSE tot[*] = nan
  ENDIF ELSE BEGIN
  ENDELSE 
  undefine, idx, cnt

  ; Energy order is from high to low.
  tot = TRANSPOSE(REVERSE(tot, 2))
  index = TRANSPOSE(REVERSE(index, 2))
  tot = tot[edx, *]
  index = index[edx, *]

  result.avg = tot / index
  result.nbins = index

  idx = WHERE(index LE 0., cnt)
  result.index = LONG(index / index)
  IF cnt GT 0 THEN result.index[idx] = 0
  
  result.xax = xax * !RADEG
  undefine, tot, index  
  RETURN, result
END
; Converts the data to the plasma rest frame.
FUNCTION mvn_swe_pad_resample_swia, var, archive=archive, silent=silent, $
                                    sc_pot=sc_pot, interpolate=interpolate
  COMPILE_OPT idl2
  @mvn_swe_com

  edat = var
  time = edat.time
  unit = edat[0].units_name
  idat = mvn_swia_get_3dc(time, archive=archive)
  ivel = v_3d(idat)             ; SWIA coordiate system

  IF time LT t_mtx[2] THEN fswe = 'MAVEN_SWEA_STOW' $
  ELSE fswe = 'MAVEN_SWEA'
  
  ;; Converting to the SWEA coordinate system. ;;
  vel = spice_vector_rotate(ivel, time, 'MAVEN_SWIA', fswe, $
                            check_objects='MAVEN_SPACECRAFT', verbose=1)
  ;IF NOT keyword_set(silent) THEN dprint, 'Shifted bulk velocity [km/s]: ', vel
  IF N_ELEMENTS(WHERE(~FINITE(vel))) EQ 3 THEN BEGIN
     dprint, 'Cannot convert the SWEA frame due to the lack of SPICE/Kernels.'
     vel = [0., 0., 0.]
     data = edat
  ENDIF ELSE $
     data = convert_vframe(edat, vel, sc_pot=sc_pot, interpolat=interpolate)

  mvn_swe_convert_units, data, unit
  RETURN, data
END
FUNCTION mvn_swe_pad_resample_cscale, data, mincol=mincol, maxcol=maxcol, mindat=mindat, maxdat=maxdat
  IF n_elements(mincol) EQ 0 THEN mincol = 0
  IF n_elements(maxcol) EQ 0 THEN maxcol = 255
  IF n_elements(mindat) EQ 0 THEN mindat = MIN(data, /nan)
  IF n_elements(maxdat) EQ 0 THEN maxdat = MAX(data, /nan)

  colrange = maxcol - mincol
  datrange = maxdat - mindat

  lodata = WHERE(data LT mindat, locount)
  hidata = WHERE(data GT maxdat, hicount)

  dat = data                    ; Copy data

  IF locount NE 0 THEN dat[lodata] = mindat
  IF hicount NE 0 THEN dat[hidata] = maxdat

  RETURN, (dat - mindat) * colrange/FLOAT(datrange) + mincol
END 
; Main routine
PRO mvn_swe_pad_resample, var, mask=mask, stow=stow, ddd=ddd, pad=pad,  $
                          nbins=nbins, abins=abins, dbins=dbins, archive=archive, $
                          pans=pans, window=wi, result=result, no_mask=no_mask, $
                          units=units, erange=erange, normal=normal, _extra=extra, $
                          snap=plot, tplot=tplot, map3d=map3d, swia=swia, $
                          mbins=mbins, sc_pot=sc_pot, symdir=symdir, interpolate=interpolate, $
                          cut=cut, spec=spec, pstyle=pstyle, silent=sil, verbose=vb, hires=hires, fbdata=fbdata
  COMPILE_OPT idl2
  @mvn_swe_com
  nan = !values.f_nan 

  fifb = string("15b) ;"
  IF keyword_set(sil) THEN silent = sil ELSE silent = 0
  IF keyword_set(vb) THEN verbose = vb ELSE verbose = 0
  verbose -= silent

  IF SIZE(mvn_swe_engy, /type) NE 8 THEN BEGIN
     print, ptrace()
     print, '  No SWEA data loaded.'
     RETURN
  ENDIF 
  IF SIZE(swe_mag1, /type) NE 8 THEN BEGIN
     print, ptrace()
     print, '  No MAG1 data loaded.  Use mvn_swe_addmag first.'
     RETURN
  ENDIF 

  IF keyword_set(ddd) OR keyword_set(map3d) THEN dtype = 1
  IF keyword_set(pad) THEN dtype = 0
  IF SIZE(dtype, /type) EQ 0 THEN dtype = 0

  IF NOT keyword_set(dtype) THEN BEGIN
     if keyword_set(archive) then begin
       if (size(a3,/type) eq 8) then dat_time = a3.time
       if (size(mvn_swe_pad_arc,/type) eq 8) then dat_time = mvn_swe_pad_arc.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No PAD archive data.'
         archive = 0
       endif
     endif
     if not keyword_set(archive) then begin
       if (size(a2,/type) eq 8) then dat_time = a2.time
       if (size(mvn_swe_pad,/type) eq 8) then dat_time = mvn_swe_pad.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No PAD survey data.  Nothing to resample.'
         return
       endif
     endif
  ENDIF ELSE BEGIN
     if keyword_set(archive) then begin
       if (size(swe_3d_arc,/type) eq 8) then dat_time = swe_3d_arc.time
       if (size(mvn_swe_3d_arc,/type) eq 8) then dat_time = mvn_swe_3d_arc.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No 3D archive data.'
         archive = 0
       endif
     endif
     if not keyword_set(archive) then begin
       if (size(swe_3d,/type) eq 8) then dat_time = swe_3d.time
       if (size(mvn_swe_3d,/type) eq 8) then dat_time = mvn_swe_3d.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No 3D survey data.  Nothing to resample.'
         return
       endif
     endif

     IF keyword_set(symdir) THEN BEGIN
        swe_3d_strahl_dir, result=strahl, archive=archive
        
        idx = NN(dat_time, strahl.time)
        magf = [ [COS(strahl.theta[idx]*!DTOR) * COS(strahl.phi[idx]*!DTOR)], $
                 [COS(strahl.theta[idx]*!DTOR) * SIN(strahl.phi[idx]*!DTOR)], $
                 [SIN(strahl.theta[idx]*!DTOR)] ]
        str_element, strahl, 'magf', magf, /add
        undefine, magf
     ENDIF 
  ENDELSE

  IF SIZE(var, /type) NE 0 THEN BEGIN
     trange = var
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
     IF SIZE(plot, /type) EQ 0 THEN plot = 1
     CASE N_ELEMENTS(trange) OF
        1: BEGIN
           ndat = 1
           idx = nn(dat_time, trange)
        END 
        2: BEGIN
           idx = WHERE(dat_time GE MIN(trange) AND dat_time LE MAX(trange), ndat)
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
     trange = minmax(dat_time)
     ndat = N_ELEMENTS(dat_time)
     idx = LINDGEN(ndat)

     IF SIZE(tplot, /type) EQ 0 THEN tplot = 1
  ENDELSE 
  IF keyword_set(swia) THEN mk = mvn_spice_kernels(/load, /all, trange=trange, verbose=verbose)
  IF NOT keyword_set(units) THEN units = 'eflux'
  IF NOT keyword_set(nbins) THEN nbins = 128.
  IF NOT keyword_set(wi) THEN wnum = 0 ELSE wnum = wi
  IF NOT keyword_set(erange) AND keyword_set(tplot) THEN erange = 280.
  IF (SIZE(mask, /type) EQ 0) AND (SIZE(no_mask, /type) EQ 0) THEN mask = 1
  IF keyword_set(no_mask) THEN mask = 0
  IF keyword_set(hires) THEN hflg = 1 ELSE hflg = 0
  IF SIZE(pstyle, /type) EQ 0 THEN BEGIN
     pstyle = 0
     IF keyword_set(plot) THEN IF plot GT 0 THEN pstyle += 1
     IF keyword_set(tplot) THEN IF tplot GT 0 THEN pstyle += 2
     IF keyword_set(cut) THEN IF cut GT 0 THEN pstyle += 4
     IF keyword_set(spec) THEN IF spec GT 0 THEN pstyle += 8
  ENDIF
  pflg = BYTARR(4)
  FOR i=0, 3 DO pflg[i] = (pstyle AND 2L^i)/2L^i

  IF NOT keyword_set(abins) THEN abins = REPLICATE(1., 16)
  IF NOT keyword_set(dbins) THEN dbins = REPLICATE(1., 6)
  obins = REFORM(abins # dbins, 96)
  i = WHERE(obins EQ 0., cnt)
  IF cnt GT 0 THEN obins[i] = nan
  undefine, i, cnt

  stow = INTARR(ndat)
  stow[*] = 0
  IF keyword_set(mask) THEN BEGIN
     mobins = FLTARR(96, 2)
     mobins[*, 1] = swe_sc_mask[*,0]  ; stowed boom
     mobins[*, 0] = swe_sc_mask[*,1]  ; deployed boom
     i = WHERE(dat_time[idx] LT t_mtx[2], cnt)
     IF cnt GT 0 THEN stow[i] = 1
     undefine, i, cnt
  ENDIF ELSE IF keyword_set(mbins) THEN BEGIN
     IF N_ELEMENTS(mbins) EQ 96 THEN mobins = mbins $
     ELSE BEGIN
        dprint, 'You should input 96 elements of array to mask.'
        mobins = REPLICATE(1., 96)
     ENDELSE 
  ENDIF ELSE mobins = REPLICATE(1., 96)
  i = WHERE(mobins EQ 0., cnt)
  IF cnt GT 0 THEN mobins[i] = nan
  undefine, i, cnt

  IF STRLOWCASE(!version.os_family) EQ 'windows' THEN chsz = 1. ELSE chsz = 1.3
  plim = {noiso: 1, zlog: 1, charsize: chsz, xticks: 6, xminor: 3, xrange: [0., 180.], ylog: 1}
  start = SYSTIME(/sec)
  cet = 0.d0
  IF keyword_set(silent) THEN prt = 0 ELSE prt = 1
  FOR i=0L, ndat-1L DO BEGIN
     IF keyword_set(dtype) THEN BEGIN
        ddd = mvn_swe_get3d(dat_time[idx[i]], units=units, archive=archive)
        if keyword_set(sc_pot) then begin
          pot = swe_sc_pot[nn(swe_sc_pot.time, ddd.time)].potential
          if (finite(pot)) then begin
            mvn_swe_convert_units, ddd, 'df'
            ddd.energy -= pot
            mvn_swe_convert_units, ddd, units
          endif
        endif
        dtime = ddd.time
        tabok = ddd.chksum eq 'CC'X
        energy = average(ddd.energy, 2)

        IF keyword_set(swia) THEN $
           ddd = mvn_swe_pad_resample_swia(ddd, archive=archive, interpolate=interpolate, $
                                           silent=silent, sc_pot=sc_pot)
        
        IF keyword_set(symdir) THEN $
           ddd.magf = strahl.magf[NN(strahl.time, ddd.time), *]
     
        dname = ddd.data_name
        magf = ddd.magf
        magf /= SQRT(TOTAL(magf * magf))
        
        ;; ddd.data *= REBIN(TRANSPOSE(obins), ddd.nenergy, ddd.nbins)
        ddd.data *= REBIN(TRANSPOSE(obins*mobins[*, stow[i]]), ddd.nenergy, ddd.nbins)
        IF keyword_set(map3d) THEN $
           ddd = mvn_swe_pad_resample_map3d(ddd, prf=interpolate)
     ENDIF ELSE BEGIN
        pad = mvn_swe_getpad(dat_time[idx[i]], units=units, archive=archive)
        IF (hflg) THEN pad = mvn_swe_padmap_32hz(pad, fbdata=fbdata, verbose=verbose)
        if keyword_set(sc_pot) then begin
          pot = swe_sc_pot[nn(swe_sc_pot.time, pad.time)].potential
          if (finite(pot)) then begin
            mvn_swe_convert_units, pad, 'df'
            pad.energy -= pot
            mvn_swe_convert_units, pad, units
          endif
        endif
        dtime = pad.time
        tabok = pad.chksum eq 'CC'X
        dname = pad.data_name
        energy = average(pad.energy, 2)
        ;; pad.data *= REBIN(TRANSPOSE(obins[pad.k3d]), pad.nenergy, pad.nbins)
        pad.data *= REBIN(TRANSPOSE(obins[pad.k3d]*mobins[pad.k3d, stow[i]]), pad.nenergy, pad.nbins)
        block = WHERE(~FINITE(obins[pad.k3d]*mobins[pad.k3d, stow[i]]), nblock)
        IF ((nblock GT 0) and prt) THEN BEGIN
           tblk = 'Removed anode bin(s) data due to the FOV blockage: ['
           FOR iblk=0, nblock-1 DO BEGIN
              tblk += STRING(block[iblk], '(I0)')
              IF iblk NE nblock-1 THEN tblk += ', '
           ENDFOR 
           tblk += ']'
           dprint, tblk, dlevel=2, verbose=3-silent
           undefine, iblk, tblk
        ENDIF 
        undefine, block, nblock
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

     IF (not tabok) THEN BEGIN
        pa.time  = dtime
        pa.xax   = !values.f_nan
        pa.index = !values.f_nan
        pa.avg   = !values.f_nan
        pa.std   = !values.f_nan
        pa.nbins = !values.f_nan
        GOTO, skip_spec
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
        ;; IF keyword_set(swia) THEN $
        IF NOT keyword_set(interpolate) AND keyword_set(swia) THEN $
           pa = mvn_swe_pad_resample_prf(pad, dtype, silent=silent, archive=archive, map3d=map3d, $
                                         nbins=nbins, nene=nene, edx=edx, dformat=dformat, energy=energy) $
        ELSE BEGIN
           pa.time = pad.time
           xax = (0.5*(180./nbins) + FINDGEN(nbins) * (180./nbins)) * !DTOR
           ; Resampling
           FOR j=0, nene-1 DO BEGIN
              tot = DBLARR(nbins)
              variance = tot
              index = tot
              FOR k=0, pad.nbins-1 DO BEGIN
                 l = WHERE(~FINITE(pad.data[edx[j], k]), cnt)
                 IF cnt EQ 0 THEN BEGIN
                    l = WHERE((xax GE pad.pa_min[edx[j],k]) AND (xax LE pad.pa_max[edx[j],k]), cnt)
                    IF cnt GT 0 THEN BEGIN
                       tot[l] += pad.data[edx[j], k]
                       variance[l] += pad.var[edx[j], k]
                       index[l] += 1.
                    ENDIF 
                 ENDIF 
                 undefine, l, cnt
              ENDFOR 
              undefine, k

              pa.avg[j,*] = tot/index            ; average signal of overlapping PA bins
              pa.nbins[j,*] = index              ; normalization factor (# overlapping PA bins)
              pa.index[j,*] = float(index gt 0.) ; bins that have signal (1=yes, 0=no)
              pa.std[j,*] = SQRT(variance) / index  ; standard deviation (error propagation)
              undefine, k, cnt
              undefine, tot, index, variance
           ENDFOR  
           pa.xax = xax * !RADEG
           undefine, tot, index
        ENDELSE 
     ENDELSE  
     skip_spec:
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
     'counts': oztit = 'Counts / Samples'
     'crate' : oztit = 'CRATE'
     'eflux' : oztit = 'EFLUX'
     'flux'  : oztit = 'FLUX'
     'df'    : oztit = 'Distribution Function'
     ELSE    : oztit = 'Unknown Units' 
  ENDCASE 
  IF keyword_set(normal) THEN $
     ztit = 'Normalized ' + oztit ELSE ztit = oztit

  IF (pflg[0]) OR (pflg[2]) OR (pflg[3]) THEN BEGIN
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

     nfct = average(zdata, 1, /nan)
     IF keyword_set(normal) THEN BEGIN
        ;; zdata /= REBIN(TRANSPOSE(average(zdata, 1, /nan)), nbins, nene)
        zdata /= REBIN(TRANSPOSE(nfct), nbins, nene)

        i = WHERE(index EQ 0, cnt)
        IF cnt GT 0 THEN zdata[i] = nan
        undefine, i, cnt

        ;; str_element, plim, 'zrange', [0.1, 10.], /add        
        str_element, plim, 'zrange', [0.5, 1.5], /add
        str_element, plim, 'zlog', 0, /add_replace
     ENDIF
  ENDIF 

  IF (pflg[0]) THEN BEGIN       ; Plot snapshot section.
     plotxyz, xax, energy[edx], zdata, wi=wnum, _extra=plim, $
              xtit='Pitch Angle [deg]', ytit='Energy [eV]', ztit=ztit, $
              yrange=minmax(energy), title=tit, xmargin=[0.15, 0.17], ymargin=[0.10, 0.09]
     wnum += 1
  ENDIF 

  ;; IF keyword_set(tplot) THEN BEGIN
  IF (pflg[1]) THEN BEGIN       ; Generate a tplot valiable section
     ytit = 'SWE PAD!C('
     IF nene EQ 1 THEN ytit += STRING(energy[edx[0]], '(f0.1)') + ' eV)' $
     ELSE ytit += STRING(MIN(energy[edx]), '(f0.1)') + ' - ' + STRING(MAX(energy[edx]), '(f0.1)') + ' eV)' 

     data = TRANSPOSE(average(result.avg, 1, /nan))
     nfactor = average(data, 2, /nan)
     IF keyword_set(normal) THEN BEGIN
        data /= REBIN(nfactor, ndat, nbins)
;        data /= REBIN(average(data, 2, /nan), ndat, nbins)
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
                 data={x: result.time, y: data, v: TRANSPOSE(result.xax)}, $ ;, nfactor: nfactor}, $
                 dlim={nfactor: nfactor, spec: 1, yrange: [0., 180.], ystyle: 1, yticks: 6, yminor: 3, $
                       ytitle: ytit, ysubtitle: '[deg]', ztitle: ztit, zlog: zlog, zrange: zrange}

  ENDIF 
  ;; plim = {noiso: 1, zlog: 1, charsize: chsz, xticks: 6, xminor: 3, xrange: [0., 180.], ylog: 1}  

  IF (pflg[2]) OR (pflg[3]) THEN BEGIN 
     pos = [0.15, 0.10, 0.83, 0.91]
     pbar = pos
     pbar[0] = pos[2] + (pos[2]-pos[0])*.05  
     pbar[2] = pos[2] + (pos[2]-pos[0])*.1
     
     IF NOT keyword_set(normal) THEN $
        spec = mvn_swe_getspec(trange, /sum, archive=archive, units=units, yrange=yrange) $
     ELSE yrange = [0.1, 10.]
     undefine, spec
  ENDIF 

  IF (pflg[2]) THEN BEGIN       ; Plot pitch-angle-sorted 1-d spectra.
     ;; lc = colorscale(ALOG10(energy), mincol=7, maxcol=254, mindat=MIN(ALOG10(energy)), maxdat=MAX(ALOG10(energy)))
     lc = mvn_swe_pad_resample_cscale(ALOG10(energy), mincol=7, maxcol=254, $
                                      mindat=MIN(ALOG10(energy)), maxdat=MAX(ALOG10(energy)))
     wi, wnum, wsize=[640, 512]
     PLOT_IO, /nodata, [0., 180.], yrange, charsize=chsz, xticks=6, xminor=3, $
              xrange=[0., 180.], /xstyle, yrange=yrange, /ystyle, xtitle='Pitch Angle [deg]', $
              ytitle=ztit, title=tit, pos=pos
     FOR i=0, N_ELEMENTS(edx)-1 DO $
        OPLOT, xax, zdata[*, i], psym=10, color=lc[edx[i]]
     
     draw_color_scale, range=minmax(energy), /log, charsize=chsz, pos=pbar, $
                       brange=[7, 254], ytitle='Energy [eV]'
     wnum += 1
  ENDIF 

  IF (pflg[3]) THEN BEGIN       ; Plot pitch-angle-selected 1-d energy spectra.
     ;; lc = colorscale(xax, mincol=7, maxcol=254, mindat=0., maxdat=180.)
     angle = [15., 52.5, 90., 127.5, 165.]
     lc = mvn_swe_pad_resample_cscale(angle, mincol=7, maxcol=254, mindat=0., maxdat=180.)

     wi, wnum, wsize=[640, 512]

     spec = mvn_swe_getspec(trange, /sum, archive=archive, units=units, yrange=yrange) 
     PLOT_OO, /nodata, minmax(energy), yrange, charsize=chsz, $
              xrange=minmax(energy), /xstyle, yrange=yrange, /ystyle, xtitle='Energy [eV]', $
              ytitle=oztit, title=tit, pos=pos

     IF keyword_set(normal) THEN zdata2 = zdata * REBIN(TRANSPOSE(nfct), nbins, nene) ELSE zdata2 = zdata
     
     ;; FOR i=0, nbins-1 DO $
     ;;    OPLOT, energy, zdata2[i, *], psym=10, color=lc[i]
     FOR i=0, N_ELEMENTS(lc)-1 DO BEGIN
        IF (i MOD 2) EQ 0 THEN j = WHERE(xax GE angle[i] - 15. AND xax LE angle[i] + 15.) $
        ELSE j = WHERE(xax GE angle[i] - 22.5 AND xax LE angle[i] + 22.5) 

        zavg = average(zdata2[j, *], 1, stdev=zdev, /nan)
        ;; oploterror, energy, zavg, zdev, color=lc[i], errcolor=lc[i], psym=10
        OPLOT, energy, zavg, color=lc[i], psym=10
        FOR k=0, N_ELEMENTS(energy)-1 DO $ ; Draws error bars.
           plots, [energy[k], energy[k]], [zavg[k]-zdev[k], zavg[k]+zdev[k]], color=lc[i]

        undefine, zavg, zdev, j, k
     ENDFOR 
     draw_color_scale, range=[0., 180.], charsize=chsz, pos=pbar, $
                       brange=[7, 254], ytitle='Pitch Angle [deg]', yticks=6, xminor=3
     undefine, spec
  ENDIF 

  RETURN
END
