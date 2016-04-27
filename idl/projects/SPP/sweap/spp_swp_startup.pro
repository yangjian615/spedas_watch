
pro spp_swp_startup, spanai = spanai,$
                     spanae = spanae,$
                     spanb  = spanb


  ;;--------------------------------------------
  ;; Check keywords
  if ~keyword_set(spanai) and $
     ~keyword_set(spanae) and $
     ~keyword_set(spanb)  then begin
     spanai = 1
     spanae = 1
     spanb  = 1
  endif
    
  save=0
 

  ;;--------------------------------------------
  ;; Compile necessary programs
  ;resolve_routine, 'spp_swp_functions'
  ;resolve_routine, 'spp_swp_ptp_pkt_handler'




  ;;############################################
  ;; SETUP SWEM APIDs
  ;;############################################
  
  ;;############################################
  ;; SETUP SWEM APID
  ;;############################################
  ;  spp_apid_data,'340'x,routine='spp_swp_swem_decom',tname='spp_swem_hkp_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'341'x,routine='spp_swp_swem_decom',tname='spp_swem_hkp_crit_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'342'x,routine='spp_swp_swem_decom',tname='spp_swem_memdump_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'343'x,routine='spp_swp_swem_decom',tname='spp_swem_hkp_analog_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'344'x,routine='spp_swp_swem_decom',tname='spp_swem_events_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'345'x,routine='spp_swp_swem_decom',tname='spp_swem_cmdecho_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'346'x,routine='spp_swp_swem_decom',tname='spp_swem_timing_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  ;  spp_apid_data,'347'x,routine='spp_swp_swem_decom',tname='spp_swem_memdwell',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  
  
  spp_apid_data,'340'x,routine='spp_generic_decom',tname='spp_swem_hkp_',   tfields='none',save=save,rt_tags='none',rt_flag=1
  spp_apid_data,'341'x,routine='spp_generic_decom',tname='spp_swem_hkp_crit_',   tfields='none',save=save,rt_tags='none',rt_flag=1
  spp_apid_data,'343'x,routine='spp_generic_decom',tname='spp_swem_hkp_analog_',   tfields='none',save=save,rt_tags='none',rt_flag=1
  spp_apid_data,'344'x,routine='spp_generic_decom',tname='spp_swem_events_',   tfields='none',save=save,rt_tags='none',rt_flag=1
  spp_apid_data,'346'x,routine='spp_generic_decom',tname='spp_swem_timing_',   tfields='none',save=save,rt_tags='none',rt_flag=1

  spp_apid_data,'347'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_priority1',   tfields='UNWRAP',save=save,rt_tags='unwrap',rt_flag=1

  spp_apid_data,'34f'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_priority9',   tfields='UNWRAP',save=save,rt_tags='unwrap',rt_flag=1


  ;;############################################
  ;; SETUP SWEM APIDs
  ;;############################################

  SPC = 1
  IF SPC THEN  BEGIN
    spp_apid_data,'353'x,routine='spp_swp_spc_decom',    tname='spp_spc_353_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
    spp_apid_data,'35E'x,routine='spp_swp_spc_decom',    tname='spp_spc_35E_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
    spp_apid_data,'35F'x,routine='spp_swp_spc_decom',    tname='spp_spc_hkp_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag

  endif






  ;;############################################
  ;; SETUP SPAN-Ai APID
  ;;############################################
  if keyword_set(spanai) then begin

     rt_flag=1

     ;;------------------------------------------------------------------------------------------------------------
     ;; Housekeeping - Rates - Events - Manipulator - Memory Dump
     ;;------------------------------------------------------------------------------------------------------------
     if 0 then begin
        spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_50x',tname='spp_spanai_hkp_',    tfields='*',save=save
        spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_50x',           tname='spp_spanai_rates_',  tfields='*',save=save
        spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',               tname='spp_spanai_events_', tfields='*',save=save
     endif
     if 0 then  begin
        spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_64x',tname='spp_spanai_hkp_',    tfields='*',save=save
        spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_64x',           tname='spp_spanai_rates_',  tfields='*',save=save
        spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',               tname='spp_spanai_events_', tfields='*',save=save  
     endif
     if 0 then begin
        spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_70x',tname='spp_spanai_hkp_',    tfields='*',save=save
        spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_64x',           tname='spp_spanai_rates_',  tfields='*',save=save
        spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',               tname='spp_spanai_events_', tfields='*',save=save
     endif  
     

     if 1 then begin
        spp_apid_data,'3b8'x,routine='spp_generic_decom',                tname='spp_spanai_mem_dump_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3b9'x,routine='spp_swp_spani_event_decom',        tname='spp_spanai_events_',  tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3ba'x,routine='spp_swp_spani_tof_decom',          tname='spp_spanai_tof_',     tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3bb'x,routine='spp_swp_spani_rates_64x_decom',    tname='spp_spanai_rates_',   tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3be'x,routine='spp_swp_spani_slow_hkp_96x_decom', tname='spp_spanai_hkp_',     tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3bf'x,routine='spp_generic_decom',                tname='spp_spanai_fhkp_',    tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     endif



     ;#############################
     ;######### ARCHIVE ###########
     ;#############################

     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     decom_routine_i = 'spp_swp_spani_product_decom2'

     spp_apid_data,'380'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p0_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'381'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p0_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'382'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p0_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'383'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p0_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'384'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p1_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'385'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p1_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'386'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p1_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'387'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p1_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'388'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p2_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'389'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p2_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'38a'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p2_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'38b'x,routine=decom_routine_i,tname='spp_spanai_ar_full_p2_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'38c'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p0_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'38d'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p0_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'38e'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p0_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'38f'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p0_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'390'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p1_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'391'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p1_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'392'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p1_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'393'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p1_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'394'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p2_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'395'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p2_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'396'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p2_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'397'x,routine=decom_routine_i,tname='spp_spanai_ar_targ_p2_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     


     ;#############################
     ;########## SURVEY ###########
     ;#############################


     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'398'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p0_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'399'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p0_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'39a'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p0_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'39b'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p0_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'39c'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p1_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'39d'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p1_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'39e'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p1_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'39f'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p1_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a0'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p2_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a1'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p2_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a2'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p2_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a3'x,routine=decom_routine_i,tname='spp_spanai_sr_full_p2_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'3a4'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p0_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a5'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p0_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a6'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p0_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a7'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p0_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a8'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p1_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3a9'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p1_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3aa'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p1_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3ab'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p1_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3ac'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p2_m0_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3ad'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p2_m1_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3ae'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p2_m2_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3af'x,routine=decom_routine_i,tname='spp_spanai_sr_targ_p2_m3_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     



     
  endif







  ;;############################################
  ;; SETUP SPAN-Ae APID
  ;;############################################
  if keyword_set(spanae) then begin

     rt_flag = 1
     decom_routine = 'spp_swp_spane_product_decom2'


     ;;----------------------------------------------------------------------------------------------------------------------------------
     ;; Product Decommutators
     ;;----------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'360'x ,routine=decom_routine,tname='spp_spane_a_ar_full_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'361'x ,routine=decom_routine,tname='spp_spane_a_ar_full_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'362'x ,routine=decom_routine,tname='spp_spane_a_ar_targ_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'363'x ,routine=decom_routine,tname='spp_spane_a_ar_targ_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

     spp_apid_data,'364'x ,routine=decom_routine,tname='spp_spane_a_sr_full_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'365'x ,routine=decom_routine,tname='spp_spane_a_sr_full_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'366'x ,routine=decom_routine,tname='spp_spane_a_sr_targ_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'367'x ,routine=decom_routine,tname='spp_spane_a_sr_targ_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Memory Dump
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36d'x ,routine='spp_generic_decom',tname='spp_spane_a_dump_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Slow Housekeeping
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36e'x ,routine='spp_swp_spane_slow_hkp_v4dx_decom',tname='spp_spane_a_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; Fast Housekeeping
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36f'x ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spane_a_fast_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     

  endif



  ;;############################################
  ;; SETUP SPAN-B APID
  ;;############################################
  if keyword_set(spanb) then begin
     
     ;if n_elements(save) eq 0 then save=0
     rt_flag = 1

     ;;----------------------------------------------------------------------------------------------------------------------------------
     ;; Product Decommutators
     ;;----------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'370'x ,routine=decom_routine,tname='spp_spane_b_ar_full_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'371'x ,routine=decom_routine,tname='spp_spane_b_ar_full_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'372'x ,routine=decom_routine,tname='spp_spane_b_ar_targ_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'373'x ,routine=decom_routine,tname='spp_spane_b_ar_targ_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

     spp_apid_data,'374'x ,routine=decom_routine,tname='spp_spane_b_sr_full_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'375'x ,routine=decom_routine,tname='spp_spane_b_sr_full_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'376'x ,routine=decom_routine,tname='spp_spane_b_sr_targ_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'377'x ,routine=decom_routine,tname='spp_spane_b_sr_targ_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'370'x ,routine=decom_routine,tname='spp_spane_b_ar_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'371'x ,routine=decom_routine,tname='spp_spane_b_ar_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'372'x ,routine=decom_routine,tname='spp_spane_b_ar_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'373'x ,routine=decom_routine,tname='spp_spane_b_ar_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

