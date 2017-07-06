;+
; NAME:
;  secs_ui_quicklook_plots
;
; PURPOSE:
;  Widget wrapper for secs_quicklook_plots used to view secs quicklook plots on the web
;
; CALLING SEQUENCE:
;  success = secs_ui_quicklook_plots(gui_id, historyWin, oplot_calls, callSequence,$
;                                windowStorage,windowMenus,loadedData,drawObject)
;
; INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;  oplot_calls:  The number calls to secs_ui_gen_overplot
;  callSequence: object that stores sequence of procedure calls that was used to load data
;  windowStorage: standard windowStorage object
;  windowMenus: standard menu object
;  loadedData: standard loadedData object
;  drawObject: standard drawObject object
;  
;
; OUTPUT:
;  none
;  
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-01-23 19:30:24 -0800 (Fri, 23 Jan 2015) $
;$LastChangedRevision: 16723 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/spedas_plugin/secs_ui_gen_overplot.pro $
;-

pro secs_ui_quicklook_plots_event, event

  Compile_Opt hidden
 
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error while generating SECS quicklook plot'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    dprint,  'Generate SECS Quicklook plots widget killed' 
    state.historyWin->Update,'SECS_UI_QUICKLOOK_PLOTS: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'SECS_UI_QUICKLOOK_PLOTS: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'GOWEB': BEGIN
      timeid = widget_info(event.top, find_by_uname='time')
      widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      if valid then begin
        state.tr_obj->getproperty, starttime=starttime, endtime=endtime
        starttime->getproperty, year=year, month=month, date=date, hour=hour, min=min, sec=sec
        ; For some reason, the & cannot be sent as part of the URL. So we are going to use a single string variable that will be split by PHP.
        datepath = string(year, format='(I04)') + "/" + string(month, format='(I02)') + "/" + string(date, format='(I02)') + "/"
        filename = 'ThemisSEC'+ string(year, format='(I04)') + string(month, format='(I02)') + string(date, format='(I02)') + "_" + $
          string(hour, format='(I02)') + string(min, format='(I02)') + string(sec, format='(I02)') + '.jpeg'
        url = !secs.remote_data_dir + "Quicklook/" + datepath + "/"+filename
        spd_ui_open_url, url
      endif else begin
        ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
          /center)   
      endelse

     end
     
    'DONE': BEGIN
      state.historyWin->update,'Generate secs overview plot canceled',/dontshow
      state.statusBar->Update,'Generate secs overview plot canceled.'
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END

    'CHECK_DATA_AVAIL': begin
      spd_ui_open_url, 'http://vmo.igpp.ucla.edu/data1/SECS/Quicklook'
    end

    'KEY': begin
      ok = dialog_message('Key not yet avaiable.', $
        /center)
      ;spd_ui_overplot_key, state.gui_id, state.historyWin, /modal, secs=fix(state.probe)
    end

    ELSE: 
  ENDCASE
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end


pro secs_ui_quicklook_plots, gui_id = gui_id, $
                          history_window = historyWin, $
                          status_bar = statusbar, $
                          call_sequence = callSequence, $
                          time_range = tr_obj, $
                          window_storage = windowStorage, $
                          loaded_data = loadedData, $
                          data_structure = data_structure, $
                          _extra = _extra

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
    ok = error_message('An unknown error occured starting widget to generate SECS quicklook plots. ', $
         'See console for details.', /noname, /center, title='Error while generating SECS quicklook plots')
    spd_gui_error, gui_id, historywin
    RETURN
  ENDIF
  
  tlb = widget_base(/col, title='View SECS Quicklook Plots', group_leader=gui_id, $
          /floating, /base_align_center, /tlb_kill_request_events, /modal)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1, space=4)
    txtBase = widget_base(mainbase, /Col, /align_center)
    goWebLabel = widget_label(txtBase, Value='NOTE: SECS Plots are available per minute.  ', /align_left)
    midBase = widget_base(mainBase, /Row)
      trvalsBase = Widget_Base(midBase, /Col, Frame=1, xpad=8)
      keyButtonBase = widget_button(midBase, Value='Plot Key', UValue='KEY', XSize=80, $
                                    tooltip = 'Displays detailed descriptions of secs overview plot panels.')
    goWebBase = Widget_Base(mainBase, /Row, xpad=8, /align_center)
    buttonBase = Widget_Base(mainBase, /row, /align_center)
    davailabilitybutton = widget_button(goWebBase, val = ' Check Data Availability', $
      uval = 'CHECK_DATA_AVAIL', /align_center, $
      ToolTip = 'Check data availability on the web')
    goWebButton = Widget_Button(goWebBase, Value='  View Web Plot  ', UValue='GOWEB', XSize=80)
    
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
                                  uvalue='TIME',uname='time', startyear = 1995);, oneday=1 
  

; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='Done', UValue='DONE', XSize=80)

  ;flag denoting successful run
  success = 0

  ;initialize structure to store variables for future calls
  if ~is_struct(data_structure) then begin
    data_structure = { oplot_calls:0, track_one:0b }
  endif

  data_ptr = ptr_new(data_structure)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           tr_obj:tr_obj, success:ptr_new(success), data:data_ptr, $
           callSequence:callSequence,windowStorage:windowStorage,$
           loadedData:loadedData}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'secs_ui_quicklook_plots', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  RETURN
end
