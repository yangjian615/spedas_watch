;+ 
;NAME:
;  spd_ui_load_data_file
;
;PURPOSE:
;  A widget interface for loading SPEDAS data into the GUI
;
;CALLING SEQUENCE:
;  spd_ui_load_data_file, tab_id, gui_id, windowStorage, loadedData, historyWin, $
;                        dataFlag, dataButtons, trObj, statusText, loadTree=loadList,$
;                        treeCopyPtr, timeWidget=timeid
;
;INPUT:
;  tab_id:  The widget id of the tab.
;  gui_id:  The widget id of the main GUI window.
;  windowStorage:  The windowStorage object.
;  loadedData:  The loadedData object.
;  historyWin:  The history window object.
;  dataFlag:  
;  dataButtons:  
;  trObj:  The GUI timerange object.
;  statusText:  The status bar object for the main Load window.
;  treeCopyPtr:  Pointer variable to a copy of the load widget tree.
;  
;KEYWORDS:
;  loadTree = The Load widget tree.
;  timeWidget = The time widget object.
;
;OUTPUT:
;  none
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-02-12 09:13:00 -0800 (Wed, 12 Feb 2014) $
;$LastChangedRevision: 14352 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/panels/spd_ui_load_data_file/spd_ui_load_data_file.pro $
;
;-

