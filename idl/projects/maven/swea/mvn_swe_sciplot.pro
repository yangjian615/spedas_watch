;+
;PROCEDURE: 
;	mvn_swe_sciplot
;PURPOSE:
;	Creates an science-oriented summary plot for SWEA and optionally other instruments.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_sciplot
;INPUTS:
;   None:      Uses data currently loaded into the SWEA common block.
;
;KEYWORDS:
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-10-11 15:12:14 -0700 (Sun, 11 Oct 2015) $
; $LastChangedRevision: 19047 $
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
  if (i gt 0) then pad_pan = tname else pad_pan = 'swe_a2_280'

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
  mvn_mag_tplot
  
  mag_pan = 'mvn_mag_bamp mvn_mag_bang'

; SEP electron and ion data - sum all look directions for both units

  sepe_pan = ''
  sepi_pan = ''
  if keyword_set(sep) then begin
    mvn_sep_load

    get_data,'mvn_SEP1F_elec_eflux',data=sepe,dl=dlim,index=i
    if (i gt 0) then begin
      v = reform(sepe.v[0,*])
      sepe = 0
      sepe_pan = 'mvn_SEP_elec_eflux'
      add_data,'mvn_SEP1F_elec_eflux','mvn_SEP1R_elec_eflux',newname='mvn_SEP1_elec_eflux'
      add_data,'mvn_SEP2F_elec_eflux','mvn_SEP2R_elec_eflux',newname='mvn_SEP2_elec_eflux'
      add_data,'mvn_SEP1_elec_eflux','mvn_SEP2_elec_eflux',newname=sepe_pan
      get_data,sepe_pan,data=sepe,index=i
      if (i gt 0) then begin
        sepe = {x:sepe.x, y:sepe.y/4., v:v}
        store_data,sepe_pan,data=sepe,dl=dlim
        ylim,sepe_pan,20,200,1
        options,sepe_pan,'ytitle','SEP elec!ckeV'
        options,sepe_pan,'panel_size',0.5
      endif else begin
        print,"Missing SEP electron data."
        sepe_pan = ''
      endelse
      sepe = 0
    endif

    get_data,'mvn_SEP1F_ion_eflux',data=sepi,dl=dlim,index=i
    if (i gt 0) then begin
      v = reform(sepi.v[0,*])
      sepi = 0
      sepi_pan = 'mvn_SEP_ion_eflux'
      add_data,'mvn_SEP1F_ion_eflux','mvn_SEP1R_ion_eflux',newname='mvn_SEP1_ion_eflux'
      add_data,'mvn_SEP2F_ion_eflux','mvn_SEP2R_ion_eflux',newname='mvn_SEP2_ion_eflux'
      add_data,'mvn_SEP1_ion_eflux','mvn_SEP2_ion_eflux',newname=sepi_pan
      get_data,sepi_pan,data=sepi,index=i
      if (i gt 0) then begin
        sepi = {x:sepi.x, y:sepi.y/4., v:v}
        store_data,sepi_pan,data=sepi,dl=dlim
        ylim,sepi_pan,20,6000,1
        options,sepi_pan,'ytitle','SEP ion!ckeV'
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
