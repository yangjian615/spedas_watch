;+
;NAME:
;  spd_ui_init_load_window
;
;PURPOSE:
;  Sets up the window and tab widgets for loading data into the SPEDAS GUI.
;
;CALLING SEQUENCE:
;  spd_ui_init_load_window, gui_id, windowStorage, loadedData, historyWin, $
;                           dataFlag, dataButtons, timerange, treeCopyPtr
;
;INPUT:
;  gui_id:  The id of the main GUI window.
;  windowStorage:  The windowStorage object.
;  loadedData:  The loadedData object.
;  historyWin:  The history window object.
;  dataFlag: 
;  dataButtons: 
;  timerange:  The GUI timerange object.
;  treeCopyPtr:  Pointer variable to a copy of the load widget tree.
;  
;KEYWORDS:
;  none
;
;OUTPUT:
;  none
;-


;Helper function, used to guarantee that the tree is up-to-date.  
pro spd_ui_init_load_update_tree_copy,state

  Compile_Opt idl2, hidden

  tab = widget_info(state.tabBase,/tab_current)
  
  ;angular spectra panel has no data tree 
  ;But can change the contents of the tree. So
  ;tree copy still needs an update when GUI
  ;closes.
  if tab eq 1 then tab=0

  if obj_valid(state.treeArray[tab]) then begin
    *state.treeCopyPtr = state.treeArray[tab]->getCopy()
  endif
end

;restores user selects from previous panel open
pro spd_ui_load_data_set_user_select,state

 widget_control,widget_info(state.tabArray[0],/child),get_uvalue=load_data_state

  if widget_valid(load_data_state.itypeDropList) && (*state.userSelectPtr).inst ne -1 then begin
    widget_control,load_data_state.itypeDroplist,set_combobox_select=(*state.userSelectPtr).inst
  endif
  spd_ui_load_data_file_itype_sel, load_data_state
   
  if widget_valid(load_data_state.coordDropList) && (*state.userSelectPtr).coord ne -1 then begin
    widget_control,load_data_state.coordDropList,set_combobox_select=(*state.userSelectPtr).coord
  endif 
  spd_ui_load_data_file_coord_sel, load_data_state
  
  if widget_valid(load_data_state.observList) && ptr_valid((*state.userSelectPtr).observPtr) && (*(*state.userSelectPtr).observPtr)[0] ne -1 then begin
    widget_control,load_data_state.observList,set_list_select=*(*state.userSelectPtr).observPtr
  endif    
  spd_ui_load_data_file_obs_sel, load_data_state
  
  if widget_valid(load_data_state.level1List) && ptr_valid((*state.userSelectPtr).level1Ptr) && (*(*state.userSelectPtr).level1Ptr)[0] ne -1 then begin
    widget_control,load_data_state.level1List,set_list_select=*(*state.userSelectPtr).level1Ptr
  endif    
  spd_ui_load_data_file_l1_sel, load_data_state
  
  if widget_valid(load_data_state.level2List) && ptr_valid((*state.userSelectPtr).level2Ptr) && (*(*state.userSelectPtr).level2Ptr)[0] ne -1 then begin
    widget_control,load_data_state.level2List,set_list_select=*(*state.userSelectPtr).level2Ptr
  endif    
  spd_ui_load_data_file_l2_sel, load_data_state

  raw_data_widget_id = widget_info(widget_info(state.tabArray[0],/child),find_by_uname='raw_data')
  if widget_valid(raw_data_widget_id) then begin
    widget_control,raw_data_widget_id,set_button=(*state.userSelectPtr).uncalibrated
  endif

  widget_control,widget_info(state.tabArray[0],/child),set_uvalue=load_data_state,/no_copy
end