; TODO: When we get around to loading non-spedas data, might need a pop-up window for when we don't know the coordsys of incoming data
Pro spd_ui_load_data_file_event, event;, info
  Compile_Opt idl2, hidden

  ; get the state structure from the widget
  base = event.handler
  stash = widget_info(base,/child)
  widget_control, stash, Get_UValue=state, /no_copy

  ; handle and report errors
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
    dprint,  'Load SPEDAS Data widget killed.' 
    state.historyWin->Update,'SPD_UI_LOAD_DATA_FILE: Widget closed' 
    if obj_valid(state.loadList) then begin
      *state.treeCopyPtr = state.loadList->getCopy()
    endif 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF

  ; get the uval from this event so we know which widget was used 
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'SPD_UI_LOAD_DATA_FILE: User value: '+uval  ,/dontshow

  CASE uval OF
    'ADD': BEGIN
      ; make sure valid times are set
      state.tr->getproperty, starttime=start_obj
      state.tr->getproperty, endtime=stop_obj
      start_obj->getProperty,tstring=startval
      stop_obj->getProperty,tstring=stopval
      startt=spd_ui_timefix(startval)
      stopt=spd_ui_timefix(stopval)
      ; temporarily change get_value func to get validity
      widget_control, state.timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      widget_control, state.timeid, func_get_value='spd_ui_time_widget_get_value'
      if is_string(startt) AND is_string(stopt) AND valid then begin
        ; make sure an observatory is selected
        if ~array_equal(*state.observ, '', /no_typeconv) then begin
          widget_control, /hourglass
          state.statusText->Update, 'Loading data...'
          spd_ui_load_data_file_load, state, event
          IF Obj_Valid(state.loadedData) && state.dataFlag EQ 0 THEN BEGIN
             dataNames=state.loadedData->GetAll()
             IF is_string(dataNames) && state.dataFlag EQ 0 THEN BEGIN
                FOR i=0,N_Elements(state.dataButtons)-1 DO Widget_Control, state.dataButtons[i], sensitive=1
                state.dataFlag=1  
            ENDIF
          ENDIF
        endif else begin
          if state.instr eq 'none' then begin
            h = 'No instrument selected.  Please select an instrument.'
          endif else begin
            h = 'No probe selected.  Please select one or more probes.'
          endelse
          
          state.statusText->Update, h
          state.historyWin->Update, 'SPD_UI_LOAD_DATA_FILE: ' + h
        endelse
      endif else begin
        state.statusText->update, 'Invalid Start and/or Stop Time.  ' + $
                          'Please enter valid time before loading data.'
        break
      endelse
    END
    'CANC': BEGIN
       dprint,  'New File widget canceled' 
       state.historyWin->Update, 'SPD_UI_LOAD_DATA_FILE: Widget closed.'
       if obj_valid(state.loadList) then begin
        *state.treeCopyPtr = state.loadList->getCopy()
       endif  
       Widget_Control, event.top, Set_UValue=state, /No_Copy
       Widget_Control, event.top, /Destroy
       RETURN
    END
    'CLEAR':BEGIN ; Clear all data (tplot vars)
      ; Should check whether there is any data first.
      val_data = state.loadeddata->getall();/times)
      if is_string(val_data[0]) then begin
        result = dialog_message("This will delete all data loaded into the GUI. Do you still want to proceed?", $
          /question, dialog_parent=state.tab_id, /default_no, /center)
        IF result EQ 'Yes' THEN BEGIN
          widget_control, /hourglass
          ;val_data = state.loadeddata->getall();/times)
          spd_ui_load_data_file_del, state
          state.windowStorage->getProperty,callSequence=callSequence
          callSequence->clearCalls
          h = 'All data deleted.'
          state.statusText->Update, h
          state.historyWin->Update, 'SPD_UI_LOAD_DATA_FILE: ' + h
          state.loadedData->reset
          state.loadlist->update    ; update tree widget
        ENDIF
       endif
    END
    'CLEAR_DTYP':Begin
      if ptr_valid(state.dtyp1) then ptr_free, state.dtyp1
      if ptr_valid(state.dtyp2) then ptr_free, state.dtyp2
      if ptr_valid(state.dtyp) then ptr_free, state.dtyp
      widget_control, state.level1List, set_value=*state.dlist1
      widget_control, state.level2List, set_value=*state.dlist2
      h = 'No chosen data types'
      state.statusText->Update, h
    END
    'CLEAR_PRST':Begin
      If(state.instr Eq 'asi' Or state.instr Eq 'ask') Then Begin
        If(ptr_valid(state.astation)) Then ptr_free, state.astation
        h = 'No Chosen Asi_station'
        state.statusText->Update, h
      Endif Else If(state.instr Eq 'gmag') Then Begin
        If(ptr_valid(state.station)) Then ptr_free, state.station
        h = 'No Chosen Gmag_station'
        state.statusText->Update, h
      Endif Else Begin
        If(ptr_valid(state.probe)) Then ptr_free, state.probe      
        h = 'No Chosen Probe'
        state.statusText->Update, h
      Endelse
      widget_control,state.observlist, set_value=*state.validobservlist
    END
    'COORD_DLIST':BEGIN ; Output Coordinates dropdown list
      spd_ui_load_data_file_coord_sel, state    
    END
    'DELDATA':BEGIN ; Clear selected data (tplot vars)
      widget_control, /hourglass
      spd_ui_load_data_file_del, state
      state.loadlist->update
    END
    'ITYPE_DLIST':BEGIN ; Instrument Type dropdown list
      spd_ui_load_data_file_itype_sel, state
    END
    'LEVEL1': BEGIN ; Level 1 data list
      spd_ui_load_data_file_l1_sel, state
    END
    'LEVEL2': BEGIN ; Level 2 data list
      spd_ui_load_data_file_l2_sel, state
    END
    'LOADLIST':BEGIN
      ;this isn't needed, this code spends a lot of time and effort maintain copies of lists already maintained by ui widgets
      ;spd_ui_load_data_file_loadlist, state, event
    END
    'OBSERV_LIST':BEGIN ; Observatory list (probes, ground stations, etc.)
      spd_ui_load_data_file_obs_sel, state
    END
    'CHECK_DATA_AVAIL': BEGIN ; launch browser to data availability page
      spd_ui_open_url, 'http://themis.ssl.berkeley.edu/data_products/'
    END
    ELSE:
  ENDCASE
  
  ; must ALWAYS reset the state value
  widget_control, stash, set_uvalue=state, /NO_COPY

  RETURN
END

pro spd_ui_load_data_file, tab_id, gui_id, windowStorage, loadedData, historyWin, $
                           dataFlag, dataButtons, trObj, statusText, loadTree=loadList,$
                           treeCopyPtr,timeWidget=timeid
  compile_opt idl2, hidden
  
  widget_control, /hourglass

  ; initialize variables
  dtyp1='' & dtyp2='' & dtyp10='' & dtyp20='' & dtype='' & observ0='' & dtyp=''
  outCoord0=' DSL' ; default output coordinates
