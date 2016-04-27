;+
;PROCEDURE:   mvn_swe_swi_cal
;PURPOSE:
;  Compares ion density from SWIA and electron density from SWEA for the purpose 
;  of cross calibration.  Beware of situations where SWEA and/or SWIA are not
;  measuring important parts of the distribution.  Furthermore, SWEA data must be
;  corrected for spacecraft potential (see mvn_swe_sc_pot), and photoelectron 
;  contamination must be removed for any hope of a decent cross calibration.
;
;USAGE:
;  mvn_swe_swi_cal
;
;INPUTS:
;   None.  Uses the current value of TRANGE_FULL to define the time range
;   for analysis.  Calls timespan, if necessary, to set this value.
;
;KEYWORDS:
;   FINE:      Select SWIA 'fine' data for comparison with SWEA.  Default
;              is to use 'coarse' data.
;
;   DDD:       Use SWEA 3D data for computing density.  Allows for bin
;              masking.
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
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-04-25 20:09:15 -0700 (Mon, 25 Apr 2016) $
; $LastChangedRevision: 20925 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_swi_cal.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_swi_cal, fine=fine, ddd=ddd, abins=abins, dbins=dbins, obins=obins, $
                     mask_sc=mask_sc

  @mvn_swe_com

  tplot_options, get=opt
  if (max(opt.trange_full) eq 0D) then timespan

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

; Load SWEA data and create summary plot

  mvn_swe_load_l0
  mvn_swe_sumplot,/eph,/orb,/loadonly

; Get illumination of SWEA (to evaluate sunlight contamination)

  mvn_swe_sundir
  pans = ['Sun_The','Sun_Phi','alt2']
  
; Load MAG data

  mvn_swe_addmag
  if (size(swe_mag1,/type) eq 8) then begin
    mvn_mag_load,spice_frame='mso'
    options,'mvn_B_1sec_mso','ytitle','B!dMSO!n [nT]'
  endif else print,"No MAG data at all!"


; Calculate spacecraft potential and electron density from SWEA data

  dfoo = dflg
  mvn_swe_sc_pot,/over,ddd=dfoo,obins=obins[*,1],mask_sc=mask_sc,fudge=1.15
  dfoo = dflg
  mvn_swe_n1d,/mom,ddd=dfoo,obins=obins[*,1],mask_sc=mask_sc
  if (dflg) then dname = 'mvn_swe_3d_dens' else dname = 'mvn_swe_spec_dens'
  get_data,dname,data=den
  store_data,'mvn_swe_n1d_over',data={x:den.x, y:den.y}
  options,'mvn_swe_n1d_over','color',6
  options,'mvn_swe_n1d_over','psym',-3

; Load SWIA fine spectra

  if keyword_set(fine) then begin
    mvn_swia_load_l2_data, /loadfine, /tplot
    mvn_swia_part_moments, type=['fs','fa']
    options,'mvn_swifs_density','ynozero',1
    get_data,'mvn_swifs_density',data=den
    dt = den.x - shift(den.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then den.y[indx] = !values.f_nan
    store_data,'mvn_swifs_density',data=den
    store_data,'ie_density',data=['mvn_swifs_density','mvn_swe_n1d_over']
    options,'ie_density','ynozero',1
    options,'ie_density','ytitle','Ion-Electron!CDensity'

    div_data,'mvn_swe_spec_dens','mvn_swifs_density'
    divname = 'mvn_swe_spec_dens/mvn_swifs_density'
    options,divname,'ynozero',1
    options,divname,'ytitle','Ratio!CSWE/SWI'
    options,divname,'yticklen',1
    options,divname,'ygridstyle',1

    pans = [pans,'mvn_swe_spec_dens/mvn_swifs_density', $
            'ie_density','mvn_B_1sec_mso','swe_a4_pot']
  endif else begin
    mvn_swia_load_l2_data, /loadcoarse, /tplot
    mvn_swia_part_moments, type=['cs','ca']
    options,'mvn_swics_density','ynozero',1
    get_data,'mvn_swics_density',data=den
    dt = den.x - shift(den.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then den.y[indx] = !values.f_nan
    store_data,'mvn_swics_density',data=den
    store_data,'ie_density',data=['mvn_swics_density','mvn_swe_n1d_over']
    options,'ie_density','ynozero',1
    options,'ie_density','ytitle','Ion-Electron!CDensity'

    div_data,'mvn_swe_spec_dens','mvn_swics_density'
    divname = 'mvn_swe_spec_dens/mvn_swics_density'
    options,divname,'ynozero',1
    options,divname,'ytitle','Ratio!CSWE/SWI'
    options,divname,'yticklen',1
    options,divname,'ygridstyle',1

    pans = [pans,'mvn_swe_spec_dens/mvn_swics_density', $
            'ie_density','mvn_B_1sec_mso','swe_a4_pot']
  endelse

  tplot,pans

  return

end
