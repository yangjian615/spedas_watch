

;=============================================================
;  This is an example plugin for developers using the SPEDAS API.
;  Scroll down for the main plugin routine.
;  See spd_ui_plugin_config.txt to enable.
;=============================================================


;+
;Purpose:
;  Get the names of all currently selected variables from the tree widget.
;
;-
function yyy_ui_plugin_getselection, state

    compile_opt idl2, hidden

  ;get current selectrion from data tree
  variables = state.data_tree->getvalue()

  if ~ptr_valid(variables[0]) then begin
    state.status_bar->update, 'No valid selection.'
    return, ''
  endif

  ;loop over selected variables to get list
  for i=0, n_elements(variables)-1 do begin
    names = array_concat( (*variables[i]).groupname, names)
  endfor
  
  return, names
  
end


;+
;Purpose:
;  Example plugin event handler.
;
;-
pro yyy_ui_plugin_event, event

    compile_opt idl2, hidden


  ;Extract structure holding important object references and widget IDs.
  ;------------------------------------------------------------
  ;  Use /no_copy to improve performance.
  ;  If /no_copy is used the uvalue must be re-set before the event 
  ;  handler returns.
  widget_control, event.top, get_uval=state, /no_copy

  
  ;Error catch block
  ;------------------------------------------------------------
  catch, error
  if error ne 0 then begin
    catch, /cancel
    
    ;notify user
    help, /last_message
    dummy = dialog_message('An unexpected error occured, see console output.', $
              /error, /center, title='Unknown Error') 
    
    ;close plugin if state structure is no longer defined, 
    ;otherwise attempt to continue as usual
    if is_struct(state) then begin
      widget_control, event.top, set_uval=state, /no_copy
      return
    endif else begin
      print, '**FATAL PLUGIN ERROR - Closing window**'
      if widget_valid(event.top) then begin
        widget_control, event.top, /destroy
      endif
      return
    endelse
    
  endif
  
  
  ;catch kill requests
  ;------------------------------------------------------------
  if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    widget_control, event.top, /destroy
    return
  endif
  
  
  ;process the event based on which widget generated it
  ;------------------------------------------------------------
  uname = strlowcase(widget_info(event.id, /uname))
  if ~is_string(uname) then uname = ''


  case uname of 
    
    ;exit
    ;----------------------------------
    'ok': begin
      state.status_bar->update, 'Closing test plugin.'
      widget_control, event.top, set_uval=state, /no_copy ;necessary?
      widget_control, event.top, /destroy
      return
    end
    
    ;add test variable
    ;----------------------------------
    'add': begin
      
      ;call helper routine
      yyy_ui_plugin_add, state.loaded_data, state.history_window, state.status_bar
      
      ;Add to call sequence for GUI document replay
      ;  -specify name of routine that was just called
      ;  -any keywords that were used should be added here 
      ;    (none for this example)
      state.call_sequence->addPluginCall, 'yyy_ui_plugin_add' 
    end
    
    ;multiply data by scaled random factor
    ;----------------------------------
    'randomize': begin
      
      ;get selected names from tree
      names = yyy_ui_plugin_getselection(state)
      if ~is_string(names) then break
      
      trange = [ state.time_range->getstarttime(), $
                 state.time_range->getendtime()  ]
      
      ;call helper routine
      yyy_ui_plugin_randomize, state.loaded_data, state.history_window, state.status_bar, $
                               names=names, trange=trange
      
      ;Add to call sequence for GUI document replay
      ;  -specify name of routine that was just called
      ;  -any keywords that were used should be added here
      state.call_sequence->addPluginCall, 'yyy_ui_plugin_randomize', $
                                          names=names, trange=trange
    end
    
    ;delete selected data
    ;----------------------------------
    'delete': begin
      
      ;get selected names from tree
      names = yyy_ui_plugin_getselection(state)
      if ~is_string(names) then break
      
      ;call helper routine
      yyy_ui_plugin_delete, state.loaded_data, state.history_window, state.status_bar, $
                            names=names
      
      ;Add to call sequence for GUI document replay
      ;  -specify name of routine that was just called
      ;  -any keywords that were used should be added here
      state.call_sequence->addPluginCall, 'yyy_ui_plugin_delete', $
                                          names=names
    end
    
    else: ;ignore other widgets' events
    
  endcase
  
  
  ;update data tree for all non-tree events
  if uname ne 'tree' then begin
    state.data_tree->update
  endif
  
  ;re-set state structure
  widget_control, event.top, set_uval=state, /no_copy
  