;  astation0 = '*' ; default all-sky station
;  station0 = '*' ; default ground mag station
;  probe0 = '*' ; default probe
  astation0 = '' ; default all-sky station
  station0 = '' ; default ground mag station
  probe0 = '' ; default probe
  probes = ['*', 'a', 'b', 'c', 'd', 'e', 'f']


  If(ptr_valid(dtyp)) Then ptr_free, dtyp
  dtyp = ptr_new(dtyp)
  If(ptr_valid(dtyp1)) Then ptr_free, dtyp1
  dtyp1 = ptr_new(dtyp1)
  If(ptr_valid(dtyp2)) Then ptr_free, dtyp2
  dtyp2 = ptr_new(dtyp2)
 
  
  observ_labels=['All-Sky Ground Station','GMAG Ground Station','Probes']
  observ_label=observ_labels[0]+':' ; default instrument label
;  instr_in0 = 'ASI' ; default data type
  instr_in0 = 'ASK' ; default data type
;  thm_load_asi, /valid_names, site=asi_stations
  thm_load_ask, /valid_names, site=asi_stations
  validobservlist = ['* (All)', asi_stations]
  validobserv = validobservlist
  validobserv = ptr_new(validobserv)
  observ = ptr_new(observ0) 

  instr=strlowcase(instr_in0)
  
  outCoord = strcompress(strlowcase(outCoord0),/remove_all)
  ;outCoord = 'N/A'

 ; Get valid datatypes, probes, etc for different data types  
  dlist = spd_ui_valid_datatype(instr, ilist, llist)
  dlist1_all = ['*', dlist]
  dlist2_all = 'None'
  dlist1 = ptr_new(dlist1_all) & dlist2 = ptr_new(dlist2_all)
  ;dlist1 = dlist1_all & dlist2 = dlist2_all
  
      ;master widget
  
;  tlb = Widget_Base(/Col, Title = 'SPEDAS: Load Data ', Group_Leader = gui_id, $
;                    /Modal, /Floating, /TLB_KILL_REQUEST_EVENTS)
                    
  ; create base widgets
  topBase = Widget_Base(tab_id, /Row, /Align_Top,  tab_mode=1, /Align_Left, YPad=1) 
