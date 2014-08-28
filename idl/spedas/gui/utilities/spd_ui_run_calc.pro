;+ 
;NAME:
; spd_ui_run_calc
;
;PURPOSE:
; Function that interprets program for spd_ui_calculate
;
;CALLING SEQUENCE:
; spd_ui_run_calc,programtext,loadeddata,historywin,statusbar,error=error
;
;INPUT:
; programText: array of strings, text of program
; loadeddata: the loaded data object
; historywin: the historywin object
; statusbar: the statusbar object
;
;OUTPUT:
; error=error: set to named variable, will be 0 on success, will be set to error struct returned by calc.pro on failure
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_run_calc.pro $
;
;---------------------------------------------------------------------------------


pro spd_ui_run_calc,programtext,loadeddata,historywin,statusbar,gui_id,error=error,replay=replay,overwrite_selections=overwrite_selections,overwrite_count=overwrite_count,calc_prompt_obj=calc_prompt_obj

  compile_opt hidden,idl2
  
  pi = !DPI
  e = exp(1)
  
  error = 0


  ;list of names so that we can delete any newly created names
  tn_before = tnames()
  
  for i = 0,n_elements(programtext)-1 do begin
  
    ;widget_control,state.programLabel,set_value="Calculating line: " + strtrim(string(i),2)
    
    statusBar->update,'Calculating line: ' + strtrim(string(i),2)
    historyWin->update,'Calculating line: ' + strtrim(string(i),2)
    
    if keyword_set(programtext[i]) then begin
      calc,programtext[i],gui_data_obj=loadedData,error=error,historywin=historywin,statusbar=statusbar,gui_id=gui_id,overwrite_selections=overwrite_selections,overwrite_count=overwrite_count,replay=replay,calc_prompt_obj=calc_prompt_obj
    endif
    
    if keyword_set(error) then begin
    
      break
    
    endif
  
  endfor


  ;list of names after processing
  spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
  
end
