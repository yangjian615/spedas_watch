;+
;Procedure:
;  spd_ui_call_plugin
;
;Purpose:
;  Opens specified GUI plugin window.
;
;Calling Sequence:
;  spd_ui_call_plugin, event, loaded_data, data_tree, time_range, call_sequence,
;                      history_window, status_bar
;
;Input:
;  event: event structure from plugin menu
;  loaded_data: loaded data object
;  data_tree: GUI data tree object
;  time_range: GUI time range object
;  call_sequence: GUI call sequence object
;  history_window: history window object
;  status_bar: status bar object
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;
;-

pro spd_ui_call_plugin, event, $
                        loaded_data, $
                        data_tree, $
                        time_range, $
                        call_sequence, $
                        history_window, $
                        status_bar


    compile_opt idl2, hidden


  ;-------------------------------------------------------
  ; Check that procedure exists in current IDL path
  ;-------------------------------------------------------
  
  widget_control, event.id, get_uvalue=plugin
  
  if ~spd_find_file(plugin.procedure+'.pro') then begin
    dummy = dialog_message('The plugin file "'+plugin.procedure+'.pro" could not be located.  '+ $
                           'Check that file exists in the current IDL path.', $
                           title='Plugin not found.', /error, /center)
    return
  endif
  
  
  ;-------------------------------------------------------
  ; Call procedure
  ;-------------------------------------------------------
  
  if ptr_valid(plugin.data) && is_struct(*plugin.data) then begin
    data_struct = *plugin.data
  endif
  
  ;top level widget ID passed as argument because it is required,
  ;everything else will use keywords to allow developer discretion
  ;over level of GUI connectivity
  call_procedure, plugin.procedure, $
                  event.top, $ 
                  loaded_data=loaded_data, $
                  data_tree=data_tree, $
                  time_range=time_range, $
                  call_sequence=call_sequence, $
                  history_window=history_window, $
                  status_bar=status_bar, $
                  data_struct=data_struct
                  
  
  ;-------------------------------------------------------
  ; Update objects and other stored quantities
  ;-------------------------------------------------------
  
  if ~undefined(data_struct) && is_struct(data_struct) then begin
    plugin.data = ptr_new(data_struct)
  endif
  
  widget_control, event.id, set_uvalue=plugin

end