;  buttonBase = Widget_Base(tab_id, /Row, /Align_Center, YPad=8) 
;  statusBase = Widget_Base(tab_id, /Row)
  dataBase = Widget_Base(topBase, /Col, /Align_Left, YPad=1)
  data_label = Widget_Label(dataBase, Value='Data Selection:', /Align_Left)  
  dlistBase = Widget_Base(dataBase, /Col, XPad=2, Frame=3)     
      top1Base = Widget_Base(dlistBase, /Col)
          droplistBase = Widget_Base(top1Base, /Row)
              itypeBase = Widget_Base(droplistBase, /Row) ; instrument type dropdown list
              coordBase = Widget_Base(droplistBase, /Row) ; output coordinates dropdown list
          dbottomBase = Widget_Base(top1Base, /Col)
          observBase = Widget_Base(top1Base, /Row)
              observBase2 = Widget_Base(observBase, /Col)
                  o1Base = Widget_Base(observBase2, /Col)
                      o1ListBase = Widget_Base(o1Base, /Col)
              o2Base = Widget_Base(observBase, /Col)
                  levelBase = Widget_Base(o2Base, /Row)
                      llabelBase = Widget_Base(levelBase, /Row)
                      level1Base = Widget_Base(levelBase, /Col)
                      level2Base = Widget_Base(levelBase, /Col)
  
  ldBase = Widget_Base(topBase, /Col)
      toploadBase= Widget_Base(ldBase, /Row)
          addBase = Widget_Base(toploadBase, /Col, /Align_Left, YPad=175, XPad=5)
          loadBase = Widget_Base(toploadBase, /Col, /Align_Left, YPad=1)    
      bottomloadBase = Widget_Base(ldBase, /Row, YPad=2, /Align_Center)  

  validIType = [' ASK', ' ESA', ' EFI', ' FBK', ' FFT', ' FGM', $
                ' FIT ', ' GMAG', ' MOM', ' SCM', ' SST', ' STATE']
                
  itypeDroplistLabel = Widget_Label(itypeBase, Value='Instrument Type:  ')
  itypeDroplist = Widget_ComboBox(itypeBase, Value=validIType, $ 
                                 uval='ITYPE_DLIST')
                                 
  widget_control, itypeDroplist, set_combobox_select=0 ; default selection is the first in the list (currently ASK)
  
  validProbes = [' * (All)', ' A (P5)', ' B (P1)', ' C (P2)', ' D (P3)', $
                 ' E (P4)', ' F (Flatsat)']
  
  observLabel = Widget_Label(o1ListBase, Value=observ_label, /align_left)
  observList = Widget_List(o1ListBase, Value=*validobserv, uval='OBSERV_LIST', $
                         /Multiple, XSize=16, YSize=11)
  
  level1Label = Widget_Label(level1Base, Value='Level 1:', /align_left)
  level1List = Widget_List(level1Base, Value=*dlist1, XSize=16, /Multiple, YSize=11, $
                           Uvalue='LEVEL1')
  
  level2Label = Widget_Label(level2Base, Value='Level 2:', /align_left)
  level2List = Widget_List(level2Base, Value=*dlist2, /Multiple, XSize=16, YSize=11, $
                           Uvalue='LEVEL2')
                           
  validCoords = [ ' DSL ', ' GSM ', ' SPG  ', ' SSL ',' GSE ', ' GEI ']

  coordDroplistLabel = Widget_Label(coordBase, Value=' Output Coordinates:  ')
  coordDroplist = Widget_ComboBox(coordBase, Value=validCoords, $ ;XSize=165, $
                                  Sensitive=0, uval='COORD_DLIST')
  
  getresourcepath,rpath
