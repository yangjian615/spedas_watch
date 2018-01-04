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
;	POTENTIAL: Returns spacecraft potentials in a structure.
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
;   ANGCORR:   Angular distribution correction based on interpolated 3d data
;              to emphasize the returning photoelectrons and improve 
;              the edge detection (added by Yuki Harada).
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   BADVAL:    If the algorithm cannot estimate the potential, then set it
;              to this value.  Units = volts.  Default = NaN.
;
;   FILL:      Do not fill in the common block.  Default = 0 (no).
;
;   RESET:     Initialize the spacecraft potential, discarding all previous 
;              estimates, and start fresh.
;
;OUTPUTS:
;   None - Result is stored in SPEC data structure, returned via POTENTIAL
;          keyword, and stored as a TPLOT variable.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-12-18 12:25:46 -0800 (Mon, 18 Dec 2017) $
; $LastChangedRevision: 24432 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=pot, erange=erange2, thresh=thresh2, dEmax=dEmax2, $
                    ddd=ddd, abins=abins, dbins=dbins, obins=obins2, mask_sc=mask_sc, $
                    badval=badval2, angcorr=angcorr, minflux=minflux2, pans=pans, $
                    fill=fill, reset=reset

  compile_opt idl2
  
  @mvn_swe_com
  @mvn_scpot_com

  pot = 0
  pans = ''

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    return
  endif

; Process keywords, set defaults

  if (size(Espan,/type) eq 0) then mvn_scpot_defaults

; Override defaults by keyword.  Affects all routines that use mvn_scpot_com.

  if (n_elements(erange2)  gt 1) then Espan = float(minmax(erange2))
  if (size(thresh2,/type)  gt 0) then thresh = float(thresh2)
  if (size(dEmax2,/type)   gt 0) then dEmax = float(dEmax2)
  if (size(minflux2,/type) gt 0) then minflux = float(minflux2)
  if (size(badval2,/type)  gt 0) then badval = float(badval2)

  reset = (keyword_set(reset) or (size(swe_sc_pot,/type) ne 8))
  dofill = keyword_set(fill)

  if keyword_set(ddd) then dflg = 1 else dflg = 0

; Configure the 3D FOV masK

  if ((size(obins,/type) eq 0) or keyword_set(abins) or keyword_set(dbins) or $
      keyword_set(obins2) or (size(mask_sc,/type) ne 0)) then begin
    if (n_elements(abins)  ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins)  ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins2) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = byte(obins2 # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
    if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  endif

; Initialize the potential structure

  badphi = !values.f_nan  ; bad value guaranteed to be a NaN

  npts = n_elements(mvn_swe_engy)
  pot = replicate(mvn_pot_struct, npts)
  pot.time = mvn_swe_engy.time
  pot.potential = badphi
  pot.method = -1

; Get energy flux vs. energy from SPEC or 3D data

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

; Estimate the potentials using the SWE+ method

  print,"Estimating positive potentials from SWEA alone."
  phi = mvn_swe_sc_pospot(e,f)

; Oversample 3D grid to SPEC grid, if necessary

  if (dflg) then begin
    phi = interpol(phi, t, swe_sc_pot.time)
    indx = nn(t, swe_sc_pot.time)
    gap = where(abs(t[indx] - swe_sc_pot.time) gt maxdt, count)
    if (count gt 0L) then phi[gap] = badphi  ; estimates too far away
  endif

; Fill in the potential structure

  igud = where(finite(phi), ngud)
  if (ngud gt 0L) then begin
    pot[igud].potential = phi[igud]
    pot[igud].method = 2
  endif

; Filter for low flux

  fmax = max(mvn_swe_engy.data, dim=1)
  indx = where(fmax lt minflux, count)
  if (count gt 0L) then begin
    pot[indx].potential = badphi
    pot[indx].method = -1
  endif

; Filter out shadow regions

  get_data, 'wake', data=wake, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /shadow, /loadonly
    get_data, 'wake', data=wake, index=i
  endif
  if (i gt 0) then begin
    shadow = interpol(float(finite(wake.y)), wake.x, mvn_swe_engy.time)
    indx = where(shadow gt 0., count)
    if (count gt 0L) then begin
      pot[indx].potential = badphi
      pot[indx].method = -1
    endif
  endif

; Filter out altitudes below 250 km

  get_data, 'alt', data=alt, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /current, /loadonly
    get_data, 'alt', data=alt, index=i
  endif
  if (i gt 0) then begin
    altitude = spline(alt.x, alt.y, mvn_swe_engy.time)
    indx = where(altitude lt 250., count)
    if (count gt 0L) then begin
      pot[indx].potential = badphi
      pot[indx].method = -1
    endif
  endif

; Report the result

  igud = where(pot.method eq 2, ngud, complement=ibad, ncomplement=nbad)
  msg = string("SWE+ : ",ngud," valid potentials from ",npts," spectra",format='(a,i8,a,i8,a)')
  print, strcompress(strtrim(msg,2))

; Make tplot variables for the swe+ method

  phi = {x:pot.time, y:pot.potential}

  store_data,'swe_pos',data=phi
  options,'swe_pos','color',2

  store_data,'df',data={x:pot.time, y:transpose(dfs), v:transpose(ee)}
  options,'df','spec',1
  ylim,'df',min(Espan),max(Espan),0
  zlim,'df',0,0,0

  store_data,'d2f',data={x:pot.time, y:transpose(d2fs), v:transpose(ee)}
  options,'d2f','spec',1
  ylim,'d2f',min(Espan),max(Espan),0
  zlim,'d2f',0,0,0

  return

end
