;+
;Procedure:
;  spd_ui_call_plugin
;
;Purpose:
;  Opens specified GUI plugin window.
;
;Calling Sequence:
;  spd_ui_call_plugin, event, info
;
;Input:
;  event: event structure from plugin menu
;  info: Main storage structure from GUI
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-03-31 17:09:35 -0700 (Mon, 31 Mar 2014) $
;$LastChangedRevision: 14721 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_call_plugin.pro $
;
;-

pro spd_ui_call_plugin, event, info


    compile_opt idl2, hidden


  ;-------------------------------------------------------
  ; Check that procedure exists in current IDL path
  ;-------------------------------------------------------
  
  widget_control, event.id, get_uvalue=plugin
  
  if ~spd_find_file(plugin.procedure+'.pro') then begin
    spd_ui_message, 'The plugin file "'+plugin.procedure+'.pro" could not be located.  '+ $
                    'Check that file exists in the current IDL path.', $
                    sb=status_bar, hw=history_window, $
                    /dialog, /error, /center, title='Plugin not found.'
    return
  endif
  
  
  ;-------------------------------------------------------
  ; Call procedure
  ;-------------------------------------------------------
  
  if ptr_valid(plugin.data) && is_struct(*plugin.data) then begin
    data_structure = *plugin.data
  endif
  
  ;call sequence is stored in the window object (gui doc support) 
  info.windowStorage->getProperty,callSequence=call_Sequence
  
  ;Required inputs are passed as arguments, optional inputs use keywords
  call_procedure, plugin.procedure, $
                  gui_id = event.top, $
                  loaded_data = info.loadeddata, $
                  call_sequence = call_sequence, $
                  data_tree = info.guitree, $
                  time_range = info.loadtr, $
                  window_storage = info.windowStorage, $
                  history_window = info.historywin, $
                  status_bar = info.statusbar, $
                  data_structure = data_structure
                  
                  
  ;-------------------------------------------------------
  ; Update objects and other stored quantities
  ;-------------------------------------------------------
  
  if ~undefined(data_structure) && is_struct(data_structure) then begin
    plugin.data = ptr_new(data_structure)
    
    if in_set('track_one',strlowcase(tag_names(data_structure))) then begin
      if keyword_set(data_structure.track_one) then begin
        spd_ui_track_one, ptr_new(info)
      endif
    endif
  endif
  
  widget_control, event.id, set_uvalue=plugin
  
  info.windowMenus->sync, info.windowStorage
  
  
  ;-------------------------------------------------------
  ; Update draw object and draw
  ;-------------------------------------------------------
  
;    ;needed for overview plots?
;    spd_ui_orientation_update,drawObject,windowStorage
    
    info.drawObject->Update,info.windowStorage,info.loadedData 
    info.drawObject->Draw

end
