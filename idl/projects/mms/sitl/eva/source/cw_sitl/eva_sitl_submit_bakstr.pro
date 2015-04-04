PRO eva_sitl_submit_bakstr, tlb, TESTING

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
  tai_BAKStr_org = lorg.unix_BAKStr_org
  str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
  str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
  tai_BAKStr_mod = lmod.unix_BAKStr_mod
  str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
  str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
  
  ;------------------
  ; Modification Check
  ;------------------
  diff = eva_sitl_strct_comp(tai_BAKStr_mod, tai_BAKstr_org); (0) Not equal (1) Equal
  if strmatch(diff,'unchanged') then begin
    msg = "The back-structure has not been modified at all."
    msg = [msg,'EVA cannot submit unmodified back-structure.']
    answer = dialog_message(msg,/info,/center,title=title)
    return
  endif
  
  ;------------------
  ; Validation
  ;------------------
  vsp = '////////////////////////////'
  header = [vsp+' NEW SEGMENTS '+vsp]
  r = eva_sitl_validate(tai_BAKStr_mod, -1, vcase=1, header=header, /quiet); Validate New Segs
  header = [r.msg,' ', vsp+' MODIFIED SEGMENTS '+vsp]
  r2 = eva_sitl_validate(tai_BAKStr_mod, tai_BAKStr_org, vcase=2, header=header); Validate Modified Seg

  ct_err = r.error.COUNT+r2.error.COUNT
  if ct_err ne 0 then begin
    if ct_err eq 1 then mmm=' error exists.' else mmm=' errors exist.'
    msg = strtrim(string(ct_err),2)+mmm+' Submission aborted.'
    answer = dialog_message(msg,/center,title=title)
    return
  endif
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
  local_dir = module_state.PREF.EVA_DATA_DIR+'sitl_data/'
  found = file_test(local_dir); check if the directory exists
  if not found then file_mkdir, local_dir
  

  if TESTING then begin
    problem_status = 0
    msg='TEST MODE: The modified BAKStr was not sent to SDC.'
    rst = dialog_message(msg,/information,/center,title=title)
  endif else begin
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
    if problem_status eq 0 then begin
      msg='The back-structure was sent successfully to SDC.'
      rst = dialog_message(msg,/information,/center,title=title)
    endif else begin
      msg='Submission Failed.'
      rst = dialog_message(msg,/error,/center,title=title)
    endelse
    ptr_free, mod_error_times, new_error_times, orange_warning_times, yellow_warning_times
    ptr_free, mod_error_indices, new_error_indices, orange_warning_indices, yellow_warning_indices
  endelse

  
END
