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
;              Default = [4.,40.]
;
;   SMO:       Smoothing parameter for the derived potentials.
;
;   FUDGE:     Multiply the derived potential by this fudge factor.
;              Default = 1.
;
;OUTPUTS:
;   none - result is returned via POTENTIAL keyword.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-07-10 18:11:18 -0700 (Thu, 10 Jul 2014) $
; $LastChangedRevision: 15559 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=phi, erange=erange, smo=smo, fudge=fudge

  compile_opt idl2
  
  @mvn_swe_com

  if (data_type(mvn_swe_engy) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif
  
  if not keyword_set(erange) then erange = [4.,40.]
  erange = float(erange[sort(erange)])
  if not keyword_set(smo) then smo = 1
  if not keyword_set(fudge) then fudge = 1.
    
  old_units = mvn_swe_engy[0].units_name
  mvn_swe_convert_units, mvn_swe_engy, 'crate'

  npts = n_elements(mvn_swe_engy.time)
  e = mvn_swe_engy.energy
  f = mvn_swe_engy.data
  
  indx = where(e[*,0] lt 60., n_e)
  e = e[indx,*]
  f = alog10(f[indx,*])

; Take second and third derivatives of log(eflux) w.r.t. log(E)

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
  dfs = smooth(dfs,[9,1])

  d2fs = fltarr(n_es,npts)
  for i=0L,(npts-1L) do d2fs[*,i] = interpol(d2f[*,i],n_es)
  d2fs = smooth(d2fs,[9,1])

  indx = where((ee[*,0] gt erange[0]) and (ee[*,0] lt erange[1]))
  ee = ee[indx,*]
  dfs = dfs[indx,*]
  d2fs = d2fs[indx,*]
  
  sign = d2fs*shift(d2fs,[1,0])

; The spacecraft potential is taken to be the local maximum slope (dlogF/dlogE)
; at energies just below the maximum curvature (d2logF/dlogE2). Use diagnostics
; keywords in swe_engy_snap to plot these functions, together with the retrieved
; potential.

  phi = fltarr(npts)
  for i=0L,(npts-1L) do begin
    d2max = max(d2fs[*,i],j)    
    k = (where(sign[j:*,i] lt 0.))[0]
    phi[i] = ee[j+k,i]
  endfor
  phi = smooth(phi*fudge,smo,/nan)

  mvn_swe_convert_units, mvn_swe_engy, old_units

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

  return

end