pro spd_ui_load_data_select_copy,state

  Compile_Opt idl2, hidden

  widget_control,widget_info(state.tabArray[0],/child),get_uvalue=load_data_state

  if ptr_valid(state.userSelectPtr) && is_struct(load_data_state) then begin
     if widget_valid(load_data_state.itypeDroplist) then begin
       (*state.userSelectPtr).inst = where(widget_info(load_data_state.itypeDroplist,/combobox_gettext) eq load_data_state.validItype)
     endif
     
     if widget_valid(load_data_state.coordDropList) then begin
       (*state.userSelectPtr).coord = where(widget_info(load_data_state.coordDropList,/combobox_gettext) eq *load_data_state.validCoords)
     endif
     
     if widget_valid(load_data_state.observList) then begin
       ptr_free,(*state.userSelectPtr).observPtr
       (*state.userSelectPtr).observPtr = ptr_new(widget_info(load_data_state.observList,/list_select))
     endif
     
     if widget_valid(load_data_state.level1List) then begin
       ptr_free,(*state.userSelectPtr).level1Ptr
       (*state.userSelectPtr).level1Ptr = ptr_new(widget_info(load_data_state.level1List,/list_select))
     endif
     
     if widget_valid(load_data_state.level2List) then begin
       ptr_free,(*state.userSelectPtr).level2Ptr
       (*state.userSelectPtr).level2Ptr = ptr_new(widget_info(load_data_state.level2List,/list_select))
     endif
     
     raw_data_widget_id = widget_info(widget_info(state.tabArray[0],/child),find_by_uname='raw_data')
     if widget_valid(raw_data_widget_id) then begin
       (*state.userSelectPtr).uncalibrated = widget_info(raw_data_widget_id,/button_set)
     endif
   endif
       
end

pro spd_ui_init_load_window_event, event

  Compile_Opt idl2, hidden

      ; get the state structure from the widget

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

      ; put a catch here to insure that the state remains defined

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      x=state.gui_id
      histobj=state.historywin
      ;update central tree to reflect last expansion of current tree 
      spd_ui_init_load_update_tree_copy,state
    endif
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
       /noname, /center, title='Error in Load Data')
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    if widget_valid(x) && obj_valid(histobj) then begin 
      spd_gui_error,x,histobj
    endif
    RETURN
  ENDIF
  
  ;kill request block

  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  


    exit_sequence:
;    dprint,  'Load SPEDAS Data widget killed.' 
    state.historyWin->Update,'SPD_UI_INIT_LOAD_WINDOW: Widget closed' 
    ;update central tree to reflect last expansion of current tree 
    spd_ui_init_load_update_tree_copy,state
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 

  ENDIF

  ;update widget tree when new tab is selected
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN
    tab = event.tab
   
    spd_ui_time_widget_update,state.timeArray[tab], $
      oneday= spd_ui_time_widget_is_oneday(state.timeArray[state.previoustab])
    spd_ui_init_load_update_tree_copy,state
    
    widget_control,event.top,tlb_set_title=state.tabTitleText[tab]
    
    ;angular spectra panel has no data tree
    if state.previousTab ne 1 then begin
      if obj_valid(state.treeArray[state.previousTab]) then begin
        *state.treeCopyPtr = state.treeArray[state.previousTab]->getCopy()
      endif
    endif
      
    if tab ne 1 then begin
      if obj_valid(state.treeArray[tab]) then begin
        state.treeArray[tab]->update,from_copy=*state.treeCopyPtr
      endif
    endif
  
    state.previousTab = tab
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    return
  
  endif  
      ; get the uval from this event so we know which widget was used 

  Widget_Control, event.id, Get_UValue=uval
  
  ; check for empty event coming from one of the other event handlers
  if size(uval,/type) eq 0 then begin 
    Widget_Control, event.top, Set_UValue = state, /No_Copy
    RETURN
  endif
  
  state.historywin->update,'SPD_UI_INIT_LOAD_WINDOW: User value: '+uval  ,/dontshow

  CASE uval OF
    'DISMISS':BEGIN
      spd_ui_init_load_update_tree_copy,state
      spd_ui_load_data_select_copy,state
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    ELSE:    
  ENDCASE
  
      ; must ALWAYS reset the state value
      
  Widget_Control, event.top, Set_UValue = state, /No_Copy

  RETURN
end

