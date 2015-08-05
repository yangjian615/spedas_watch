;+ 
;NAME:
;      mms_ui_load_data
;
;PURPOSE:
;      This is the start of a SPEDAS Load Data plugin for the MMS mission
;
; NOTES:
;      Need to add multiple select capabilities to probes and types
;      mms_load_state can handle '*' for probes levels and types
;      mms_load_data may not yet have this implemented
;      
;HISTORY:
;$LastChangedBy: crussell $
;$LastChangedDate: 2015-08-03 15:10:24 -0700 (Mon, 03 Aug 2015) $
;$LastChangedRevision: 18370 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/load_data/mms_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro mms_ui_load_data_event,event
  compile_opt hidden,idl2

  ;handle and report errors, reset variables
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
      /noname, /center, title='Error in Load Data')
    if is_struct(state) then begin
      ;send error message
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      
      if widget_valid(state.baseID) && obj_valid(state.historyWin) then begin 
        spd_gui_error,state.baseid,state.historyWin
      endif
      
      ;update central tree, if possible
      if obj_valid(state.loadTree) then begin
        *state.treeCopyPtr = state.loadTree->getCopy()
      endif  
      
      ;restore the state structure 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    endif
  
    widget_control, event.top,/destroy
    RETURN
  ENDIF

  ;retrieve the state variable 
  widget_control, event.handler, Get_UValue=state, /no_copy
  
  ;retrieve event information and the uvalue (or widget name)
  ;note, not all widgets are assigned uvalues
  widget_control, event.id, get_uvalue = uval

  if is_string(uval) then begin
    case uval of
      'INSTRUMENT': begin
        ;retrieve the instrument type that was selected by the user and 
        ;update state
        instrList = widget_info(event.handler,find_by_uname='instrument')
        instrSel = widget_info(instrList, /combobox_gettext) 
        if instrSel NE state.currentInstrument then begin
           if instrSel NE 'STATE' then levelArray=state.sciLevelArray else levelArray=state.stateLevelArray
           if instrSel NE 'STATE' then typeArray=state.sciTypeArray else typeArray=state.stateTypeArray
           levelList = widget_info(event.handler,find_by_uname='levellist')
           typeList = widget_info(event.handler,find_by_uname='typelist')
           widget_control, levelList, set_value=levelArray
           widget_control, typeList, set_value=typeArray
           state.currentInstrument = instrSel
        endif
        ;widget_control,instrList,set_list_select=instrSel
      end    
      'CLEARPROBE': begin
        ;clear the proble list widget of any selections
        probeList = widget_info(event.handler,find_by_uname='probelist')
        widget_control,probeList,set_list_select=-1
      end
      'CLEARLEVEL': begin
        ;clear the data type list widget of all selections
        levelList = widget_info(event.handler,find_by_uname='levellist')
        widget_control,levelList,set_list_select=-1
      end
      'CLEARTYPE': begin
        ;clear the data type list widget of all selections
        typeList = widget_info(event.handler,find_by_uname='typeList')
        widget_control,typeList,set_list_select=-1
      end
      'CLEARDATA': begin
        ;clear the actual data that has been loaded. this will delete all 
        ;data loaded into the gui memory so warn user first
        ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",/question,/default_no,/center)
        
        if strlowcase(ok) eq 'yes' then begin
          datanames = state.loadedData->getAll(/parent)
          if is_string(datanames) then begin
            for i = 0,n_elements(dataNames)-1 do begin
              result = state.loadedData->remove(datanames[i])
              if ~result then begin
                ;report errors to the status bar for the user to see and log the
                ;error to the history window
                state.statusBar->update,'Unexpected error while removing data.'
                state.historyWin->update,'Unexpected error while removing data.'
              endif
            endfor
          endif
          ;update the data tree and add the delete commands to the callSequence
          ;object which tracks sequences of calls during the gui session
          state.loadTree->update
          state.callSequence->clearCalls
        endif
        
      end   
      'DEL': begin
        ;get the current list of loaded data
        dataNames = state.loadTree->getValue()
        
        if ptr_valid(datanames[0]) then begin
          for i = 0,n_elements(dataNames)-1 do begin
            ;delete the selected data from the gui memory and loaded data tree
            result = state.loadedData->remove((*datanames[i]).groupname)
            if ~result then begin
              ;report errors to the status bar for the user to see and log the
              ;error to the history window
              state.statusBar->update,'Unexpected error while removing data.'
              state.historyWin->update,'Unexpected error while removing data.'
            endif
          endfor
        endif
        state.loadTree->update      
   
      end
      'ADD': begin

        probelist = widget_info(event.handler,find_by_uname='probelist')
        probeSelect = widget_info(probelist,/list_select)
        ;if no selections were made, report this to the status bar and
        ;history window
        if probeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one probe'
          state.historyWin->update,'MMS add attempted without selecting probe'
          break
        endif
        probes = state.probeArray[probeSelect]

        ;retrieve the instruments selected by the user
        instlist = widget_info(event.handler,find_by_uname='instrument')
        instrument = widget_info(instlist,/combobox_gettext)
        instNum = widget_info(instlist,/combobox_number)
        ;report errors to status bar and history window
        if  instNum eq -1 then begin
          state.statusBar->update,'You must select at least one instrument'
          state.historyWin->update,'MMS add attempted without selecting an instrument'
          break
        endif

        ;retrieve the data level that were selected by the user
        levellist = widget_info(event.handler,find_by_uname='levellist')
        levelSelect = widget_info(levellist,/list_select)
        ;if no selections were made, report this to the user via the
        ;status bar and log the error to the history window
        ; Currently there are no levels for science types so for now only check state data
        if levelSelect[0] eq -1 && state.currentInstrument eq 'STATE' then begin
          state.statusBar->update,'You must select at least one level'
          state.historyWin->update,'MMS add attempted without selecting level'
          break
        endif
        if state.currentInstrument ne 'STATE' then levels = state.sciLevelArray[levelSelect] $
           else levels = state.stateLevelArray[levelSelect] 

        ;retrieve the levels that were selected by the user
        ;if state.currentInstrumemt eq 'STATE' then levels = state.statelevelArray[levelSelect]
      
        ;retrieve the data types that were selected by the user
        typelist = widget_info(event.handler,find_by_uname='typelist')
        typeSelect = widget_info(typelist,/list_select)        
        ;if no selections were made, report this to the user via the 
        ;status bar and log the error to the history window
        if typeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one data type'
          state.historyWin->update,'MMS add attempted without selecting data type'
          break
        endif
        if state.currentInstrument ne 'STATE' then types = state.sciTypeArray[typeSelect] $
           else types = state.stateTypeArray[typeSelect]
        
        ;get the start and stop times 
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        ;report errors
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'MMS add attempted with start time greater than end time.'
          break
        endif
        
        ;turn on the hour glass while the data is being loaded
        widget_control, /hourglass
        
        ;create a load structure to pass the parameters needed by the load
        ;procedure
        ; NOTE: Currently state data has both level and type but science
        ; data does not. Eventually science data will probably have a level.
        if instrument EQ 'STATE' then $
           loadStruc = { probes:probes, $
                         instrument:instrument, $
                         level:levels, $
                         type:types, $
                         trange:[startTimeString, endTimeString] }  $
        else loadStruc = { probes:probes, $
                           instrument:instrument, $
                           level:types, $
                           trange:[startTimeString, endTimeString] }

        ;call the routine that loads the data and update the loaded data tree
        mms_ui_load_data_import, $
                         loadStruc,$
                         state.loadedData,$
                         state.statusBar,$
                         state.historyWin,$
                         state.baseid,$  ;needed for appropriate layering and modality of popups
                         replay=replay,$
                         overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 

         ;update the loaded data object
         state.loadTree->update

         ;create a structure that will be used by the call sequence object. the
         ;call sequence object tracks the sequences of dprocs that have been 
         ;executed during a gui session. This is so it can be replayed in a 
         ;later session. The callSeqStruc.type for ALL new missions is 
         ;'loadapidata'.
         callSeqStruc = { type:'loadapidata', $
                          subtype:'mms_ui_load_data_import', $
                          loadStruc:loadStruc, $
                          overwrite_selections:overwrite_selections }
         ; add the information regarding this load to the call sequence object
         state.callSequence->addSt, callSeqStruc
         
         ;NOTE: In order to replay a session the user must save the sequence of
         ;commands by selecting 'Save SPEDAS document' under the 'File' 
         ;pull down menu prior to exiting the gui session. 
              
      end
      else:
    endcase
  endif
  
  ;set the state structure before returning to the panel
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end