end




;+
;Procedure:
;  yyy_ui_plugin
;
;Purpose:
;  A basic example plugin for SPEDAS GUI API.
;
;Calling Sequence:
;  See instructions in spedas/gui/resources/spd_ui_plugin_config.txt
;  to enable the plugin in the GUI.
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-13 18:21:48 -0800 (Thu, 13 Feb 2014) $
;$LastChangedRevision: 14378 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/api_examples/plugin_menu/yyy_ui_plugin.pro $
;-

pro yyy_ui_plugin, gui_id, $
                   loaded_data=loaded_data, $
                   data_tree=data_tree, $
                   time_range=time_range, $
                   call_sequence=call_sequence, $
                   history_window=history_window, $
                   status_bar=status_bar, $
                   _extra=dummy


    compile_opt idl2, hidden


  ;Create top level base.
  ;  IMPORTANT: The top level base should always be modal and have its
  ;             group leader set to GUI_ID.  This will keep events from 
  ;             the main gui from conflicting with those from the plugin. 
  main_base = widget_base(title='Example Plugin.', /col, /base_align_center, $ 
               group_leader=gui_id, /modal, /tlb_kill_request_events, tab_mode=1)
  
  
  ;time
  ;-------------------------------------------------------
  
  time_base = widget_base(main_base, /row)
  
    ;create new time widget using time range from GUI
    time = spd_ui_time_widget(time_base, status_bar, history_window, $
               timerangeobj=time_range, uname='time', suppressoneday=1)

  
  ;data tree
  ;-------------------------------------------------------
  
  tree_base = widget_base(main_base, /row)

    ;The data tree requires a reference to the loaded data object
    ;and a copy of the GUI data tree.  Here we also specify the
    ;widget's size, allow for multiple selections, and set the
    ;widget to display each variable's time range.  
    tree = obj_new('spd_ui_widget_tree', tree_base, 'tree', loaded_data, $
           uname='tree', xsize=440, ysize=330, /multi, /showdatetime, $
           from_copy=long(*data_tree))
  
  
  ;buttons
  ;-------------------------------------------------------
  
  button_base = widget_base(main_base, /row)
    
    ok = widget_button(button_base, value=' OK ', uname='ok', $
           tooltip='Exit test widget.')

    add = widget_button(button_base, value='Add', uname='add', $
           tooltip='Add test variable.')
    
    randomize = widget_button(button_base, value='Randomize', uname='randomize', $
           tooltip='Multiply data by scaled random factor.')
        
    delete = widget_button(button_base, value='Delete', uname='delete', $
           tooltip='Delete all selected variables')


  ;finalize & start
  ;-------------------------------------------------------
  
  ;Store important objects and widget IDs in a structure
  ;that can be retreived while processing widget events. 
  state = { $
           gui_id:gui_id, $
           loaded_data:loaded_data, $
           data_tree:tree, $
           time_range:time_range, $
           call_sequence:call_sequence, $
           history_window:history_window, $
           status_bar:status_bar $
           }
  
  ;center the window
  centertlb, main_base
  
  ;store state structure and realize widgets
  widget_control, main_base, set_uval=state, /no_copy
  widget_control, main_base, /realize
  
  ;keep windows in X11 from snaping back to center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, main_base, xoffset=0, yoffset=0
  endif
  
  xmanager, 'yyy_ui_plugin', main_base, /no_block
  
  return

end