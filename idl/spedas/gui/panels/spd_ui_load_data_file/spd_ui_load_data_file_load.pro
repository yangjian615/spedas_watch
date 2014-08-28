;+ 
;NAME:
; spd_ui_load_data_file_load.pro
;
;PURPOSE:
; Loads SPEDAS data by calling spd_ui_load_data_fn.  Called by
; spd_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; spd_ui_load_data_file_load, state, event
;
;INPUT:
; state     State structure
; event     Event structure
;
;OUTPUT:
; None
;
;HISTORY:
;-
pro spd_ui_load_data_file_load, state, event

  Compile_Opt idl2, hidden
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      x=state.gui_id
      histobj=state.historywin
    endif
    if !error_state.name eq 'THM_SPINMODEL_POST_PROCESS_NO_TVAR' then begin
            h = 'LOAD DATA: ' +!error_state.msg + $
                ". There's probably no data for the requested date."
       ok=dialog_message(h,/error)
       return
    endif else begin
       Print, 'Error--See history'
       ok=error_message('An unknown error occured while loading data. See console for details.',$
          /noname, /center, title='Error in Load Data')
       RETURN
    endelse
  ENDIF
  
  outcoord = state.outcoord
  If(ptr_valid(state.dtyp)) Then dtype = *state.dtyp $
  Else If(ptr_valid(state.dtyp_pre)) Then dtype = *state.dtyp_pre $
  Else Begin
    ;widget_control, event.top, set_uval = state, /no_copy
    spd_ui_update_progress, event.top, 'Please Choose a data type'
    Return
  Endelse
  
  if array_equal(dtype,'',/no_typeconv) then begin
    h='Please choose a data type.'
    state.statusText->Update, h
    return
  endif
  
  If(ptr_valid(state.station)) Then station = *state.station $
    Else station = ''
  If(ptr_valid(state.astation)) Then astation = *state.astation $
    Else astation = ''
  If(ptr_valid(state.probe)) Then probe = *state.probe $
    Else probe = ''

  If(state.instr Eq 'asi' Or state.instr Eq 'ask') Then Begin
    if ~is_string(astation) then begin
      h = 'No Chosen Asi_station'
      state.statusText->Update, h
      return
    endif
  Endif Else If(state.instr Eq 'gmag') Then Begin
    if ~is_string(station) then begin
      h = 'No Chosen Gmag_station'
      state.statusText->Update, h
      return
    endif
  Endif Else Begin
    if ~is_string(probe) then begin      
    ;h = 'probe = '+''''+''''
      h = 'No Chosen Probe'
      state.statusText->Update, h
      return
    endif
  Endelse

  state.tr->getproperty, starttime=startt
  state.tr->getproperty, endtime=stopt
  startt->getproperty, tdouble=t0
  stopt->getproperty, tdouble=t1
  ;t0 = state.st_time & t1 = state.en_time
  ;progobj = state.progobj
  ;widget_control, event.top, set_uval = state, /no_copy
  ;test for time range...
  If(t0 Eq 0.0 Or t1 Eq 0.0) Then Begin
    spd_ui_update_progress, event.top, 'Please Choose a Time Range'
    Return
  Endif
  
  ;test for too looong of a time range:
;  dt_all = t1 - t0
;
;  ask_l1 = strpos(dtype, 'ask/l1')
;  ask_test = where(ask_l1 ne -1, nask_test)
;  if(nask_test gt 0) then begin
;    
;    ;number of julian days that cover time range
;    days = floor(t1/86400)-floor(t0/86400.)+1
;    dataObjSize = days *  
;    cdfSize = 
;  endif


;  asf_l1 = strpos(dtype, 'asf/l1')
;  asf_test = where(asf_l1 Ne -1, nasf_test)
;  If(nasf_test Gt 0) Then Begin
;    ttest = 7.0*3600.0d0
;    txt_m = 'THIS IS A LONG TIME RANGE FOR ASF DATA. DO YOU REALLY WANT TO LOAD THE DATA?'
;  Endif Else Begin
;    ttest = 7.0*24.0*3600.0d0
;    txt_m = 'THIS IS A LONG TIME RANGE. DO YOU REALLY WANT TO LOAD THE DATA?'
;  Endelse
;  ;A widget for a question
;  If(dt_all Gt ttest) Then Begin
;    ppp = yesno_widget_fn(title = 'test', label = txt_m)
;  Endif Else ppp = 1b
;  If(ppp Eq 0) Then Begin
;    spd_ui_update_progress, event.top, 'Load Operation Cancelled'
;    Return
;  Endif
;  h1 = 'varnames = spd_ui_load_data_fn('+ $
;    ''''+time_string(t0)+''''+', '+ $
;    ''''+time_string(t1)+''''+', '+ $
;    'dtype=dtyp, station=station, astation=asi_station, probe=probe)'

  state.windowStorage->getProperty, callSequence=callSequence

  raw_id = widget_info(state.tab_id,find_by_uname='raw_data')
  raw = widget_info(raw_id,/button_set)

  ;special case for scm, need to pass in calibration parameters
  if (strlowcase(strmid(dtype[0],0,3)) eq 'scm') then Begin

    spd_ui_load_data2obj, t0, t1, dtype = dtype, $
                              outcoord = outcoord, $
                              observ = *state.observ, $
                              raw=raw,$ 
                              loadedData = state.loadedData, $
                              historywin = state.historyWin, $
                              statustext = state.statusText, $
                              state_gui_id = state.tab_id, $ ;using tab id so that overwrite messages will layer correctly
                              loadedVarList = loadedVarList,$
                              overwrite_selections=overwrite_selections
     
     ; store load_data2obj call on windowStorage
     callSequence->addloadcall, t0, t1, dtype, *state.observ, outcoord,raw,overwrite_selections
  endif else Begin
    spd_ui_load_data2obj, t0, t1, dtype = dtype, $
                              outcoord = outcoord, $
                              observ = *state.observ, $
                               raw=raw,$
                              loadedData = state.loadedData, $
                              historywin = state.historyWin, $
                              statustext = state.statusText, $
                              state_gui_id = state.tab_id, $ ;using tab id so that overwrite messages will layer correctly
                              loadedVarList = loadedVarList,$
                              overwrite_selections=overwrite_selections
    
    ; store load_data2obj call on windowStorage
    callSequence->addloadcall, t0, t1, dtype, *state.observ, outcoord,raw,overwrite_selections
  endelse
 
  if is_string(loadedVarList) then begin
  
    state.loadList->update,selected=loadedVarList
  
  endif
 
  RETURN
END
