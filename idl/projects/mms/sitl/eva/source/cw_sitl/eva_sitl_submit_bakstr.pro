PRO eva_sitl_submit_bakstr, tlb

  ; initialize
  title = 'Back Structure Submission'

  ; Check for BAK structures
  tn = tnames()
  idx = where(strmatch(tn,'mms_stlm_bakstr'),ct)
  if ct eq 0 then begin
    msg = 'Back-Structure not found. If you wish to'
    msg = [msg, 'submit a FOM structure, please disable the back-']
    msg = [msg, 'structure mode.']
    rst = dialog_message(msg,/error,/center,title=title)
    return
  endif
  
  ; BAK structures
  get_data,'mms_stlm_bakstr',data=Dmod, lim=lmod,dl=dmod
  get_data,'mms_soca_bakstr',data=Dorg, lim=lorg,dl=dorg
  
  ; UNIX to TAI
  tai_BAKStr_org = lorg.unix_BAKStr_org
  str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
  str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
  tai_BAKStr_mod = lmod.unix_BAKStr_mod
  str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
  str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
  
  ; Modification check
  modified = ~eva_sitl_strct_comp(tai_BAKStr_mod, tai_BAKstr_org); (0) Not equal (1) Equal
  if ~modified then begin
    msg = "The back-structure has not been modified at all."
    msg = [msg,'EVA cannot submit unmodified back-structure.']
    answer = dialog_message(msg,/info,/center,title=title)
    return
  endif
  
  ;===========================================
  ; Validation by Rick (existing segments)

  mms_back_structure_check_modifications, tai_BAKStr_mod, tai_BAKStr_org, $
    mod_error_flags, mod_warning_flags, $
    mod_error_msg,   mod_warning_msg,   $
    mod_error_times, mod_warning_times, $
    mod_error_indices, mod_warning_indices
  type_mod_errors   = where(mod_error_flags gt 0, count_errors)
  type_mod_warnings = where(mod_warning_flags gt 0, count_warnings) 
  if count_errors gt 0 then begin
    eva_sitl_validate_handler, count_errors, title=title, $
      desc = '(in existing back-structure segments)' & return
  endif
  if count_warnings gt 0 then begin
    eva_sitl_validate_handler, count_warnigs, title=title,/warning,$
      desc = '(in existing back-structure segments)' & return
  endif

  
  ;=============================================
  ; Validation by Rick (new segments)
  
  mms_back_structure_check_new_segments, tai_BAKStr_mod, new_segs, $
    new_error_flags, orange_warning_flags, yellow_warning_flags, $
    new_error_msg,   orange_warning_msg,   yellow_warning_msg, $
    new_error_times, orange_warning_times, yellow_warning_times, $
    new_error_indices, orange_warning_indices, yellow_warning_indices
  type_new_errors      = where(new_error_flags gt 0, count_errors)
  type_orange_warnings = where(orange_warning_flags gt 0, count_orange)
  type_yellow_warnings = where(yellow_warning_flags gt 0, count_yellow)
  if count_errors gt 0 then begin
    eva_sitl_validate_handler, count_errors, title=title, $
      desc = '(in new back-structure segments)' & return
  endif
  if count_orange gt 0 then begin
    eva_sitl_validate_handler, count_orange, title=title,/warning,$
      desc = '(in new back-structure segments)' & return
  endif
  if count_yellow gt 0 then begin
    eva_sitl_validate_handler, count_yellow, title=title,/warning,$
      desc = '(in new back-structure segments)' & return
  endif

  ;=============================================
  ; Submission by Rick
  
  widget_control, widget_info(tlb,find='eva_data'), GET_VALUE=module_state
  local_dir = module_state.PREF.cache_data_dir+'sitl_data/'
  found = file_test(local_dir); check if the directory exists
  if not found then file_mkdir, local_dir
  
  mms_put_back_structure, tai_BAKStr_mod, tai_BAKStr_org, local_dir, $
    mod_error_flags,   mod_warning_flags, $
    mod_error_msg,     mod_warning_msg,   $
    mod_error_times,   mod_warning_times, $
    mod_error_indices, mod_warning_indices, $
    new_segs, $
    new_error_flags,   orange_warning_flags,   yellow_warning_flags, $
    new_error_msg,     orange_warning_msg,     yellow_warning_msg, $
    new_error_times,   orange_warning_times,   yellow_warning_times, $
    new_error_indices, orange_warning_indices, yellow_warning_indices, $
    problem_status,    /warning_override
  
  ;problem_status = 0
  
  if problem_status eq 0 then begin
    msg='The back-structure was sent successfully to SDC.'
    rst = dialog_message(msg,/information,/center,title=title)
  endif else begin
    msg='Submission Failed.'
    rst = dialog_message(msg,/error,/center,title=title)
  endelse
  ptr_free, mod_error_times, new_error_times, orange_warning_times, yellow_warning_times
  ptr_free, mod_error_indices, new_error_indices, orange_warning_indices, yellow_warning_indices
END
