

pro spp_init_realtime,filename=filename,base=base,SWEMGSE=SWEMGSE,hub=hub,itf=itf

;  common spp_crib_com, recorder_base1,recorder_base2,exec_base
  
  exec, exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1'
  
  if n_elements(hub) eq 0 then hub = 1
  if keyword_set(itf) then begin
    recorder,title='SWEM ITF', port= hub ? 8082 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='spp_itf_stream_read' ;,  destination='spp_raw_YYYYMMDD_hhmmss.ptp'
    return
  endif
  if keyword_set(swemgse) then begin
    recorder,title='SWEMGSE', port= hub ? 8081 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='spp_ptp_stream_read' ;,  destination='spp_raw_YYYYMMDD_hhmmss.ptp'
    return
  endif
  host = 'localhost'
  host = '128.32.98.101'
  host = 'ABIAD-SW.ssl.berkeley.edu'
  recorder,title='GSEOS PTP ion', port=2028, host='ABIAD-SW.ssl.berkeley.edu', exec_proc='spp_ptp_stream_read';,  destination='spp_raw_YYYYMMDD_hhmmss.ptp'
  recorder,title='GSEOS PTP elec',port=2128, host='ABIAD-SW.ssl.berkeley.edu', exec_proc='spp_ptp_stream_read';,  destination='spp_raw_YYYYMMDD_hhmmss.ptp'
  
  printdat,recorder_base,filename,exec_base,/value
  
  ;spp_swp_apid_data_init,save=1
  ;spp_apid_data,'3b9'x,name='SWEAP SPAN-I Events',rt_tags='*'
  ;spp_apid_data,'3bb'x,name='SWEAP SPAN-I Rates',rt_tags='*CNTS'
  ;spp_apid_data,'3be'x,name='SWEAP SPAN-I HKP',rt_tags='*'
  ;spp_apid_data, rt_flag = 1
  ;spp_swp_manip_init
  ;wait,1
  
  ;spp_swp_set_tplot_options
  
  ;;--------------------------------------------------
  ;; Useful command to see what APIDs have been loaded
  ;spp_apid_data,apdata=ap
  ;print_struct,ap
  ;;-------------------------------------------------

  if 0 then begin
     f1= file_search('spp*.ptp')
     spp_apid_data,rt_flag=0
     spp_ptp_file_read,f1[-1]
     spp_apid_data,rt_flag=1
  endif
;  base = recorder_base

end
