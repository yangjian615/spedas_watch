PRO eva_sitl_submit_FOMStr, tlb

  ; initialize 
  title = 'FOM Submission'
  
  ; FOM structures
  get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dmod
  get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dorg
  mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
  mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference

  
  ; Modification check
  diff = eva_sitl_strct_comp(tai_FOMstr_mod, tai_FOMstr_org);
  if strmatch(diff,'unchanged') then begin
    msg = "The FOM structure has not been modified at all."
    msg = [msg,'Woud you still like to submit?']
    answer = dialog_message(msg,/question,/center,title=title)
    if strcmp(answer,'No') then return
  endif
  
  ; Validation by Rick's program
  problem_status = 0; 0 means 'no error'
  mms_check_fom_structure, tai_FOMstr_mod, tai_FOMstr_org, $
    error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
    error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
    error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
    error_indices,orange_warning_indices,yellow_warning_indices; Error Indices (ptr_arr)
  type_errors = where(error_flags gt 0, count_errors)
  type_orange_warnings = where(orange_warning_flags gt 0, count_orange)
  type_yellow_warnings = where(yellow_warning_flags gt 0, count_yellow)
   
  ; Error Handler
  if count_errors gt 0 then begin
    eva_sitl_validate_handler, count_errors, title=title & return
  endif
    
  ; Warning Handler
  if count_orange+count_yellow gt 0 then begin
    
    ; find orange and yellow segments
    seg_index_yellow = eva_sitl_validate_getsegs(yellow_warning_indices)
    seg_index_orange = eva_sitl_validate_getsegs(orange_warning_indices)
    seg_index = [seg_index_yellow, seg_index_orange]
    idx = where((finite(seg_index) and seg_index ge 0),c)
    if c gt 0 then begin
      seg_index = seg_index[idx]; exclude -1 and NaN
      seg_index_combined = seg_index[UNIQ(seg_index, SORT(seg_index))]; uniq and sorted
      ;srcID[idx] = 'SITL'
    endif else begin
      message,'Something is wrong'
    endelse
    
    ; Not-modified but warnings
    if strmatch(diff,'unchanged') then begin
;    if ~modified then begin; Not modified but warnings!!
      msg = "You haven't modified the FOMStr and yet there are warnings."
      msg = [msg, "This is because ABS selection criteria is different from"]
      msg = [msg, "the SITL validation criteria.... Continue?"]
      answer = dialog_message(msg,/question,/center)
      if strcmp(answer,'Yes') then begin; the warned segments are now considered 'modified'
        srcID = tai_FOMStr_mod.sourceID
        srcID[seg_index_combined] = 'SITL'
        str_element,/add, tai_FOMStr_mod,'sourceID', srcID
      endif else return
    endif
    
    ; Comment (UI)
    ready = 0
    msg = ''
    while ~ready do begin ; while NOT ready
      msgA = strtrim(string(count_orange+count_yellow),2)
      msgB = strtrim(string(n_elements(seg_index_combined)),2)
      msg1 = 'You have '+msgA+' types of warnings in '+msgB+' segments. If you still wish to submit'
      msg2 = 'please state your name and the reason for overriding the warnings. '
      desc = [ $
        '0, LABEL,'+msg1+', CENTER',$
        '0, LABEL,'+msg2+', CENTER',$
        '0, TEXT, , LABEL_LEFT=Name (max 27 chars):, WIDTH=32, TAG=name', $
        '0, TEXT, , LABEL_LEFT=Reason:, WIDTH=60,TAG=comment, YSIZE=2', $
        '1, BASE,, ROW', $
        '0, BUTTON, SUBMIT, QUIT,' $
        + 'TAG=OK', $
        '2, BUTTON, Cancel, QUIT']
      if strlen(msg) gt 0 then desc = ['0, LABEL,'+msg+', CENTER',desc]
      form = EVA_CW_FORM(desc, /COLUMN, group_leader=tlb)
      if ~form.OK then begin; if canceled
        return; exit
      endif else begin; if the user chose to override the warnings...
        if (strlen(form.COMMENT) gt 4) and (strlen(form.NAME) gt 4) then begin
          ready = 1; make sure we get a comment
        endif else msg = '!!!!!!!! NAME or REASON was TOO SHORT !!!!!!!!'
      endelse; if ~form.OK
    endwhile; while NOT ready
    
    ; Comment (Store into FOMStr)

    srcID = tai_FOMStr_mod.sourceID
    idx = where(strpos(srcID,'SITL') ge 0, ct_sitl)
    if ct_sitl gt 0 then begin
      cmt = tai_FOMStr_mod.comment
      srcID[idx] = 'SITL:'+form.NAME
      cmt[idx] = form.COMMENT
      str_element,/add,tai_FOMstr_mod,'sourceID',srcID
      str_element,/add,tai_FOMstr_mod,'comment',cmt
    endif
    
  endif else begin ; no warning
    msg = 'No error/warning found. Click "OK" to submit (or "Cancel" to abort).'
    rst = dialog_message(msg,/info,/center,/cancel,title=title); 'OK'
    if ~strmatch(rst,'OK') then return
  endelse; if orange+yellow warnings

  
  
  ; Submit
    
  widget_control, widget_info(tlb,find='eva_data'), GET_VALUE=module_state
  local_dir = module_state.PREF.cache_data_dir+'sitl_data/'
  found = file_test(local_dir); check if the directory exists
  if not found then file_mkdir, local_dir
  
  ;////////////////////////
  TESTING =1 
  ;////////////////////////
  
  if TESTING then begin
    problem_status = 0
    msg='TEST MODE: The modified FOMStr is not sent to SDC.'
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
