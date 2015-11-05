;+
;PROCEDURE: 
;	mvn_swe_sciplot
;PURPOSE:
;	Creates an science-oriented summary plot for SWEA and MAG and optionally other 
;   instruments.
;
;   Warning: This routine can consume a large amount of memory:
;
;     SWEA + MAG : 0.6 GB/day
;     SEP        : 0.2 GB/day
;     SWIA       : 0.2 GB/day
;     STATIC     : 3.5 GB/day
;     -------------------------
;      total     : 4.5 GB/day
;
;   You'll also need memory for performing calculations on large arrays, so you
;   can create a plot with all data types spanning ~1 day per 8 GB of memory.
;
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_sciplot
;INPUTS:
;   None:      Uses data currently loaded into the SWEA common block.
;
;KEYWORDS:
;   SUN:       Create a panel for the Sun direction in spacecraft coordinates.
;
;   RAM:       Create a panel for the RAM direction in spacecraft coordinates.
;
;   SEP:       Include two panels for SEP data: one for ions, one for electrons.
;
;   SWIA:      Include a panel for SWIA ion density (cs ground moments).
;
;   STATIC:    Include two panels for STATIC data: one mass spectrum, one energy
;              spectrum.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-04 17:39:26 -0800 (Wed, 04 Nov 2015) $
; $LastChangedRevision: 19247 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sciplot.pro $
;
;-

pro mvn_swe_sciplot, sun=sun, ram=ram, sep=sep, swia=swia, static=static

  compile_opt idl2

  @mvn_swe_com

  mvn_swe_sumplot,/loadonly
  mvn_swe_sc_pot,/over
  engy_pan = 'swe_a4_pot'
  options,engy_pan,'ytitle','SWEA elec!ceV'

; Try to load resampled PAD data

  mvn_swe_pad_restore
  tname = 'mvn_swe_pad_resample'
  get_data,tname,index=i
  if (i gt 0) then begin
    pad_pan = tname
    options,tname,'ytitle','SWEA PAD!c(111-140 eV)'
  endif else pad_pan = 'swe_a2_280'

; Spacecraft orientation

  alt_pan = 'alt2'

  if keyword_set(sun) then begin
    mvn_swe_sundir
    sun_pan = 'Sun_MAVEN_SPACECRAFT'
    get_data,sun_pan,index=i
    if (i gt 0) then begin
      options,sun_pan,'ytitle','Sun (PL)'
    endif else sun_pan = ''
  endif else sun_pan = ''

  if keyword_set(ram) then begin
    mvn_sc_ramdir
    ram_pan = 'V_sc_MAVEN_SPACECRAFT'
    get_data,ram_pan,index=i
    if (i gt 0) then begin
      options,ram_pan,'ytitle','RAM (PL)!ckm/s'
    endif else ram_pan = ''
  endif else ram_pan = ''

; MAG data

  mvn_swe_addmag
  mvn_mag_geom
  mvn_mag_tplot, /model
  
  mag_pan = 'mvn_mag_bamp mvn_mag_bang'

; SEP electron and ion data - sum all look directions for both units

  sepe_pan = ''
  sepi_pan = ''
  if keyword_set(sep) then begin
    mvn_sep_load

    get_data,'mvn_SEP1F_elec_eflux',data=sepe,dl=dlim,index=i
    if (i gt 0) then begin
      j = where(finite(sepe.v[*,0]),count)
      if (count gt 0L) then v = reform(sepe.v[j[0],*]) else v = findgen(15)
      sepe = 0
      sepe_pan = 'mvn_SEP_elec_eflux'
      add_data,'mvn_SEP1F_elec_eflux','mvn_SEP1R_elec_eflux',newname='mvn_SEP1_elec_eflux'
      add_data,'mvn_SEP2F_elec_eflux','mvn_SEP2R_elec_eflux',newname='mvn_SEP2_elec_eflux'
      add_data,'mvn_SEP1_elec_eflux','mvn_SEP2_elec_eflux',newname=sepe_pan
      get_data,sepe_pan,data=sepe,index=i
      if (i gt 0) then begin
        sepe = {x:sepe.x, y:sepe.y/4., v:v}
        store_data,sepe_pan,data=sepe,dl=dlim
        if (count gt 0L) then begin
          ylim,sepe_pan,20,200,1
          options,sepe_pan,'ytitle','SEP elec!ckeV'
        endif else begin
          ylim,sepe_pan,0,14,0
          options,sepe_pan,'ytitle','SEP elec!cchannel'
        endelse
        options,sepe_pan,'panel_size',0.5
      endif else begin
        print,"Missing SEP electron data."
        sepe_pan = ''
      endelse
      sepe = 0
    endif

    get_data,'mvn_SEP1F_ion_eflux',data=sepi,dl=dlim,index=i
    if (i gt 0) then begin
      j = where(finite(sepi.v[*,0]),count)
      if (count gt 0L) then v = reform(sepi.v[j[0],*]) else v = findgen(28)
      sepi = 0
      sepi_pan = 'mvn_SEP_ion_eflux'
      add_data,'mvn_SEP1F_ion_eflux','mvn_SEP1R_ion_eflux',newname='mvn_SEP1_ion_eflux'
      add_data,'mvn_SEP2F_ion_eflux','mvn_SEP2R_ion_eflux',newname='mvn_SEP2_ion_eflux'
      add_data,'mvn_SEP1_ion_eflux','mvn_SEP2_ion_eflux',newname=sepi_pan
      get_data,sepi_pan,data=sepi,index=i
      if (i gt 0) then begin
        sepi = {x:sepi.x, y:sepi.y/4., v:v}
        store_data,sepi_pan,data=sepi,dl=dlim
        if (count gt 0L) then begin
          ylim,sepi_pan,20,6000,1
          options,sepi_pan,'ytitle','SEP ion!ckeV'
        endif else begin
          ylim,sepi_pan,0,27,0
          options,sepi_pan,'ytitle','SEP ion!cchannel'
        endelse
        options,sepi_pan,'panel_size',0.5
      endif else begin
        print,"Missing SEP ion data."
        sepi_pan = ''
      endelse
    endif
    sepi = 0
  endif

; SWIA survey data

  swi_pan = ''
  if keyword_set(swia) then begin
    mvn_swia_load_l2_data, /loadall, /tplot
    mvn_swia_part_moments, type=['cs']
    swi_pan = 'mvn_swics_density'
    options,swi_pan,'ynozero',1
    get_data,'mvn_swics_velocity',data=swi_v,index=i
    if (i gt 0) then begin
      vsw = sqrt(total(swi_v.y^2.,2))
      swi_pan2 = 'mvn_swi_vsw'
      store_data,swi_pan2,data={x:swi_v.x, y:vsw}
      options,swi_pan2,'ytitle','SWIA Vsw!c(km/s)'
      swi_pan = swi_pan + ' ' + swi_pan2
    endif
  endif

; STATIC data

  sta_pan = ''
  if keyword_set(static) then begin
    mvn_sta_l2_load
    mvn_sta_l2_tplot,/replace
    sta_pan = 'mvn_sta_c0_E mvn_sta_c6_M'
  endif

; Assemble the panels and plot

  pans = ram_pan + ' ' + sun_pan + ' ' + alt_pan + ' ' + swi_pan + ' ' + $
         sta_pan + ' ' + mag_pan + ' ' + sepi_pan + ' ' + sepe_pan + ' ' + $
         pad_pan + ' ' + engy_pan

  tplot, pans

  return

end