pro spd_ui_init_load_window, gui_id, windowStorage, loadedData, historyWin, $
                             dataFlag, dataButtons, timerange, treeCopyPtr,userSelectPtr

  compile_opt idl2, hidden
  
  tlb = widget_base(/Col, Title = "Load Data", Group_Leader = gui_id, $
                    /Modal, /Floating, /TLB_KILL_REQUEST_EVENTS)
  tabBase = widget_tab(tlb, location=0, multiline=10)

  getresourcepath,configPath
  restore,filename=configPath+'spd_ui_load_data_config_template.sav' ;restores a saved ascii_template variable named "templ"
  loadDataTabs = read_ascii(configPath+'spd_ui_load_data_config.txt',template=templ,count=tabNum) ;load data api configuration information
  ; if no title was provided then use the tab mission name
  ind = where(loadDataTabs.panel_title eq '', ncnt)
  if ncnt gt 0 then loadDataTabs.panel_title[ind]=loadDataTabs.mission_name[ind]

  if tabNum eq 0 then begin 
    message,'ERROR: No tabs found in config file. Probable config file error' ;use of message to send error here is okay, methinx, 'cause it is serious and will be caught by the parent error handler'
  endif

      ; create a widget base for each tab
  tabArray = make_array(tabNum, /long)
  for i=0,tabNum-1 do begin
      tabArray[i] = widget_base(tabBase, title=loadDataTabs.mission_name[i], $
                           event_pro=loadDataTabs.procedure_name[i])    
  endfor
     
  bottomBase = widget_base(tlb, /Col, YPad=6, /Align_Left)
  
  widget_control, tabBase, set_tab_current=0
    
  ; Create Status Bar Object
  okButton = Widget_Button(bottomBase, Value='Done', XSize=75, uValue='DISMISS', $
    ToolTip='Dismiss Load Panel', /align_center)
  statusText = Obj_New('SPD_UI_MESSAGE_BAR', $
                       Value='Status information is displayed here.', $
                        bottomBase, XSize=135, YSize=1)

  windowStorage->getProperty, callSequence=callSequence
  
  ;At the moment, this saves user preferences only for the main SPEDAS load window.  
  userSelectStruct = $
    {inst:-1,$
     coord:-1,$
     observPtr:ptr_new(-1),$
     level1Ptr:ptr_new(-1),$
     level2Ptr:ptr_new(-1),$
     uncalibrated:0}
   
  if ~ptr_valid(userSelectPtr) then begin
    userSelectPtr = ptr_new(userSelectStruct)
  endif

  treeArray = objarr(tabNum)
  timeArray = lonarr(tabNum)
   
  for i= 0, tabNum-1 do begin

     if (loadDataTabs.mission_name[i] eq 'SPEDAS') then begin   
         spd_ui_load_data_file, tabArray[i], gui_id, windowStorage, loadedData, $
                         historyWin, dataFlag, dataButtons, timerange, statusText, $
                         loadTree=spedasTree,timeWidget=loadTimeWidget,treeCopyPtr
         timeArray[i]=loadTimeWidget
         treeArray[i]=spedasTree
         continue
      endif 

      if (loadDataTabs.mission_name[i] eq 'SPEDAS Derived Spectra') then begin   
         spd_ui_part_getspec_options, tabArray[i], loadedData, historyWin, statusText, $
                               timerange,callSequence,timeWidget=specTimeWidget
         treeArray[i] = obj_new() ;filler obj, should not be referenced 
         timeArray[i] = specTimeWidget
         continue
      endif

      call_procedure, strtrim(loadDataTabs.procedure_name[i]), tabArray[i], loadedData, historyWin, statusText, $
                      treeCopyPtr, timeRange, callSequence,loadTree=thisTreeArray, $
                      timeWidget=otherTimeWidget
      timeArray[i] = otherTimeWidget
      treeArray[i] = thisTreeArray
      
  endfor     
  
  tabTitleText=loadDataTabs.panel_title
                   
  state = {tlb:tlb, gui_id:gui_id,tabBase:tabBase, historyWin:historyWin, statusText:statusText,treeArray:treeArray,timeArray:timeArray,tabArray:tabArray,treeCopyPtr:treeCopyPtr,previousTab:0,tabTitleText:tabTitleText, userSelectPtr:userSelectPtr}

  CenterTLB, tlb
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  Widget_Control, tlb, get_UValue = state, /No_Copy
  spd_ui_load_data_set_user_select,state
  Widget_Control, tlb, set_UValue = state, /No_Copy

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_init_load_window', tlb, /No_Block
 
  RETURN
end
