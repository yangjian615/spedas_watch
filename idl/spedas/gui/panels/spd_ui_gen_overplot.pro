;+
;NAME:
;  spd_ui_gen_overplot
;
;PURPOSE:
;  Widget wrapper for spd_ui_overplot used to create SPEDAS overview plots in
;  the GUI.  If the overview plot is successfully created, this function returns
;  the number 1.  Otherwise, a zero is returned.
;
;CALLING SEQUENCE:
;  success = spd_ui_gen_overplot(gui_id, historyWin, oplot_calls, callSequence,$
;                                windowStorage,windowMenus,loadedData,drawObject)
;
;INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;  oplot_calls:  The number calls to spd_ui_gen_overplot
;  callSequence: object that stores sequence of procedure calls that was used to load data
;  windowStorage: standard windowStorage object
;  windowMenus: standard menu object
;  loadedData: standard loadedData object
;  drawObject: standard drawObject object
;  
;KEYWORDS:
;  none
;
;OUTPUT:
;  success: a 0-1 flag.
;  
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/panels/spd_ui_gen_overplot.pro $
;-----------------------------------------------------------------------------------

pro spd_ui_gen_overplot_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error while generating SPEDAS overview plot'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    dprint,  'Generate SPEDAS overview plot widget killed' 
    state.historyWin->Update,'SPD_UI_GEN_OVERPLOT: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'SPD_UI_GEN_OVERPLOT: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'APPLY': BEGIN
    ; Check whether times set in widget are valid
    timeid = widget_info(event.top, find_by_uname='time')
    widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
    if valid then begin
      state.tr_obj->getproperty, starttime=starttime, endtime=endtime
      starttime->getproperty, tdouble=st_double
      endtime->getproperty, tdouble=et_double
      dur = (et_double - st_double) / 86400
      if dur le 0 then begin
        etxt = 'End Time is earlier than Start Time.'
        ok = dialog_message(etxt,title='Error while generating SPEDAS overview plot', /center, information=1)
        
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif
       
      widget_control, /hourglass
      
      if ~state.windowStorage->add(isactive=1) then begin
        ok = spd_ui_prompt_widget(state.tlb,state.statusbar,state.tlb,prompt='Error initializing new window for SPEDAS overview plot.', $
               title='Error while generating SPEDAS overview plot',/traceback, frame_attr=8)
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif  
      
      activeWindow = state.windowStorage->GetActive()
    
      ; add window name to gui window menu
      activeWindow[0]->GetProperty, Name=name
      state.windowMenus->Add, name
      state.windowMenus->Update, state.windowStorage
   
      spd_ui_overplot, state.windowStorage,state.loadedData,state.drawObject,$
                       probes=state.probe, date=st_double, dur=dur, $
                       oplot_calls=state.oplot_calls,error=error
                     
      if ~error then begin               
        state.callSequence->addLoadOver,state.probe,st_double,dur,*state.oplot_calls           
        *state.oplot_calls = *state.oplot_calls + 1 ; update # of calls to overplot
        *state.success = 1
      endif
      
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      return
    endif else ok = dialog_message('Invalid Start/End time, please use: YYYY-MM-DD/hh:mm:ss', $
                                   /center)
    END
    'CANC': BEGIN
      state.historyWin->update,'Generate SPEDAS overview plot canceled',/dontshow
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'KEY': begin
      spd_ui_overplot_key, state.gui_id, state.historyWin, /modal
    end
    'PROBE:A': state.probe='a'
    'PROBE:B': state.probe='b'
    'PROBE:C': state.probe='c'
    'PROBE:D': state.probe='d'
    'PROBE:E': state.probe='e'
    'TIME': ;nothing to implement at this time
;    'STARTCAL': begin
;      widget_control, state.trcontrols[0], get_value= val
;      start=spd_ui_timefix(val)
;      state.tr_obj->getproperty, starttime = start_time       
;      if ~is_string(start) then start_time->set_property, tstring=start
;      spd_ui_calendar, 'Choose date/time: ', start_time, state.gui_id
;      start_time->getproperty, tstring=start
;      widget_control, state.trcontrols[0], set_value=start
;    end
;    'STOPCAL': begin
;      widget_control, state.trcontrols[1], get_value= val
;      endt=spd_ui_timefix(val)
;      state.tr_obj->getproperty, endtime = end_time       
;      if ~is_string(endt) then end_time->set_property, tstring=endt
;      spd_ui_calendar, 'Choose date/time: ', end_time, state.gui_id
;      end_time->getproperty, tstring=endt
;      widget_control, state.trcontrols[1], set_value=endt
;    end
;    'TSTART': begin ; Start Time entry box
;      widget_control,event.id,get_value=value
;      t0 = spd_ui_timefix(value)
;      If(is_string(t0)) Then Begin
;;get both times for limit checking
;          state.tr_obj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
;          state.tr_obj->GetProperty, endTime=et   ;et is endtime object
;;set start time value
;          st->SetProperty, tstring = value
;;return a warning if the time range is less than zero, or longer than 1 week
;          et->getproperty, tdouble=t1
;          st->getproperty, tdouble=t0
;          state.validTime = 1
;       Endif else state.validTime = 0
;    end
;    'TEND': begin ; End Time entry box
;      widget_control,event.id,get_value=value
;      t0 = spd_ui_timefix(value)
;      If(is_string(t0)) Then Begin
;          state.tr_obj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
;          state.tr_obj->GetProperty, endTime=et ;et is endtime object (spd_ui_time__define)
;;Set end time value
;          et->SetProperty, tstring = value
;;return a warning if the time range is less than zero, or longer than 1 week
;          et->getproperty, tdouble=t1
;          st->getproperty, tdouble=t0
;          state.validTime = 1
;      Endif else state.validTime = 0
;    end
    ELSE: dprint,  'Not yet implemented'
  ENDCASE
  
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end


