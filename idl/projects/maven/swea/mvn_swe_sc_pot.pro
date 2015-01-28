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
;              Default = [3.,20.]
;
;   THRESH:    Threshold for the minimum slope: d(logF)/d(logE). 
;              Default = 0.05
;
;              A smaller value includes more data and extends the range 
;              over which you can estimate the potential, but at the 
;              expense of making more errors.
;
;   DEMAX:     The largest allowable energy width of the spacecraft 
;              potential feature.  This excludes features not related
;              to the spacecraft potential at higher energies (often 
;              observed downstream of the shock).  Default = 4 eV.
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
;              Takes precedence over ABINS and DBINS.  No default, but
;              must have 96 elements.
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   OVERLAY:   Overlay the result on the energy spectrogram.
;
;OUTPUTS:
;   None - Result is stored in SPEC data structure, returned via POTENTIAL
;          keyword, and stored as a TPLOT variable.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-01-24 14:40:03 -0800 (Sat, 24 Jan 2015) $
; $LastChangedRevision: 16729 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=phi, erange=erange, fudge=fudge, thresh=thresh, dEmax=dEmax, $
                    pans=pans, overlay=overlay, ddd=ddd, abins=abins, dbins=dbins, obins=obins

  compile_opt idl2
  
  @mvn_swe_com

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif

; Clear any previous potential calculations

  mvn_swe_engy.sc_pot = !values.f_nan
  
  if not keyword_set(erange) then erange = [3.,20.]
  erange = minmax(float(erange))
  if not keyword_set(fudge) then fudge = 1.
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if not keyword_set(abins) then abins = replicate(1B, 16)
  if not keyword_set(dbins) then dbins = replicate(1B, 6)
  if (size(thresh,/type) eq 0) then thresh = 0.05
  if (size(dEmax,/type) eq 0) then dEmax = 4.
  
  if (dflg) then begin
    t = swe_3d.time
    npts = n_elements(t)
    if (n_elements(obins) ne 96) then obins = reform(abins # dbins, 96)
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
  if (npts gt 0L) then begin
    t = t[gndx]
    e = e[*,gndx]
    f = f[*,gndx]
  endif else begin
    print,"No good spectra!"
    return
  endelse

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

; Trim to the desired search range

  indx = where((ee[*,0] gt erange[0]) and (ee[*,0] lt erange[1]), n_e)
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

  phi = replicate(!values.f_nan, npts)
  for i=0L,(npts-1L) do begin
    indx = where((dfs[*,i] gt thresh) and (zcross[*,i] lt 0.), ncross) ; local maxima in slope

    if (ncross gt 0) then begin
      k = max(indx)               ; lowest energy feature above threshold
      dfsmax = dfs[k,i]
      dfsmin = dfsmax/3.

      while ((dfs[k,i] gt dfsmin) and (k lt n_e-1)) do k++
      kmax = k
      k = max(indx)
      while ((dfs[k,i] gt dfsmin) and (k gt 0)) do k--
      kmin = k
      
      dE = ee[kmin,i] - ee[kmax,i]
      if ((kmax eq (n_e-1)) or (kmin eq 0)) then dE = 2.*dEmax
      
      if (dE lt dEmax) then phi[i] = ee[max(indx),i]  ; only accept narrow features
    endif
  endfor

; Filter for low flux

  fmax = max(mvn_swe_engy[gndx].data, dim=1)
  indx = where(fmax lt 1.e7, count)
  if (count gt 0L) then phi[indx] = !values.f_nan

; Filter out shadow regions

  get_data, 'wake', data=wake, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /current, /loadonly
    get_data, 'wake', data=wake, index=i
  endif
  if (i gt 0) then begin
    shadow = interpol(float(finite(wake.y)), wake.x, mvn_swe_engy[gndx].time)
    indx = where(shadow gt 0., count)
    if (count gt 0L) then phi[indx] = !values.f_nan
  endif

; Filter out altitudes below 250 km

  get_data, 'alt', data=alt, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /current, /loadonly
    get_data, 'alt', data=alt, index=i
  endif
  if (i gt 0) then begin
    altitude = interpol(alt.y, alt.x, mvn_swe_engy[gndx].time)
    indx = where(altitude lt 250., count)
    if (count gt 0L) then phi[indx] = !values.f_nan
  endif

; Apply fudge factor, and store the result

  phi = phi*fudge

  if (not dflg) then begin
    mvn_swe_engy[gndx].sc_pot = phi
    mvn_swe_convert_units, mvn_swe_engy, old_units
  endif else begin
    mvn_swe_engy[gndx].sc_pot = interpol(phi,t,mvn_swe_engy[gndx].time)
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
    str_element,pot,'psym',3,/add
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