pro mms_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  ;create all the bases needed for the widgets on the panel 
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='mms_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='MMS Data Selection:',/align_left)
  rightLabel = widget_label(rightBase,value='Data Loaded:',/align_left)
  
  selectionBase = widget_base(leftBase,/col,/frame)
  treeBase = widget_base(rightBase,/col,/frame)
  
  ;create the buttons to add or remove data to the gui. the bitmaps for 
  ;these buttons include a 'right arrow' for adding to the currently loaded 
  ;data, and a 'trashcan' for removing data from the data tree. 
  addButton = Widget_Button(middleBase, Value=rightArrow, /Bitmap,  UValue='ADD', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(middleBase, Value=trashcan, /Bitmap, $
                Uvalue='DEL', $
                ToolTip='Delete data selected in the list of loaded data')
  
  ;this creates and copies the loaded data tree for use within this routine
  loadTree = Obj_New('spd_ui_widget_tree', treeBase, 'LOADTREE', loadedData, $
                     XSize=400, YSize=425, mode=0, /multi,/showdatetime)                   
  loadTree->update,from_copy=*treeCopyPtr
  
  ;create the buttons that removes all data
  clearDataBase = widget_base(rightBase,/row,/align_center)  
  clearDataButton = widget_button(clearDataBase,value='Delete All Data',uvalue='CLEARDATA',/align_center,ToolTip='Deletes all loaded data')
  
  ;the ui time widget handles all widgets and events that are associated with the 
  ;time widget and includes Start/Stop Time labels, text boxes, calendar icons, and
  ;other items associated with setting the time for the data to be loaded.
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget')
    
  probeArrayValues = ['1', '2', '3', '4']
  probeArrayDisplayed = ['MMS 1', 'MMS 2', 'MMS 3', 'MMS 4']
  instrumentArray = ['DFG', 'AFG', 'STATE']
  sciLevelArray = ['']
  sciTypeArray = ['ql', 'l1b']
  stateLevelArray = ['def']
  stateTypeArray = ['*','pos', 'vel', 'spinras', 'spindec']

  ; default to science data 
  currentLevelArray = sciLevelArray
  currentTypeArray = sciTypeArray
  currentInstrument = instrumentArray[0]
  
  ;create the dropdown menu that lists the various instrument types for MMS
  instrumentBase = widget_base(selectionBase,/row) 
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  instrumentCombo = widget_combobox(instrumentBase,$
                                       value=instrumentArray,$
                                       uvalue='INSTRUMENT',$
                                       uname='instrument')
                                  
  ;create the list box that lists all the probes that are associated with MMS
  dataBase = widget_base(selectionBase,/row)
  probeBase = widget_base(dataBase,/col)
  probeLabel = widget_label(probeBase,value='Probe: ')
  probeList = widget_list(probeBase,$
                          value=probeArrayDisplayed,$
                        ;  /multiple,$
                          uname='probelist',$
                          xsize=16,$
                          ysize=15)
  clearProbeButton = widget_button(probeBase,value='Clear Probe',uvalue='CLEARPROBE',ToolTip='Deselect all probes/stations')
                          
  ;create the list box aand a clear all button for the data levels for a given 
  ;instrument           
  levelBase = widget_base(dataBase,/col)
  levelLabel = widget_label(levelBase,value='Level:')
  levelList = widget_list(levelBase,$
                         value=currentLevelArray,$
                       ;  /multiple,$
                         uname='levellist',$
                         xsize=16,$
                         ysize=15)
  ; default to all science data types 
  widget_control, levelList, set_list_select = 0                                               
  clearLevelButton = widget_button(levelBase,value='Clear Level',uvalue='CLEARLEVEL',ToolTip='Deselect all levels')

  ;create the list box aand a clear all button for the data types for a given
  ;instrument
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Type:')
  typeList = widget_list(typeBase,$
                         value=currentTypeArray,$
                       ;  /multiple,$
                         uname='typelist',$
                         xsize=16,$
                         ysize=15)
  ; default to all science data types
  widget_control, typeList, set_list_select = 0
  clearLevelButton = widget_button(typeBase,value='Clear Types',uvalue='CLEARTYPE',ToolTip='Deselect all data types')

  ;create the state variable with all the parameters that are needed by this 
  ;panels event handler routine                                                               
  state = {baseid:topBase,$
           loadTree:loadTree,$
           treeCopyPtr:treeCopyPtr,$
           timeRangeObj:timeRangeObj,$
           statusBar:statusBar,$
           historyWin:historyWin,$
           loadedData:loadedData,$
           callSequence:callSequence,$
           probeArray:probeArrayValues,$
           instrumentArray:instrumentArray,$
           currentInstrument:currentInstrument,$
           sciLevelArray:sciLevelArray, $
           sciTypeArray:sciTypeArray, $            
           stateLevelArray:stateLevelArray, $
           stateTypeArray:stateTypeArray, $
           currentLevelArray:currentLevelArray, $
           currentTypeArray:currentTypeArray}
  widget_control,topBase,set_uvalue=state
                                  
  return

end
