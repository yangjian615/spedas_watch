

pro spp_init_realtime,filename=filename,base=base,SWEMGSE=SWEMGSE,hub=hub,itf=itf,RM133=RM133,rm320=rm320,rm333=rm333,tent=tent, $
    exec=exec0, elec=elec,ion=ion,tv=tv,cal=cal

;  common spp_crib_com, recorder_base1,recorder_base2,exec_base
  
  
  if n_elements(hub) eq 0 then hub = 1
  
  
  rootdir = root_data_dir() + 'spp/data/sci/sweap/prelaunch/gsedata/realtime/'
  fileformat = 'YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
  fileres =3600.d


  
  if keyword_set(itf) then begin
    recorder,title='SWEM ITF', port= hub ? 8082 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='spp_itf_stream_read' 
    return
  endif
  if keyword_set(swemgse) then begin
    recorder,title='SWEMGSE', port= hub ? 2228 : 2024, host='abiad-sw.ssl.berkeley.edu', exec_proc='spp_ptp_stream_read' 
  endif
  if keyword_set(rm133) then begin
    recorder,title='ROOM 133', port= hub ? 2028 : 2024, host='128.32.13.37', exec_proc='spp_ptp_stream_read'
    return
  endif
  if keyword_set(rm333) then begin
    recorder,title='ROOM 333', port= hub ? 2028 : 2023, host='ssa333-lab.ssl.berkeley.edu', exec_proc='spp_msg_stream_read'
    return
  endif
  if keyword_set(rm320) or keyword_set(cal) then begin
    host = 'abiad-sw.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(ion) then recorder,title='CAL Ion PTP',  port=2028, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spani/',set_file_timeres=fileres
    if keyword_set(elec) then recorder,title='CAL Elec PTP',port=2128, host=host, exec_proc=exec_proc,destination=fileformat,directory=rootdir+'cal/spane/',set_file_timeres=fileres   
  endif
  if keyword_set(tent) or keyword_set(TV) then begin
    host = 'mgse2.ssl.berkeley.edu'
    exec_proc = 'spp_ptp_stream_read'
    if keyword_set(ion)  then recorder,title='TV Ion PTP' ,port=2028, host=host, exec_proc=exec_proc,directory=rootdir+'TVac/spani/',destination=fileformat,set_file_timeres=fileres
    if keyword_set(elec) then recorder,title='TV Elec PTP',port=2128, host=host, exec_proc=exec_proc,directory=rootdir+'TVac/spane/',destination=fileformat,set_file_timeres=fileres
  endif

  if keyword_set(exec0) then begin
    exec, exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1',title=title
  endif
  tplot_options,title='Real time'
  
  spp_swp_startup,/rt_flag
  
  ;spp_swp_set_tplot_options
  
  ;;--------------------------------------------------
  ;; Useful command to see what APIDs have been loaded
  ;spp_apid_data,apdata=ap
  ;print_struct,ap
  ;;-------------------------------------------------

;  base = recorder_base

end