;  cal = read_bmp(rpath + 'cal.bmp', /rgb)
;  spd_ui_match_background, tab_id, cal  
  
  midRowBase = Widget_Base(dbottomBase, /row)
  
 ttextBase = Widget_Base(midRowBase, /Col, YPad=3)
 timeid = spd_ui_time_widget(ttextBase,$
                            statusText,$
                            historyWin,$
                            timeRangeObj=trObj,$
                            uvalue='TIME_WIDGET',$
                            uname='time_widget')
                            
  rawDataBase = widget_base(midRowBase,/col,ypad=3,/nonexclusive,/align_center)
  button = widget_button(rawDataBase,val='Uncalibrated/Raw?',uname='raw_data',uvalue='RAW_DATA',sensitive=0)
  
  ;clear buttons
  clearbuts = Widget_Base(dbottomBase, /Row)
  clearbut1 = Widget_Button(observBase2, val = ' Clear Probe/Station ', $
                            uval = 'CLEAR_PRST', /align_center, $
                            ToolTip='Deselect all probes/stations')
  clearbut2 = Widget_Button(o2Base, val = ' Clear Data Type ', $
                            uval = 'CLEAR_DTYP', /align_center, $
                            ToolTip='Deselect all data types')

  davailabilitybutton = widget_button(dataBase, val = ' Check data availability', $
                                      uval = 'CHECK_DATA_AVAIL', /align_center, $
                                      ToolTip = 'Check data availability on the web')
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tab_id, rightArrow 
  spd_ui_match_background, tab_id, trashcan
  
  
  addButton = Widget_Button(addBase, Value=rightArrow, /Bitmap,  UValue='ADD', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(addBase, Value=trashcan, /Bitmap, $
                Uvalue='DELDATA', $
                ToolTip='Delete data selected in the list of loaded data')

  ; ============== Setup loaded data list ======================================
  if obj_valid(loadedData) then begin
    val_data = loadedData->getall(/times)
    if array_equal(val_data,0,/no_typeconv) then val_data = 'None' $
      else begin
        ndata = n_elements(val_data[0,*])
        val_data_temp = strarr(ndata)
        ; would like to vectorize this but need loaded data to be vectorized.
        lastParent = ''
        for i=0, ndata-1 do begin
          ;child = loadedData->isChild(val_data[0,i])
          
          parent = loadedData->isParent(val_data[0,i])
          
          ;this logic is in-case parent and child have the same name
          if parent && val_data[0,i] ne lastParent then begin
            lastParent =val_data[0,i]
            val_data_temp[i] = val_data[0,i]+':    '+val_data[1,i]+' to '+val_data[2,i]
          endif else begin
            val_data_temp[i] = '  - '+val_data[0,i]+':    '+val_data[1,i]+' to '+val_data[2,i]
          endelse
          
;          if child then begin
;            val_data_temp[i] = '  - '+val_data[0,i]+':    '+val_data[1,i]+' to '+val_data[2,i]
;          endif else begin
;            val_data_temp[i] = val_data[0,i]+':    '+val_data[1,i]+' to '+val_data[2,i]
;          endelse
        endfor
        val_data = val_data_temp
      endelse
  endif else val_data = 'None'

  loadLabel  = Widget_Label(loadBase, Value='Data Loaded: ', /Align_Left)
  loadList = Obj_New('spd_ui_widget_tree', loadBase, 'LOADLIST', loadedData, $
                     XSize=380, YSize=380, mode=0, /multi,/showdatetime)
                     
  loadList->update,from_copy=*treeCopyPtr
;  loadList = Widget_List(loadBase, Value=val_data, UValue='LOADLIST', $
;                         XSize=75, YSize=24, /multiple)
  ; ============== End setup loaded data list =================================

;  cancelButton = Widget_Button(bottomloadBase, Value='Cancel', XSize=82, UValue='CANC', $
;    ToolTip='Cancel this operation')
  clearButton = Widget_Button(bottomloadBase, Value='Delete All Data', UValue='CLEAR', $
    ToolTip='Deletes all loaded data')
;  okButton = Widget_Button(bottomloadBase, Value='Done', XSize=82, uValue='DISMISS', $
;    ToolTip='Dismiss Load Panel')

;  statusText = Widget_Text(statusBase, Value='Status information is displayed here ', $
;    UValue='STAT', XSize=87)
    
;  ; Create Status Bar Object
;  statusText = Obj_New('SPD_UI_MESSAGE_BAR', $
;                       Value='Status information is displayed here.', $
;                        statusBase, XSize=145, YSize=1)


  ;main structure for this panel (to be filled in as items are needed)
  state = {tab_id:tab_id, gui_id:gui_id, itypeDroplist:itypeDroplist, observBase:observBase, $
           observ_label:observ_label, timeID:timeID, $
           observ_labels:observ_labels, observLabel:observLabel, observ:observ, $
           observList:observList, validobserv:validobserv, $
           validobservlist:ptr_new(validobservlist), validIType:validIType, $
           level1List:level1List, probe:ptr_new(probe0), probes:probes, $
           validProbes:validProbes, dataFlag:dataFlag, $
           station:ptr_new(station0), astation:ptr_new(astation0), $
           level2List:level2List, dlist1:dlist1, dlist2:dlist2, instr:instr, $
           dtyp10:dtyp10, dtyp20:dtyp20, dtyp1:dtyp1, dtyp2:dtyp2, dtype:dtype, $
           dtyp:dtyp, dtyp_pre:ptr_new(), $
           coordDroplist:coordDroplist, validCoords:ptr_new(validCoords), $
           outCoord:outCoord, tr:trObj, dataButtons:dataButtons, $
           ;addButton:addButton, minusButton:minusButton, loadlist:state_x.loadList, $
           addButton:addButton, minusButton:minusButton, loadlist:loadList, $
           loadedData:loadedData, historyWin:historyWin, $
           validData:ptr_new(val_data), $
           statusText:statusText, windowStorage:windowStorage,$
           treeCopyPtr:treeCopyPtr}

;  CenterTLB, tlb
  Widget_Control, widget_info(tab_id, /child), Set_UValue=state, /No_Copy
;  Widget_Control, tab_id, /Realize
;  XManager, 'spd_ui_load_data_file', tlb, /No_BlockWidget_Control, widget_info(tab_id, /child), Set_UValue=state, /No_Copy

  
  RETURN
END