;     spp_apid_data,'374'x ,routine=decom_routine,tname='spp_spane_b_sr_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'375'x ,routine=decom_routine,tname='spp_spane_b_sr_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'376'x ,routine=decom_routine,tname='spp_spane_b_sr_p0_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
;     spp_apid_data,'377'x ,routine=decom_routine,tname='spp_spane_b_sr_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag


     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Memory Dump
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'37d'x ,routine='spp_generic_decom',tname='spp_spane_b_dump_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Slow Housekeeping
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'37e'x ,routine='spp_swp_spane_slow_hkp_v4dx_decom',tname='spp_spane_b_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; Fast Housekeeping
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'37f'x ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spane_b_fast_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
  endif






  ;;############################################
  ;; SETUP GSE APID
  ;;############################################
  spp_apid_data,'7c1'x,routine='spp_power_supply_decom',tname='HV_',       tfields='*',     save=save,rt_tags='*_?',   rt_flag=1
  spp_apid_data,'7c0'x,routine='spp_log_msg_decom',     tname='log_',      tfields='MSG',   save=save,rt_tags='MSG',   rt_flag=1
  spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',tname='spp_manip_',tfields='*',name='SWEAP SPAN-I Manip',rt_tags='M???POS',save=1,/rt_flag


  spp_apid_data,apdata=ap
  print_struct,ap
  
  ;;------------------------------
  ;; Connect to GSEOS
  spp_init_realtime
  
  store_data,'APID',data='APIDS_*'
  ylim,'APID',820,960
  tplot_options,'wshow',0
  

end
