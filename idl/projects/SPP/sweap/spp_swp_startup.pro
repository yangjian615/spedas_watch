
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
     

  ;;--------------------------------------------
  ;; Compile necessary programs
  resolve_routine, 'spp_swp_functions'
  resolve_routine, 'spp_swp_ptp_pkt_handler'



  ;;############################################
  ;; SETUP SPAN-Ai APID
  ;;############################################
  if spanai then begin

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
        spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',                      tname='spp_manip_',         tfields='*',save=save
     endif  

     if 1 then begin
        spp_apid_data,'3ba'x,routine='spp_swp_spani_tof_decom',                 tname='spp_spani_tof_',   tfields='*',save=save

        spp_apid_data,'3be'x,routine='spp_swp_spani_slow_hkp_84x_decom',        tname='spp_spani_hkp_',   tfields='*',save=save
        ;spp_apid_data,'3be'x,routine='spp_swp_spani_slow_hkp_decom_version_84x', tname='spp_spani_hkp_',     tfields='*',save=save

        spp_apid_data,'3bf'x,routine='spp_generic_decom',                        tname='spp_spani_fhkp_',tfields='*',save=save
        spp_apid_data,'3bf'x,routine='spp_generic_decom',                        tname='spp_spani_fhk_',     tfields='*',save=save

        spp_apid_data,'3bb'x,routine='spp_swp_spani_rates_64x_decom',           tname='spp_spani_rates_', tfields='*',save=save
        ;spp_apid_data,'3bb'x,routine='spp_swp_spani_rates_decom_64x',            tname='spp_spani_rates_',   tfields='*',save=save

        spp_apid_data,'3b9'x,routine='spp_swp_spani_event_decom',                tname='spp_spani_events_',  tfields='*',save=save
        ;spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',               tname='spp_spanai_events_',tfields='*',save=save

        spp_apid_data,'3b8'x,routine='spp_generic_decom',                        tname='spp_spani_mem_dump_',tfields='*',save=save
        spp_apid_data,'3b8'x,routine='spp_generic_decom',                        tname='spp_spani_mem_dump_',tfields='*',save=save
     endif
     
     ;spp_spani_product_init

     ;;------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;------------------------------------------------------------------------------------------------------------
     spp_apid_data,'380'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m1_',tfields='*',save=save
     spp_apid_data,'381'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m2_',tfields='*',save=save
     spp_apid_data,'382'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m3_',tfields='*',save=save
     spp_apid_data,'383'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m4_',tfields='*',save=save
     spp_apid_data,'384'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m1_',tfields='*',save=save
     spp_apid_data,'385'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m2_',tfields='*',save=save
     spp_apid_data,'386'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m3_',tfields='*',save=save
     spp_apid_data,'387'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m4_',tfields='*',save=save
     spp_apid_data,'388'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m1_',tfields='*',save=save
     spp_apid_data,'389'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m2_',tfields='*',save=save
     spp_apid_data,'38a'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m3_',tfields='*',save=save
     spp_apid_data,'38b'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m4_',tfields='*',save=save
     
     ;;------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;------------------------------------------------------------------------------------------------------------
     spp_apid_data,'38c'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m1_',tfields='*',save=save
     spp_apid_data,'38d'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m2_',tfields='*',save=save
     spp_apid_data,'38e'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m3_',tfields='*',save=save
     spp_apid_data,'38f'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m4_',tfields='*',save=save
     spp_apid_data,'390'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m1_',tfields='*',save=save
     spp_apid_data,'391'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m2_',tfields='*',save=save
     spp_apid_data,'392'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m3_',tfields='*',save=save
     spp_apid_data,'393'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m4_',tfields='*',save=save
     spp_apid_data,'394'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m1_',tfields='*',save=save
     spp_apid_data,'395'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m2_',tfields='*',save=save
     spp_apid_data,'396'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m3_',tfields='*',save=save
     spp_apid_data,'397'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m4_',tfields='*',save=save
     
     
  endif
     
     

  


  ;;############################################
  ;; SETUP SPAN-Ae APID
  ;;############################################
  if spanae then begin

     ;if n_elements(save) eq 0 then save=0
     rt_flag = 1
     save = 1

     ;;----------------------------------------------------------------------------------------------------------------------------------
     ;; Product Decommutators
     ;;----------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'360'x ,routine='spp_swp_spane_product_decom',tname='spp_spane_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'361'x ,routine='spp_swp_spane_product_decom',tname='spp_spane_p2_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'362'x ,routine='spp_swp_spane_product_decom',tname='spp_spane_p3_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     spp_apid_data,'363'x ,routine='spp_swp_spane_product_decom',tname='spp_spane_p4_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Memory Dump
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36d'x ,routine='spp_generic_decom',tname='spp_spane_dump_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Slow Housekeeping
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36e'x ,routine='spp_swp_spane_slow_hkp_v3d_decom',tname='spp_spane_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; Fast Housekeeping
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36f'x ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spane_fast_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     

  endif

  ;;############################################
  ;; SETUP SPAN-B APID
  ;;############################################
  if spanb then begin
     
     print, 'No SPAN-B APID'
     
  endif



  ;;############################################
  ;; SETUP Generic APID
  ;;############################################
  spp_apid_data,'7c1'x,routine='spp_power_supply_decom',tname='HV_',       tfields='*',     save=0,rt_tags='*_?',   rt_flag=1
  spp_apid_data,'34f'x,routine='spp_swp_swem_unwrapper',tname='unwrap_',   tfields='UNWRAP',save=0,rt_tags='unwrap',rt_flag=1
  spp_apid_data,'7c0'x,routine='spp_log_msg_decom', tname='log_',      tfields='MSG',   save=1,rt_tags='MSG',   rt_flag=1
  spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',   tname='spp_manip_',tfields='*',     save=1,rt_tags='MANIP', rt_flag=1




  spp_apid_data,apdata=ap
  print_struct,ap
  




  ;;------------------------------
  ;; Connect to GSEOS
  spp_init_realtime

end
