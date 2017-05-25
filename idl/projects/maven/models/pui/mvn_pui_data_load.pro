;20160404 Ali
;loads PFP data for use by MAVEN pickup ion model
;to be called by mvn_pui_model

pro mvn_pui_data_load,do3d=do3d,nomag=nomag,noswia=noswia,noswea=noswea,nostatic=nostatic,nosep=nosep,noeuv=noeuv,nospice=nospice

if ~keyword_set(nomag) then begin
  mvn_mag_load,'L2_1sec' ;load MAG data

  ylim,'mvn_B_1sec',-10,10
  options,'mvn_B_1sec','colors','bgr'
endif

if ~keyword_set(noswia) then begin
  mvn_swia_load_l2_data,/loadmom,/loadspec,loadcoarse=do3d,/eflux,/tplot,qlevel=0.1 ;load SWIA data

  ylim,'mvn_swim_density',.01,100,1
  ylim,'mvn_swim_velocity_mso',100,-800
  options,'mvn_swim_velocity_mso','colors','bgr'
  ylim,'mvn_swis_en_eflux',25,25e3
  zlim,'mvn_swis_en_eflux',1e3,1e8
  options,'mvn_swis_en_eflux','ytickunits','scientific'
endif

if ~keyword_set(nostatic) then begin
  mvn_sta_l2_load,sta_apid='c0' ;load STATIC 1D spectra
;  mvn_sta_l2_tplot ;store STATIC data in tplot variables
;  ylim,'mvn_swim_swi_mode',0,1 ;because mvn_sta_l2_tplot messes with 'mvn_swim_swi_mode' !!!
  if keyword_set(do3d) then mvn_sta_l2_load,sta_apid=['d0','d1'] ;load STATIC 3D spectra

;  ylim,'mvn_sta_c0_?_E',1,32e3,1
;  zlim,'mvn_sta_c0_?_E',1e3,1e8,1
;  options,'mvn_sta_c0_att','panel_size',.5
;  options,'mvn_sta_c0_mode','panel_size',.5
endif

if ~keyword_set(nosep) then begin
  mvn_sep_var_restore,units_name='Rate',/basic_tags ;load SEP data
  ;cdf2tplot,mvn_pfp_file_retrieve('maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v??_r??.cdf',/daily),prefix='SepAnc_' ;sep ancillary data

;  ylim,'mvn_sep?_?-?_Rate_Energy',10,1e3
;  zlim,'mvn_sep?_?-?_Rate_Energy',.1,1e4
;  options,'mvn_sep?_?-?_Rate_Energy','panel_size',1
  options,'mvn_sep?_?-*_Rate_Energy','ytickunits','scientific'
  options,'mvn_sep?_?-*_Rate_Energy','ztickunits','scientific'
  options,'mvn_sep?_svy_DURATION','ylog',1
  options,'mvn_sep?_svy_DURATION','panel_size',.5
  options,'mvn_sep?_svy_DURATION','colors','r'
endif

if ~keyword_set(noeuv) then begin
  mvn_euv_l3_load ;load FISM data
  mvn_euv_load ;load EUVM data

  ylim,'mvn_euv_data',1e-5,1e-2,1
  options,'mvn_euv_data','colors','bgr'
endif

if ~keyword_set(nospice) then begin
  ;mvn_spice_load ;load spice kernels
  kernels=mvn_spice_kernels(/all,/clear)
  spice_kernel_load,kernels,verbose=3
  maven_orbit_tplot,colors=[4,6,2],/loadonly ;loads the color-coded orbit info
endif

if ~keyword_set(noswea) then begin
  mvn_swe_load_l2,/spec ;load SWEA spec data
  mvn_swe_sumplot,eph=0,orb=0,/loadonly ;plot SWEA data, without calling maven_orbit_tplot, changing orbnum tplot variable, or plotting anything!
;  tlimit,/full ;revert back to full time period, since swea may change tlimit to its available trange
  mvn_swe_sc_pot ;calculate the spacecraft potential from SWEA data

  zlim,'swe_a4',1e4,1e9
  store_data,'swea_a4_pot',data='swe_a4 mvn_swe_sc_pot'
  ylim,'swea_a4_pot',3.,5e3,1
  options,'swea_a4_pot','ytickunits','scientific'
endif

end