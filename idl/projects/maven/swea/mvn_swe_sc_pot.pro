;+
;PROCEDURE: 
;	mvn_swe_sc_pot
;
;PURPOSE:
;	Estimates the spacecraft potential from SWEA energy spectra.  The basic
;   idea is to look for a break in the energy spectrum (sharp change in flux
;   level and slope).  No attempt is made to estimate the potential when the
;   spacecraft is in darkness (expect negative potential) or below 250 km
;   altitude (expect small or negative potential).
;
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	mvn_swe_sc_pot, potential=dat
;
;INPUTS: 
;   none - energy spectra are obtained from SWEA common block.
;
;KEYWORDS:
;	POTENTIAL: Returns a time-ordered array of spacecraft potentials
;
;   ERANGE:    Energy range over which to search for the potential.
;              Default = [3.,30.]
;
;   THRESH:    Threshold for the minimum slope: d(logF)/d(logE). 
;              Default = 0.05
;
;              A smaller value includes more data and extends the range 
;              over which you can estimate the potential, but at the 
;              expense of making more errors.
;
;   MINFLUX:   Minimum peak energy flux.  Default = 1e6.
;
;   DEMAX:     The largest allowable energy width of the spacecraft 
;              potential feature.  This excludes features not related
;              to the spacecraft potential at higher energies (often 
;              observed downstream of the shock).  Default = 6 eV.
;
;   FUDGE:     Multiply the derived potential by this fudge factor.
;              (for calibration against LPW).  Default = 1.
;
;   DDD:       Use 3D data to calculate potential.  Allows bin masking,
;              but lower cadence and typically lower energy resolution.
;
;   ABINS:     When using 3D spectra, specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     When using 3D spectra, specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   OBINS:     When using 3D spectra, specify which solid angle bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = reform(ABINS#DBINS,96).  Takes precedence over
;              ABINS and OBINS.
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking specified by the above three keywords.
;              Default = 1 (yes).
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   OVERLAY:   Overlay the result on the energy spectrogram.
;
;   SETVAL:    Make no attempt to estimate the potential, just set it to
;              this value.  Units = volts.  No default.
;
;   BADVAL:    If the algorithm cannot estimate the potential, then set it
;              to this value.  Units = volts.  Default = NaN.
;
;   ANGCORR:   Angular distribution correction based on interpolated 3d data
;              to emphasize the returning photoelectrons and improve 
;              the edge detection (added by Yuki Harada).
;
;   NEGPOT:    Calculate negative potentials with mvn_swe_sc_negpot.
;              Default = 1 (yes).
;
;   STA_POT:   Use STATIC-derived potentials to fill in gaps.  This is 
;              especially useful in the high-altitude shadow region.
;              Assumes that you have calculated STATIC potentials.
;              (See mvn_sta_scpot_load.pro)
;
;   LPW_POT:   Use pre-calculated SWEA+LPW-derived potentials.  There is
;              a ~2-week delay in the production of this dataset.  You can
;              set this keyword to the full path and filename of a tplot 
;              save/restore file, if one exists.  Otherwise, this routine 
;              will determine the potential from SWEA alone.
;              
;   POT_IN_SHDW: Calculate negative potentials with 'mvn_swe_sc_negpot_twodir_burst',
;                Default = 0 (no). This routine calculates He II in both field-aligned
;                directions, and uses the less negative one as s/c potentials if detected
;                in both directions. The results are filled to SWEA common block as well. 
;                Right row, it requires keyword "NEGPOT" to be 1, which is default. 
;
;OUTPUTS:
;   None - Result is stored in SPEC data structure, returned via POTENTIAL
;          keyword, and stored as a TPLOT variable.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-05-08 17:26:51 -0700 (Mon, 08 May 2017) $
; $LastChangedRevision: 23278 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=potential, erange=erange2, fudge=fudge, thresh=thresh2, dEmax=dEmax2, $
                    pans=pans, overlay=overlay, ddd=ddd, abins=abins, dbins=dbins, obins=obins, $
                    mask_sc=mask_sc, setval=setval, badval=badval, angcorr=angcorr, minflux=minflux2, $
                    negpot=negpot, sta_pot=sta_pot, lpw_pot=lpw_pot, pot_in_shdw=pot_in_shdw

  compile_opt idl2
  
  @mvn_swe_com
  common swe_pot_com, Espan, thresh, dEmax, minflux
  
  if (size(Espan,/type) eq 0) then begin
    Espan = [3.,30.]
    thresh = 0.05
    dEmax = 6.
    minflux = 1.e6
  endif
  
  if (n_elements(erange2)  gt 1) then Espan = float(minmax(erange2))
  if (size(thresh2,/type)  gt 0) then thresh = float(thresh2)
  if (size(dEmax2,/type)   gt 0) then dEmax = float(dEmax2)
  if (size(minflux2,/type) gt 0) then minflux = float(minflux2)

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif
  
  if (size(setval,/type) ne 0) then begin
    print,"Setting the s/c potential to: ",setval
    mvn_swe_engy.sc_pot = setval
    swe_sc_pot = replicate(swe_pot_struct, n_elements(mvn_swe_engy))
    swe_sc_pot[*].time = mvn_swe_engy.time
    swe_sc_pot[*].potential = setval
    pot = {x:mvn_swe_engy.time, y:mvn_swe_engy.sc_pot}
    store_data,'mvn_swe_sc_pot',data=pot

    if keyword_set(overlay) then begin
      str_element,pot,'thick',2,/add
      str_element,pot,'color',0,/add
      str_element,pot,'psym',3,/add
      store_data,'swe_pot_overlay',data=pot
      store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
      ylim,'swe_a4_pot',3,5000,1
    endif

    return
  endif
  
  if (size(badval,/type) eq 0) then badval = !values.f_nan else badval = float(badval)
  if (size(negpot,/type) eq 0) then negpot = 1
  ;if (size(pot_in_shdw,/type) eq 0) then pot_in_shdw = 1
  
; Clear any previous potential calculations

  mvn_swe_engy.sc_pot = badval

; Get pre-calculated potentials from combined SWEA-LPW analysis ...

  ok = 0

  if keyword_set(lpw_pot) then begin

    if (size(lpw_pot,/type) eq 7) then tplot_restore, file=lpw_pot $
                                  else mvn_swe_lpw_scpot_restore

    get_data,'mvn_swe_lpw_scpot_pow',data=lpwpot,index=i
    if (i gt 0) then begin
      t = mvn_swe_engy.time
      npts = n_elements(t)
      phi = replicate(badval, npts)
      phi = interpol(lpwpot.y, lpwpot.x, t)
      mvn_swe_engy.sc_pot = phi
      ok = 1
    endif

  endif

; ... otherwise calculate potential from SWEA alone
  
  if (not ok) then begin

    Espan = minmax(float(Espan))
    if not keyword_set(fudge) then fudge = 1.
    if keyword_set(ddd) then dflg = 1 else dflg = 0

    if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = byte(obins # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
   if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  
    if (dflg) then begin
      ok = 0
      if (size(mvn_swe_3d,/type) eq 8) then begin
        t = mvn_swe_3d.time
        npts = n_elements(t)
        e = fltarr(64,npts)
        f = e
        ok = 1
      endif

      if ((not ok) and size(swe_3d,/type) eq 8) then begin
        t = swe_3d.time
        npts = n_elements(t)
        e = fltarr(64,npts)
        f = e
        ok = 1
      endif
    
      if (not ok) then begin
        print, "No valid 3D data."
        return
      endif
    
      for i=0L,(npts-1L) do begin
        ddd = mvn_swe_get3d(t[i], units='eflux')

        if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0
        ondx = where(obins[*,boom] eq 1B, ocnt)
        onorm = float(ocnt)
        obins_b = replicate(1B, 64) # obins[*,boom]

        e[*,i] = ddd.energy[*,0]
        f[*,i] = total(ddd.data * obins_b, 2, /nan)/onorm
      endfor

    endif else begin
    
     old_units = mvn_swe_engy[0].units_name
      mvn_swe_convert_units, mvn_swe_engy, 'eflux'

      t = mvn_swe_engy.time
      npts = n_elements(t)
      e = mvn_swe_engy.energy
      f = mvn_swe_engy.data

    endelse
  
;  Angular distribution correction based on interpolated 3d data
;  to emphasize the returning photoelectrons.
;  This section was added by Yuki Harada.

    if keyword_set(angcorr) and (size(mvn_swe_3d,/type) eq 8) then begin
       ww = finite(mvn_swe_3d.data) * 1.
       wsky = where( mvn_swe_3d.phi gt 112.5 and mvn_swe_3d.phi lt 292.5 $
                     and mvn_swe_3d.theta gt -45 and mvn_swe_3d.theta lt 45 , comp=cwsky )
       ww[cwsky] = 0.
       skyflux = total(mvn_swe_3d.data*mvn_swe_3d.domega*ww,2,/nan) $
                 /total(mvn_swe_3d.domega*ww,2,/nan)

       ww = finite(mvn_swe_3d.data) * 1.
       aveflux = total(mvn_swe_3d.data*mvn_swe_3d.domega*ww,2,/nan) $
                 /total(mvn_swe_3d.domega*ww,2,/nan)

       fr = f * !values.f_nan
       for j=0,63 do fr[j,*] = interp(reform(skyflux[j,*]/aveflux[j,*]),mvn_swe_3d.time,t) < 1.2

;  A maximum factor of 1.2 is set to avoid too much emphasis on lowest
;  energy photoelectrons

       f = f * fr
    endif

    indx = where(e[*,0] lt 60., n_e)
    e = e[indx,*]
    f = alog10(f[indx,*])
  
    potstr = {time : 0D            , $
              pot  : !values.f_nan , $
              dE   : !values.f_nan , $
              amp  : !values.f_nan , $
              flg  : 0                }
    potential = replicate(potstr, npts)
    potential.time = t

; Filter out bad spectra

    potential.flg = 1
    n_f = round(total(finite(f),1))
    gndx = where(n_f eq n_e, ngud, complement=bad, ncomplement=nbad)

    if (ngud eq 0L) then begin
      print,"No good spectra!"
      return
    endif

    if (nbad gt 0L) then begin
      f[*,bad] = !values.f_nan
      potential[bad].flg = 0
    endif

; Take first and second derivatives of log(eflux) w.r.t. log(E)

    df = f
    d2f = f

    for i=0L,(npts-1L) do df[*,i] = deriv(f[*,i])
    for i=0L,(npts-1L) do d2f[*,i] = deriv(df[*,i])

; Oversample and smooth

    n_es = 4*n_e
    emax = max(e, dim=1, min=emin)
    dloge = (alog10(emax) - alog10(emin))/float(n_es - 1)
    ee = 10.^((replicate(1.,n_es) # alog10(emax)) - (findgen(n_es) # dloge))
  
    dfs = fltarr(n_es,npts)
    for i=0L,(npts-1L) do dfs[*,i] = interpol(df[*,i],n_es)

    d2fs = fltarr(n_es,npts)
    for i=0L,(npts-1L) do d2fs[*,i] = interpol(d2f[*,i],n_es)

; Trim to the desired energy search range

    indx = where((ee[*,0] gt Espan[0]) and (ee[*,0] lt Espan[1]), n_e)
    ee = ee[indx,*]
    dfs = dfs[indx,*]
    d2fs = d2fs[indx,*]

; The spacecraft potential is taken to be the maximum slope (dlogF/dlogE)
; within the search window.  A fudge factor is included to adjust the estimate 
; for cross calibration with LPW.
;
; Use diagnostics keywords in swe_engy_snap to plot these functions, together
; with the retrieved potential.
  
    zcross = d2fs*shift(d2fs,1,0)
    zcross[0,*] = 1.

    phi = replicate(badval, npts)
    for i=0L,(npts-1L) do begin
      indx = where((dfs[*,i] gt thresh) and (zcross[*,i] lt 0.), ncross) ; local maxima in slope

      if (ncross gt 0) then begin
        k = max(indx)               ; lowest energy feature above threshold
        dfsmax = dfs[k,i]
        dfsmin = dfsmax/2.          ; FWHM of slope

        while ((dfs[k,i] gt dfsmin) and (k lt n_e-1)) do k++
        kmax = k
        k = max(indx)
        while ((dfs[k,i] gt dfsmin) and (k gt 0)) do k--
        kmin = k
      
        dE = ee[kmin,i] - ee[kmax,i]
        if ((kmax eq (n_e-1)) or (kmin eq 0)) then dE = 2.*dEmax
      
        if (dE lt dEmax) then phi[i] = ee[max(indx),i]  ; only accept narrow features
      
        potential[i].dE = dE
        potential[i].amp = dfsmax
      endif
    endfor

; Filter for low flux

    fmax = max(mvn_swe_engy.data, dim=1)
    indx = where(fmax lt minflux, count)
    if (count gt 0L) then begin
      phi[indx] = badval
      potential[indx].flg = -1
    endif

; Filter out shadow regions

    get_data, 'wake', data=wake, index=i
    if (i eq 0) then begin
      maven_orbit_tplot, /current, /loadonly
      get_data, 'wake', data=wake, index=i
    endif
    if (i gt 0) then begin
      shadow = interpol(float(finite(wake.y)), wake.x, mvn_swe_engy.time)
      indx = where(shadow gt 0., count)
      if (count gt 0L) then begin
        phi[indx] = badval
        potential[indx].flg = -2
      endif
    endif

; Filter out altitudes below 250 km

    get_data, 'alt', data=alt, index=i
    if (i eq 0) then begin
      maven_orbit_tplot, /current, /loadonly
      get_data, 'alt', data=alt, index=i
    endif
    if (i gt 0) then begin
      altitude = interpol(alt.y, alt.x, mvn_swe_engy.time)
      indx = where(altitude lt 250., count)
      if (count gt 0L) then begin
        phi[indx] = badval
        potential[indx].flg = -3
      endif
    endif

; Apply fudge factor

    phi = phi*fudge
    potential.pot = phi

    if (not dflg) then begin
      mvn_swe_engy.sc_pot = phi
      mvn_swe_convert_units, mvn_swe_engy, old_units
    endif else begin
      mvn_swe_engy.sc_pot = interpol(phi,t,mvn_swe_engy.time)
    endelse

; Make tplot variables
  
    store_data,'df',data={x:t, y:transpose(dfs), v:transpose(ee)}
    options,'df','spec',1
    ylim,'df',0,30,0
    zlim,'df',0,0,0
  
    store_data,'d2f',data={x:t, y:transpose(d2fs), v:transpose(ee)}
    options,'d2f','spec',1
    ylim,'d2f',0,30,0
    zlim,'d2f',0,0,0

    store_data,'Potential',data=['d2f','mvn_swe_sc_pot']
    ylim,'Potential',0,30,0

  endif

; Store the result in the SWEA common block

  swe_sc_pot = replicate(swe_pot_struct, npts)
  swe_sc_pot.time = t
  swe_sc_pot.potential = phi
  swe_sc_pot.valid = 1

  pot = {x:t, y:phi}  
  store_data,'mvn_swe_sc_pot',data=pot
  pans = 'mvn_swe_sc_pot'

; Estimate negative potentials

  if keyword_set(negpot) then begin
    
    if keyword_set(pot_in_shdw) then mvn_swe_sc_negpot_twodir_burst,/fill,/shadow
    mvn_swe_sc_negpot, /fill
    indx = where(swe_sc_pot.potential lt 0., count)
    if (count gt 0L) then phi[indx] = swe_sc_pot[indx].potential

    pot_pan = 'mvn_swe_pot_all'
    store_data,'swe_pot_lab',data={x:minmax(t), y:replicate(!values.f_nan,2,2)}
    options,'swe_pot_lab','labels',['swe-','swe+']
    options,'swe_pot_lab','colors',[6,!p.color]
    options,'swe_pot_lab','labflag',1
    
    store_data,pot_pan,data=['swe_pot_lab','mvn_swe_sc_pot','neg_pot','pot_inshdw']
    options,'neg_pot','constant',!values.f_nan
    options,'neg_pot','color',6
    options,'pot_inshdw','constant',!values.f_nan
    options,'pot_inshdw','color',1
    options,pot_pan,'ytitle','S/C Potential!cVolts'
    options,pot_pan,'constant',[-1,3]
  endif

        
    
; Incorporate STATIC-derived potential.  Only used to fill in times when
; SWEA/LPW potential is unavailable.

  if keyword_set(sta_pot) then begin
    get_data,'mvn_sta_c6_scpot',data=stapot,index=i
    if (i gt 0) then begin
      indx = where(stapot.y ge 0., count)
      if (count gt 0L) then stapot.y[indx] = badval
      nndx = nn(stapot.x, t)
      if (finite(badval)) then indx = where(phi eq badval, count) $
                          else indx = where(~finite(phi), count)
      if (count gt 0L) then begin
        phi[indx] = stapot.y[nndx[indx]]
        swe_sc_pot.potential = phi
        mvn_swe_engy.sc_pot = phi

        sphi = replicate(!values.f_nan, n_elements(phi))
        sphi[indx] = phi[indx]
        store_data,'sta_pot',data={x:t, y:sphi}
        options,'sta_pot','color',4

        get_data,'mvn_swe_pot_all',data=tpot,index=i
        if (i gt 0) then begin
          tpot = [tpot,'sta_pot']
          store_data,'swe_pot_lab',data={x:minmax(t), y:replicate(!values.f_nan,2,3)}
          options,'swe_pot_lab','labels',['sta','swe-','swe+']
          options,'swe_pot_lab','colors',[4,6,!p.color]
          options,'swe_pot_lab','labflag',1
        endif else begin
          tpot = ['mvn_swe_sc_pot','sta_pot']
          pot_pan = 'mvn_swe_pot_all'
          store_data,'swe_pot_lab',data={x:minmax(t), y:replicate(!values.f_nan,2,2)}
          options,'swe_pot_lab','labels',['sta','swe+']
          options,'swe_pot_lab','colors',[4,!p.color]
          options,'swe_pot_lab','labflag',1
        endelse
        store_data,'mvn_swe_pot_all',data=tpot
      endif
    endif else print,"Can't find tplot variable: mvn_sta_c6_scpot"
  endif

  if keyword_set(overlay) then begin
    str_element,pot,'thick',2,/add
    str_element,pot,'color',0,/add
    str_element,pot,'psym',3,/add
    store_data,'swe_pot_overlay',data=pot
    store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
    ylim,'swe_a4_pot',3,5000,1

    tplot_options, get=opt
    str_element, opt, 'varnames', varnames, success=ok
    if (ok) then begin
      i = (where(varnames eq 'swe_a4'))[0]
      if (i ne -1) then begin
        varnames[i] = 'swe_a4_pot'
        tplot, varnames
      endif
    endif
  endif
  
  return

end
