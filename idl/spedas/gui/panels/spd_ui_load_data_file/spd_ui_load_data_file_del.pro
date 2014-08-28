;+ 
;NAME:
; spd_ui_load_data_file_del.pro
;
;PURPOSE:
; Controls deleting of loaded data from "Loaded Data" list.  Called by
; spd_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; spd_ui_load_data_file_del, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;HISTORY:
;-
pro spd_ui_load_data_file_del, state

  Compile_Opt idl2, hidden
  
  sel = state.loadList->getValue()

  if ptr_valid(sel[0]) then begin
    ; need to track deletions of data using the callsequence object
    state.windowStorage->getProperty, callSequence=callSequence
    
    for i=0, n_elements(sel)-1 do begin
      if ~state.loadedData->remove((*sel[i]).groupname) then begin
        msg = "Problem deleting : " + (*sel[i]).groupname
        state.statusText->Update, msg
        state.historyWin->Update, 'LOAD DATA: ' + msg
        return
      endif else begin
        callSequence->adddeletecall,(*sel[i]).groupname
      endelse
    endfor
    msg = 'Selected data deleted.'
    state.statusText->Update, msg
    state.historyWin->Update, 'LOAD DATA: ' + msg
  endif else begin
    msg='No data selected. Not deleting anything.'
    state.statusText->Update, msg
    state.historyWin->Update, 'LOAD DATA: ' + msg
  endelse
 
  RETURN
END
