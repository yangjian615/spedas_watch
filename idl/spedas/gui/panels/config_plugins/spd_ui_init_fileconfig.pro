;+
;NAME:
;  spd_ui_init_fileconfig
;
;PURPOSE:
;  Sets up the window and tab widgets for changing configuration files
;  in the SPEDAS GUI.
;
;CALLING SEQUENCE:
;  spd_ui_init_fileconfig, gui_id, historyWin
;
;INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;  
;KEYWORDS:
;  none
;
;OUTPUT:
;  none
;-


;restores user selects from previous panel open
pro spd_ui_init_fileconfig_set_user_select,state

 widget_control,widget_info(state.tabArray[0],/child),get_uvalue=config_state

  if widget_valid(config_state.localDir) && (*state.userSelectPtr).localDir ne '' then begin
    widget_control,config_state.localDir,set_value=(*state.userSelectPtr).localDir
  endif
 
  if widget_valid(config_state.remoteDir) && (*state.userSelectPtr).remoteDir ne '' then begin
    widget_control,config_state.remoteDir,set_value=(*state.userSelectPtr).remoteDir
  endif

end


pro spd_ui_init_fileconfig_event, event

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
      ;spd_ui_init_load_update_tree_copy,state
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
    state.historyWin->Update,'SPD_UI_INIT_FILECONFIG: Widget closed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF

  ;update widget tree when new tab is selected
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN
    tab = event.tab  
    state.previousTab = tab    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    RETURN
  ENDIF
      ; get the uval from this event so we know which widget was used 

  Widget_Control, event.id, Get_UValue=uval
  
  ; check for empty event coming from one of the other event handlers
  if size(uval,/type) eq 0 then begin 
    Widget_Control, event.top, Set_UValue = state, /No_Copy
    RETURN
  endif
  
  state.historyWin->update,'SPD_UI_INIT_FILECONFIG: User value: '+uval  ,/dontshow

  CASE uval OF
    'DISMISS':BEGIN
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

pro spd_ui_init_fileconfig,  gui_id,  historyWin                       
                           
  ; create the base widget for this tab
  tlb = widget_base(/col, Title = "Configuration Settings", Group_Leader = gui_id, $
                    /Modal, /Floating, /TLB_KILL_REQUEST_EVENTS)
  tabBase = widget_tab(tlb, location=0, multiline=10)
    
  ; read the spd_ui_fileconfig text file which contains information
  ; on missions that have file configuration settings they want to 
  ; modify within the gui
  getresourcepath,configPath
  restore,filename=configPath+'spd_ui_fileconfig_template.sav' ;restores a saved ascii_template variable named "templ"
  configTabs = read_ascii(configPath+'spd_ui_fileconfig.txt',template=templ,count=tabNum) ;load data api configuration information

  if tabNum eq 0 then message,'ERROR: No tabs found in config file. Probable config file error' 
  
  ; create a widget base for each tab
  tabArray = make_array(tabNum, /long)
  for i=0,tabNum-1 do begin
      tabArray[i] = widget_base(tabBase, title=configTabs.mission_name[i], $
                           event_pro=configTabs.procedure_name[i])    
  endfor

  widget_control, tabBase, set_tab_current=0
 
  ; create the save, reset and close buttons
  bottomBase = widget_base(tlb, /Col, YPad=6, /Align_Left)
  doneButton = widget_button(bottomBase, value='   Done   ',uval='DISMISS', /align_center)
  statusBar = Obj_New('SPD_UI_MESSAGE_BAR', $
                       Value='Status information is displayed here.', $
                        bottomBase, XSize=83, YSize=1)
  
  ; call the configuration file gui IDL procedure for each mission listed in the 
  ; spd_ui_config text file
  FOR i = 0 ,tabNum-1 DO call_procedure, strtrim(configTabs.procedure_name[i]), tabArray[i], $
                               historyWin, statusBar

  state = {tlb:tlb,gui_id:gui_id,tabBase:tabBase,historyWin:historyWin,statusBar:statusBar, $
            tabArray:tabArray,previousTab:0,configTabs:configTabs}
 
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  Widget_Control, tlb, get_UValue = state, /No_Copy
  Widget_Control, tlb, set_UValue = state, /No_Copy

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_init_fileconfig', tlb, /No_Block

  RETURN

end
