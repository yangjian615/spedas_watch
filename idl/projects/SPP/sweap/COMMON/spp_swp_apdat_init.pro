
pro spp_swp_apdat_init, save_flag = save_flag, $
                     rt_flag= rt_Flag, $
                     clear = clear


  dprint,dlevel=3,/phelp ,rt_flag,save_flag


  ;; special case to accumulate statistics
  spp_apdat_info, 0 ,name='Stats',apid_obj='spp_gen_apdat_stats',tname='APIDS_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 

  ;;############################################
  ;; SETUP SWEM APIDs
  ;;############################################
  
  
  ttags = 'SEQN'
    
  spp_apdat_info,'340'x,routine='spp_generic_decom',tname='spp_swem_hkp_',   save_tags=ttags,save_flag=save_flag,rt_tags=ttags,rt_flag=rt_flag 
  spp_apdat_info,'341'x,routine='spp_generic_decom',tname='spp_swem_crit_',   save_tags=ttags,save_flag=save_flag,rt_tags=ttags,rt_flag=rt_flag 
  spp_apdat_info,'343'x,routine='spp_generic_decom',tname='spp_swem_ahkp_',   save_tags=ttags,save_flag=save_flag,rt_tags=ttags,rt_flag=rt_flag 
  spp_apdat_info,'344'x,routine='spp_generic_decom',tname='spp_swem_events_',   save_tags=ttags,save_flag=save_flag,rt_tags=ttags,rt_flag=rt_flag 
  spp_apdat_info,'346'x,routine='spp_swp_swem_timing_decom',tname='spp_swem_timing_',   save_tags='*',save_flag=save_flag,rt_tags='*',rt_flag=rt_flag 

  spp_apdat_info,'347'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_347_',   save_tags='*',save_flag=save_flag,rt_tags='*',rt_flag=rt_flag 
  spp_apdat_info,'34e'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_34E_',   save_tags='*',save_flag=save_flag,rt_tags='*',rt_flag=rt_flag 
  spp_apdat_info,'34f'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_34F_',   save_tags='*',save_flag=save_flag,rt_tags='*',rt_flag=rt_flag 


  ;;############################################
  ;; SETUP SPC APIDs
  ;;############################################

  spp_apdat_info,'352'x,routine='spp_swp_spc_decom',    tname='spp_spc_352_',save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'353'x,routine='spp_swp_spc_decom',    tname='spp_spc_353_',save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'35E'x,routine='spp_swp_spc_decom',    tname='spp_spc_35E_',save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'35F'x,routine='spp_swp_spc_decom',    tname='spp_spc_hkp_',save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag 


  ;;############################################
  ;; SETUP SPAN-Ai APID
  ;;############################################

  ;;------------------------------------------------------------------------------------------------------------
  ;; Housekeeping - Rates - Events - Manipulator - Memory Dump
  ;;------------------------------------------------------------------------------------------------------------


  spp_apdat_info,'3b8'x,name='spi_mem_dump',  routine='spp_generic_decom',                tname='spp_spi_mem_dump_',save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3b9'x,name='spi_events',  routine='spp_swp_spani_event_decom',        tname='spp_spi_events_',  save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3ba'x,name='spi_tof',  routine='spp_swp_spani_tof_decom',          tname='spp_spi_tof_',     save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3bb'x,name='spi_rates',  routine='spp_swp_spani_rates_decom',        tname='spp_spi_rates_',   save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3be'x,name='spi_hkp', routine='spp_swp_spani_slow_hkp_9ex_decom', tname='spp_spi_hkp_',     save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3bf'x,name='spi_fhkp',  routine='spp_swp_spani_fast_hkp_decom',     tname='spp_spi_fhkp_',    save_tags='*',rt_tags='*',save_flag=save_flag,rt_flag=rt_flag



     ;#############################
     ;######### ARCHIVE ###########
     ;#############################

     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     decom_routine_i = 'spp_swp_spani_product_decom2'
     decom_routine_obj = 'spp_swp_spi_prod_apdat'
     ;decom_routine_i = 'spp_swp_spani_product_decom'
     ttags = '*SPEC* *CNTS* *DATASIZE'

     spp_apdat_info,'380'x,name='spi_af00',apid_obj=decom_routine_obj,tname='spp_spi_AF00_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'381'x,name='spi_af01',routine=decom_routine_i,tname='spp_spi_AF01_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'382'x,name='spi_af02',routine=decom_routine_i,tname='spp_spi_AF02_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'383'x,name='spi_af03',routine=decom_routine_i,tname='spp_spi_AF03_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'384'x,name='spi_af10',routine=decom_routine_i,tname='spp_spi_AF10_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'385'x,name='spi_af11',routine=decom_routine_i,tname='spp_spi_AF11_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'386'x,name='spi_af12',routine=decom_routine_i,tname='spp_spi_AF12_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'387'x,name='spi_af13',routine=decom_routine_i,tname='spp_spi_AF13_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'388'x,name='spi_af20',routine=decom_routine_i,tname='spp_spi_AF20_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'389'x,name='spi_af21',routine=decom_routine_i,tname='spp_spi_AF21_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'38a'x,name='spi_af22',routine=decom_routine_i,tname='spp_spi_AF22_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'38b'x,name='spi_af23',routine=decom_routine_i,tname='spp_spi_AF23_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'38c'x,routine=decom_routine_i,tname='spp_spi_AT00_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'38d'x,routine=decom_routine_i,tname='spp_spi_AT01_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'38e'x,routine=decom_routine_i,tname='spp_spi_AT02_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'38f'x,routine=decom_routine_i,tname='spp_spi_AT03_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'390'x,routine=decom_routine_i,tname='spp_spi_AT10_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'391'x,routine=decom_routine_i,tname='spp_spi_AT11_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'392'x,routine=decom_routine_i,tname='spp_spi_AT12_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'393'x,routine=decom_routine_i,tname='spp_spi_AT13_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'394'x,routine=decom_routine_i,tname='spp_spi_AT20_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'395'x,routine=decom_routine_i,tname='spp_spi_AT21_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'396'x,routine=decom_routine_i,tname='spp_spi_AT22_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'397'x,routine=decom_routine_i,tname='spp_spi_AT23_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     


     ;#############################
     ;########## SURVEY ###########
     ;#############################


     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'398'x,routine=decom_routine_i,tname='spp_spi_SF00_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'399'x,routine=decom_routine_i,tname='spp_spi_SF01_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'39a'x,routine=decom_routine_i,tname='spp_spi_SF02_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'39b'x,routine=decom_routine_i,tname='spp_spi_SF03_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'39c'x,routine=decom_routine_i,tname='spp_spi_SF10_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'39d'x,routine=decom_routine_i,tname='spp_spi_SF11_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'39e'x,routine=decom_routine_i,tname='spp_spi_SF12_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'39f'x,routine=decom_routine_i,tname='spp_spi_SF13_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a0'x,routine=decom_routine_i,tname='spp_spi_SF20_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a1'x,routine=decom_routine_i,tname='spp_spi_SF21_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a2'x,routine=decom_routine_i,tname='spp_spi_SF22_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a3'x,routine=decom_routine_i,tname='spp_spi_SF23_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'3a4'x,routine=decom_routine_i,tname='spp_spi_ST00_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a5'x,routine=decom_routine_i,tname='spp_spi_ST01_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a6'x,routine=decom_routine_i,tname='spp_spi_ST02_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a7'x,routine=decom_routine_i,tname='spp_spi_ST03_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a8'x,routine=decom_routine_i,tname='spp_spi_ST10_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3a9'x,routine=decom_routine_i,tname='spp_spi_ST11_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3aa'x,routine=decom_routine_i,tname='spp_spi_ST12_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3ab'x,routine=decom_routine_i,tname='spp_spi_ST13_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3ac'x,routine=decom_routine_i,tname='spp_spi_ST20_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3ad'x,routine=decom_routine_i,tname='spp_spi_ST21_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3ae'x,routine=decom_routine_i,tname='spp_spi_ST22_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'3af'x,routine=decom_routine_i,tname='spp_spi_ST23_',save_tags=ttags,rt_tags=ttags,save_flag=save_flag,rt_flag=rt_flag 
     


  ;;############################################
  ;; SETUP SPAN-Ae APID
  ;;############################################
  spe_hkp_tags = 'RIO_???* ADC_*_* *_FLAG MRAM* CLKS_PER_NYS ALL_ADC EASIC_DAC *CMD_* PEAK*'



  decom_routine = 'spp_swp_spane_product_decom2'
  decom_routine_obj = 'spp_swp_spe_prod_apdat'

  ttags = '*'

  ;;----------------------------------------------------------------------------------------------------------------------------------
  ;; Product Decommutators
  ;;----------------------------------------------------------------------------------------------------------------------------------
  spp_apdat_info,'360'x,name='spa_af0' ,apid_obj=decom_routine_obj,tname='spp_spa_AF0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'361'x,name='spa_af1' ,apid_obj=decom_routine_obj,tname='spp_spa_AF1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'362'x,name='spa_at0' ,apid_obj=decom_routine_obj,tname='spp_spa_AT0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'363'x,name='spa_at1' ,apid_obj=decom_routine_obj,tname='spp_spa_AT1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 

  spp_apdat_info,'364'x,name='spa_sf0' ,apid_obj=decom_routine_obj,tname='spp_spa_SF0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'365'x,name='spa_sf1' ,apid_obj=decom_routine_obj,tname='spp_spa_SF1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'366'x,name='spa_st0' ,apid_obj=decom_routine_obj,tname='spp_spa_ST0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'367'x,name='spa_st1' ,apid_obj=decom_routine_obj,tname='spp_spa_ST1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 


  ;;----------------------------------------------------------------------------------------------------------------------------------------
  ;; Memory Dump
  ;;----------------------------------------------------------------------------------------------------------------------------------------
  spp_apdat_info,'36d'x ,routine='spp_generic_decom',tname='spp_spa_memdump_',save_tags='SEQN',rt_tags='SEQN', save_flag=save_flag,rt_flag=rt_flag 

  ;;----------------------------------------------------------------------------------------------------------------------------------------
  ;; Slow Housekeeping
  ;;----------------------------------------------------------------------------------------------------------------------------------------
  spp_apdat_info,'36e'x, name='spa_hkp' ,routine='spp_swp_spane_slow_hkp_v52x_decom',tname='spp_spa_hkp_',save_tags=spe_hkp_tags,rt_tags=spe_hkp_tags, save_flag=save_flag,rt_flag=rt_flag  

  ;;-----------------------------------------------------------------------------------------------------------------------------------------
  ;; Fast Housekeeping
  ;;-----------------------------------------------------------------------------------------------------------------------------------------
  spp_apdat_info,'36f'x, name='spa_fhkp' ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spa_fhkp_',save_tags='*',rt_tags='*', save_flag=save_flag,rt_flag=rt_flag 




  ;;############################################
  ;; SETUP SPAN-B APID
  ;;############################################
     
     ;;----------------------------------------------------------------------------------------------------------------------------------
     ;; Product Decommutators
     ;;----------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'370'x,name='spb_af0' ,apid_obj=decom_routine_obj,tname='spp_spb_AF0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'371'x,name='spb_af1' ,apid_obj=decom_routine_obj,tname='spp_spb_AF1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'372'x,name='spb_at0' ,apid_obj=decom_routine_obj,tname='spp_spb_AT0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'373'x,name='spb_at1' ,apid_obj=decom_routine_obj,tname='spp_spb_AT1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 

     spp_apdat_info,'374'x,name='spb_sf0' ,apid_obj=decom_routine_obj,tname='spp_spb_SF0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'375'x,name='spb_sf1' ,apid_obj=decom_routine_obj,tname='spp_spb_SF1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'376'x,name='spb_st0' ,apid_obj=decom_routine_obj,tname='spp_spb_ST0_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 
     spp_apdat_info,'377'x,name='spb_st1' ,apid_obj=decom_routine_obj,tname='spp_spb_ST1_',save_tags=ttags,rt_tags=ttags, save_flag=save_flag,rt_flag=rt_flag 

     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Memory Dump
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'37d'x ,routine='spp_generic_decom',tname='spp_spb_dump_',save_tags='*',rt_tags='*', save_flag=save_flag,rt_flag=rt_flag 
     
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Slow Housekeeping
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'37e'x ,name='spb_hkp',routine='spp_swp_spane_slow_hkp_v52x_decom',tname='spp_spb_hkp_',save_tags=spe_hkp_tags,rt_tags=spe_hkp_tags, save_flag=save_flag,rt_flag=rt_flag 

     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; Fast Housekeeping
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apdat_info,'37f'x ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spb_fhkp_',save_tags='*',rt_tags='*', save_flag=save_flag,rt_flag=rt_flag 
     


  ;;############################################
  ;; SETUP GSE APID
  ;;############################################
  spp_apdat_info,'751'x,name='aps1' ,routine='spp_power_supply_decom',tname='APS1_',   save_tags='*P25?',  save_flag=save_flag,rt_tags='*P25?',   rt_flag=rt_flag 
  spp_apdat_info,'752'x,name='aps2' ,routine='spp_power_supply_decom',tname='APS2_',   save_tags='*P25?',  save_flag=save_flag,rt_tags='*P25?',   rt_flag=rt_flag 
  spp_apdat_info,'753'x,name='aps3' ,routine='spp_power_supply_decom',tname='APS3_',   save_tags='*P6? *N25V',  save_flag=save_flag,rt_tags='*P6? *N25V',   rt_flag=rt_flag 
  spp_apdat_info,'754'x,name='aps4' ,routine='spp_power_supply_decom',tname='APS4_',   save_tags='P25?',  save_flag=save_flag,rt_tags='P25?',   rt_flag=rt_flag 
  spp_apdat_info,'755'x,name='aps5' ,routine='spp_power_supply_decom',tname='APS5_',   save_tags='P25?',   save_flag=save_flag,rt_tags='P25?',   rt_flag=rt_flag
  spp_apdat_info,'761'x,name='bertan1' ,routine='spp_power_supply_decom',tname='Igun_',  save_tags='*VOLTS *CURRENT',  save_flag=save_flag,rt_tags='*VOLTS *CURRENT',   rt_flag=rt_flag 
  spp_apdat_info,'762'x,name='bertan2',routine='spp_power_supply_decom',tname='Egun_',    save_tags='*VOLTS *CURRENT',  save_flag=save_flag,rt_tags='*VOLTS *CURRENT',   rt_flag=rt_flag 
  spp_apdat_info,'7c0'x,name='log_msg',routine='spp_log_msg_decom'     ,tname='log_',    save_tags='MSG',   save_flag=save_flag,rt_tags='MSG',   rt_flag=rt_flag 
  spp_apdat_info,'7c3'x,name='manip', routine='spp_swp_manip_decom'   ,tname='manip_',save_tags='*POS',rt_tags='*POS',save_flag=save_flag,rt_flag=rt_flag 
  spp_apdat_info,'7c4'x,name='swemulator', apid_obj='spp_swp_swemulator_apdat'   ,tname='swemul_tns_',save_tags='F0 MET',rt_tags='F0 MET',save_flag=save_flag,rt_flag=rt_flag


  if keyword_set(clear) then spp_apdat_info,/clear
  
   

end
