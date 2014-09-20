;+
;PROCEDURE: 
;	mvn_swe_sc_pot
;
;PURPOSE:
;	Estimates the spacecraft potential from SWEA energy spectra.
;
;   This routine is EXPERIMENTAL.
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
;              Default = [3.,15.]
;
;   PSMO:      Smoothing parameter for the derived potentials.
;
;   ESMO:      Smoothing parameter in energy for dF and d2F.
;              Not recommended.
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
;   PANS:      Named varible to hold the tplot panels created.
;
;   OVERLAY:   Overlay the result on the energy spectrogram.
;
;OUTPUTS:
;   none - result is returned via POTENTIAL keyword or as TPLOT variable.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-09-16 09:33:00 -0700 (Tue, 16 Sep 2014) $
; $LastChangedRevision: 15803 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=phi, erange=erange, psmo=psmo, esmo=esmo, fudge=fudge, $
                    pans=pans, overlay=overlay, ddd=ddd, abins=abins, dbins=dbins

  compile_opt idl2
  
  @mvn_swe_com

  if (data_type(mvn_swe_engy) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif
  
  if not keyword_set(erange) then erange = [3.,15.]
  erange = float(erange[sort(erange)])
  if not keyword_set(psmo) then psmo = 1
  if not keyword_set(esmo) then esmo = 1
  if not keyword_set(fudge) then fudge = 1.
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if not keyword_set(abins) then abins = replicate(1B, 16)
  if not keyword_set(dbins) then dbins = replicate(1B, 6)
  
  if (dflg) then begin
    t = swe_3d.time
    npts = n_elements(t)
    obins = reform(abins # dbins, 96)
    indx = where(obins eq 1B, ocnt)
    onorm = float(ocnt)
    obins = replicate(1B, 64) # obins
    e = fltarr(64,npts)
    f = e
    
    for i=0L,(npts-1L) do begin
      ddd = mvn_swe_get3d(t[i], units='eflux')
      e[*,i] = ddd.energy[*,0]
      f[*,i] = total(ddd.data * obins, 2)/onorm
    endfor

  endif else begin
    
    old_units = mvn_swe_engy[0].units_name
    mvn_swe_convert_units, mvn_swe_engy, 'eflux'

    t = mvn_swe_engy.time
    npts = n_elements(t)
    e = mvn_swe_engy.energy
    f = mvn_swe_engy.data

  endelse
  
  indx = where(e[*,0] lt 60., n_e)
  e = e[indx,*]
  f = alog10(f[indx,*])

; Filter out bad spectra

  gndx = round(total(finite(f),1))
  gndx = where(gndx eq n_e, npts)
  t = t[gndx]
  e = e[*,gndx]
  f = f[*,gndx]

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
  dfs = smooth(dfs,[esmo,1])

  d2fs = fltarr(n_es,npts)
  for i=0L,(npts-1L) do d2fs[*,i] = interpol(d2f[*,i],n_es)
  d2fs = smooth(d2fs,[esmo,1])

; Trim to the desired search range

  indx = where((ee[*,0] gt erange[0]) and (ee[*,0] lt erange[1]), n_e)
  ee = ee[indx,*]
  dfs = dfs[indx,*]
  d2fs = d2fs[indx,*]

; The spacecraft potential is taken to be the maximum curvature (d2logF/dlogE2)
; within the search window.  A fudge factor is included to adjust the estimate 
; for cross calibration with LPW.
;
; Use diagnostics keywords in swe_engy_snap to plot these functions, together
; with the retrieved potential.

  phi = fltarr(npts)
  for i=0L,(npts-1L) do begin
    dmax = max(dfs[*,i],j)
    d2max = max(d2fs[0:j,i],k)
    phi[i] = ee[k,i]
  endfor

  phi = smooth(phi*fudge,psmo,/nan)

  if (not dflg) then begin
    mvn_swe_engy[gndx].sc_pot = phi
    mvn_swe_convert_units, mvn_swe_engy, old_units
  endif else begin
    mvn_swe_engy.sc_pot = interpol(phi,t,mvn_swe_engy.time)
  endelse
  
  swe_sc_pot = replicate(swe_pot_struct, npts)
  swe_sc_pot.time = t
  swe_sc_pot.potential = phi
  swe_sc_pot.valid = 1

; Make tplot variables
  
  store_data,'df',data={x:t, y:transpose(dfs), v:transpose(ee)}
  options,'df','spec',1
  ylim,'df',0,30,0
  zlim,'df',0,0,0
  
  store_data,'d2f',data={x:t, y:transpose(d2fs), v:transpose(ee)}
  options,'d2f','spec',1
  ylim,'d2f',0,30,0
  zlim,'d2f',0,0,0

  pot = {x:t, y:phi}  
  store_data,'mvn_swe_sc_pot',data=pot
  pans = 'mvn_swe_sc_pot'

  store_data,'Potential',data=['d2f','mvn_swe_sc_pot']
  ylim,'Potential',0,30,0

  if keyword_set(overlay) then begin
    str_element,pot,'thick',2,/add
    str_element,pot,'color',0,/add
    store_data,'swe_pot_overlay',data=pot
    store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
    ylim,'swe_a4_pot',3,5000,1

    tplot_options, get=opt
    i = (where(opt.varnames eq 'swe_a4'))[0]
    if (i ne -1) then opt.varnames[i] = 'swe_a4_pot'
    i = (where(opt.varnames eq 'swe_a4_pot'))[0]
    if (i eq -1) then opt.varnames = [opt.varnames, 'swe_a4_pot']

    tplot, opt.varnames
  endif

  return

end
