Function eva_sitl_load_soca_getfom, pref, parent
  compile_opt idl2

  ;////////////////////////////////////
  local_dir = !MMS.LOCAL_DATA_DIR
  TESTMODE  = pref.EVA_TESTMODE
  ;/////////////////////////////////////
  
  get_latest_fom_from_soc, fom_file, error_flag, error_msg
  
  if TESTMODE then begin
    ; 'dir' produces the directory name with a path separator character that can be OS dependent.
    local_dir = file_search(ProgramRootDir(/twoup)+'data',/MARK_DIRECTORY,/FULLY_QUALIFY_PATH); directory
    fom_file = local_dir + 'abs_selections_sample.sav'
  endif
  
  if error_flag AND (TESTMODE eq 0) then begin
    msg='FOMStr not found in SDC. Ask Super SITL.'
    print,'EVA: '+msg
    result=dialog_message(msg,/center)
    unix_FOMstr = error_flag
  endif else begin
    if strlen(fom_file) eq 0 then message, 'Something is wrong in get_latest_fom_from_soc'
    restore,fom_file
    mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
    print,'EVA: fom_file = '+fom_file
    nmax = unix_FOMStr.Nsegs
    discussion = strarr(nmax)
    discussion[0:nmax-1] = ' '
    str_element,/add,unix_FOMStr,'discussion',discussion
    
    ;---- update cw_sitl label ----
    nmax = n_elements(unix_FOMstr.timestamps)
    start_time = time_string(unix_FOMstr.timestamps[0],precision=3)
    end_time = time_string(unix_FOMstr.timestamps[nmax-1],precision=3)
    lbl = ' '+start_time+' - '+end_time
    print,'EVA: updating cw_sitl target_time label:'
    print,'EVA: '+ lbl
    id_sitl = widget_info(parent, find_by_uname='eva_sitl')
    sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
    WIDGET_CONTROL, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY
    widget_control, sitl_state.lblTgtTimeMain, SET_VALUE=lbl
    WIDGET_CONTROL, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY
  endelse
  
  return, unix_FOMstr
END