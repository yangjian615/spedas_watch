PRO eva_sitl_submit_FOMStr, tlb

  ; initialize 
  title = 'FOM Submission'
    
  ; FOM structures
  get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dmod
  get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dorg
  mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
  mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
  header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
  
  ;------------------
  ; Modification Check
  ;------------------
  diff = eva_sitl_strct_comp(tai_FOMstr_mod, tai_FOMstr_org);
  if strmatch(diff,'unchanged') then begin
    msg = "The FOM structure has not been modified at all."
    msg = [msg,'Woud you still like to submit?']
    answer = dialog_message(msg,/question,/center,title=title)
    if strcmp(answer,'No') then return
  endif
  
  ;------------------
  ; Validation
  ;------------------
  r = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, header=header)
  
  if r.error.COUNT ne 0 then return
  if r.yellow.COUNT ne 0 then begin
    msg = 'An yellow warning exists. Still submit?'
    if r.yellow.COUNT gt 1 then msg = 'Yellow warnings exist. Still submit?'
    answer = dialog_message(msg,/center,/question)
    if strmatch(strlowcase(answer),'no') then return
  endif
  
  ;------------------
  ; Submit
  ;------------------
  widget_control, widget_info(tlb,find='eva_data'), GET_VALUE=module_state
  local_dir = module_state.PREF.cache_data_dir+'sitl_data/'
  found = file_test(local_dir); check if the directory exists
  if not found then file_mkdir, local_dir
  
  ;////////////////////////
  TESTING = 0
  ;////////////////////////
  
  if TESTING then begin
    problem_status = 0
    msg='TEST MODE: The modified FOMStr was not sent to SDC.'
    rst = dialog_message(msg,/information,/center,title=title)
  endif else begin
    mms_put_fom_structure, tai_FOMstr_mod, tai_FOMStr_org, local_dir,$
      error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
      error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
      error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
      error_indices,orange_warning_indices,yellow_warning_indices,$; Error Indices (ptr_arr)
      problem_status, /warning_override
    if problem_status eq 0 then begin
      msg='The FOM structure was sent successfully to SDC.'
      rst = dialog_message(msg,/information,/center,title=title)
    endif else begin
      msg='Submission Failed.'
      rst = dialog_message(msg,/error,/center,title=title)
    endelse
  endelse
  ptr_free, error_times, orange_warning_times, yellow_warning_times
  ptr_free, error_indices, orange_warning_indices, yellow_warning_indices
END
