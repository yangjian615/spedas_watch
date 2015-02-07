Function eva_sitl_load_soca_getfom, CACHE_DATA_DIR, parent
  compile_opt idl2
  @moka_logger_com
  
  local_dir = cache_data_dir+'abs_data/'
  
  get_latest_fom_from_soc, local_dir, fom_file, error_flag, error_message
  
  if error_flag then begin
    msg='FOMStr not found in SDC. Ask Super SITL.'
    log.o,msg
    result=dialog_message(msg,/center)
    unix_FOMstr = error_flag
  endif else begin
    if strlen(fom_file) eq 0 then message, 'Something is wrong in get_latest_fom_from_soc'
    restore,fom_file
    mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
    log.o,'fom_file = '+fom_file
    nmax = unix_FOMStr.Nsegs
    comment = strarr(nmax)
    comment[0:nmax-1] = ''
    str_element,/add,unix_FOMStr,'comment',comment
    
    ;//////////////////////////////////////
;    fom_file = local_dir + 'abs_selections_2014-03-07-22-07-35.sav'
;    restore, fom_file ; retrieves 'FOMstr'
;    mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
    ;//////////////////////////////////////
    
    ;---- update cw_sitl label ----
    nmax = n_elements(unix_FOMstr.timestamps)
    start_time = time_string(unix_FOMstr.timestamps[0],precision=3)
    end_time = time_string(unix_FOMstr.timestamps[nmax-1],precision=3)
    lbl = ' '+start_time+' - '+end_time
    log.o,'updating cw_sitl target_time label:'
    log.o, lbl
    id_sitl = widget_info(parent, find_by_uname='eva_sitl')
    sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
    WIDGET_CONTROL, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY
    widget_control, sitl_state.lblTgtTimeMain, SET_VALUE=lbl
    WIDGET_CONTROL, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY
  endelse
  
  return, unix_FOMstr
END