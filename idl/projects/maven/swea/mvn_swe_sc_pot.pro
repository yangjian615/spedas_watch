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
;              Default = [4.,15.]
;
;   PSMO:      Smoothing parameter for the derived potentials.
;
;   ESMO:      Smoothing parameter in energy for dF and d2F.
;              Not recommended.
;
;   FUDGE:     Multiply the derived potential by this fudge factor.
;              (for calibration against LPW).  Default = 1.
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   OVERLAY:   Overlay the result on the energy spectrogram.
;
;OUTPUTS:
;   none - result is returned via POTENTIAL keyword or as TPLOT variable.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:43:05 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15668 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=phi, erange=erange, psmo=psmo, esmo=esmo, fudge=fudge, $
                    pans=pans, overlay=overlay

  compile_opt idl2
  
  @mvn_swe_com

  if (data_type(mvn_swe_engy) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif
  
  if not keyword_set(erange) then erange = [4.,15.]
  erange = float(erange[sort(erange)])
  if not keyword_set(psmo) then psmo = 1
  if not keyword_set(esmo) then esmo = 1
  if not keyword_set(fudge) then fudge = 1.
    
  old_units = mvn_swe_engy[0].units_name
  mvn_swe_convert_units, mvn_swe_engy, 'crate'

  npts = n_elements(mvn_swe_engy.time)
  e = mvn_swe_engy.energy
  f = mvn_swe_engy.data
  
  indx = where(e[*,0] lt 60., n_e)
  e = e[indx,*]
  f = alog10(f[indx,*])

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
  mvn_swe_engy.sc_pot = phi

  mvn_swe_convert_units, mvn_swe_engy, old_units
  
  swe_sc_pot = replicate(swe_pot_struct, npts)
  swe_sc_pot.time = mvn_swe_engy.time
  swe_sc_pot.potential = phi
  swe_sc_pot.valid = 1

; Make tplot variables
  
  store_data,'df',data={x:mvn_swe_engy.time, y:transpose(dfs), v:transpose(ee)}
  options,'df','spec',1
  ylim,'df',0,30,0
  zlim,'df',0,0,0
  
  store_data,'d2f',data={x:mvn_swe_engy.time, y:transpose(d2fs), v:transpose(ee)}
  options,'d2f','spec',1
  ylim,'d2f',0,30,0
  zlim,'d2f',0,0,0

  store_data,'phi',data={x:mvn_swe_engy.time, y:phi}
  options,'phi','thick',2
  options,'phi','color',0

  store_data,'Potential',data=['d2f','phi']
  ylim,'Potential',0,30,0
  
  pans = 'Potential'

  if keyword_set(overlay) then begin
    tplot_options, get=opt
    i = (where(opt.varnames eq 'swe_a4'))[0]
    if (i ne -1) then begin
      store_data,'swe_a4_pot',data=['swe_a4','phi']
      ylim,'swe_a4_pot',3,5000,1
      opt.varnames[i] = 'swe_a4_pot'
      tplot, opt.varnames
    endif else begin
      i = (where(opt.varnames eq 'swe_a4_pot'))[0]
      if (i ne -1) then tplot
    endelse
  endif

  return

end