;returns 1 if overplot generated and 0 otherwise
function spd_ui_gen_overplot, gui_id, historyWin, statusbar, oplot_calls,callSequence,$
                              windowStorage,windowMenus,loadedData,drawObject,tr_obj=tr_obj

  compile_opt idl2

  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO Begin
      print, err_msg[j]
      If(obj_valid(historywin)) Then historyWin -> update, err_msg[j]
    Endfor
    Print, 'Error--See history'
    ok = error_message('An unknown error occured while starting the SPEDAS overview plot widget. ', $
         'See console for details.', /noname, /center, title='Error in SPEDAS overview plots')
    spd_gui_error, gui_id, historywin
    RETURN,0
  ENDIF
  
  tlb = widget_base(/col, title='Generate SPEDAS Overview Plot', group_leader=gui_id, $
          /floating, /base_align_center, /tlb_kill_request_events, /modal)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1, space=4)
    txtBase = widget_base(mainbase, /Col, /align_center)
    probeBase = widget_base(mainBase, /row)
      probeLabel = widget_label(probeBase, value='Probe:  ', /align_left)
      probeButtonBase = widget_base(probeBase, /row, /exclusive)
    midBase = widget_base(mainBase, /Row)
      trvalsBase = Widget_Base(midBase, /Col, Frame=1, xpad=8)
;        tstartBase = Widget_Base(trvalsBase, /Row, tab_mode=1)
;        tendBase = Widget_Base(trvalsBase, /Row, tab_mode=1)
      keyButtonBase = widget_button(midBase, Value=' Plot Key ', UValue='KEY', XSize=80, $
                                    tooltip = 'Displays detailed descriptions of overview plot panels.')
    buttonBase = Widget_Base(mainBase, /row, /align_center)

; Help text
  wj = widget_label(txtbase, value='Creating the overview plot might take a few minutes.', /align_left)

; Probe selection widgets
  aButton = widget_button(probeButtonBase, value='A(P5)', uvalue='PROBE:A')
  bButton = widget_button(probeButtonBase, value='B(P1)', uvalue='PROBE:B')
  cButton = widget_button(probeButtonBase, value='C(P2)', uvalue='PROBE:C')
  dButton = widget_button(probeButtonBase, value='D(P3)', uvalue='PROBE:D')
  eButton = widget_button(probeButtonBase, value='E(P4)', uvalue='PROBE:E')
  
  widget_control, aButton, /set_button
  probe='a'

; Time range-related widgets
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  if ~obj_valid(tr_obj) then begin
    st_text = '2007-03-23/00:00:00.0'
    et_text = '2007-03-24/00:00:00.0'
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif


  timeWidget = spd_ui_time_widget(trvalsBase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                  uvalue='TIME',uname='time');, oneday=1 
  
;  tstartLabel = Widget_Label(tstartBase,Value='Start Time: ')
;  geo_struct = widget_info(tstartlabel,/geometry)
;  labelXSize = geo_struct.scr_xsize
;  tstartText = Widget_Text(tstartBase, Value=st_text, /Editable, /Align_Left, /All_Events, $
;                           UValue='TSTART')
;  startcal = widget_button(tstartbase, val = cal, /bitmap, tab_mode=0, uval='STARTCAL', uname='startcal', $
;                           tooltip='Choose date/time from calendar.')
;  tendLabel = Widget_Label(tendBase,Value='End Time: ', xsize=labelXSize)
;  tendText = Widget_Text(tendBase,Value=et_text, /Editable, /Align_Left, /All_Events, $
;                         UValue='TEND')
;  stopcal = widget_button(tendbase, val = cal, /bitmap, tab_mode=0, uval='STOPCAL', uname='stopcal', $
;                          tooltip='Choose date/time from calendar.')
  trControls=[timewidget]

; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='  Apply   ', UValue='APPLY', XSize=80)
  cancelButton = Widget_Button(buttonBase, Value='  Cancel  ', UValue='CANC', XSize=80)

  success = ptr_new(0)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           trControls:trControls, tr_obj:tr_obj, $
           probe:probe,success:success, oplot_calls:oplot_calls, $
           validTime:1,callSequence:callSequence,$;validTime doesn't seem to be used anymore
           windowStorage:windowStorage,windowMenus:windowMenus,$
           loadedData:loadedData,drawObject:drawObject}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_gen_overplot', tlb, /No_Block

  RETURN,*success
end
