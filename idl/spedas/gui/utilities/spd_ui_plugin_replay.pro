
;+
;Procedure:
;  spd_ui_plugin_replay
;
;Purpose:
;  Replays overations performed by GUI plugins when loading GUI documents.
;
;Calling Sequence:
;  spd_ui_plugin_replay, procedure, parameters, loaded_data
;
;Input:
;  procedure: (string) name of plugin routine to be called
;  parameters: (stuct/int) Anonymous struct conforming to keywords for named routine
;                          or 0 if no keywords specified.
;  loaded_data: (obj) reference to loaded_data objecrt
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-13 18:20:24 -0800 (Thu, 13 Feb 2014) $
;$LastChangedRevision: 14377 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_plugin_replay.pro $
;
;-

pro spd_ui_plugin_replay, procedure, $
                          parameters, $
                          loaded_data, $
                          history_window, $
                          status_bar

    compile_opt idl2, hidden


  if ~is_string(procedure) then begin
    return
  endif

  if ~spd_find_file(procedure+'.pro') then begin
    x = 'The plugin routine "'+procedure+'.pro" could not be located.  '+ $
        'Check that file exists in the current IDL path.'
    spd_ui_message, x, sb=status_bar, hw=history_window 
    return
  endif
  
  ;A halt here may indicate that keyword options were not 
  ;properly added to the call sequence.  Checking the plugin
  ;code for typos is recommended.
  if is_struct(parameters) then begin
    call_procedure, procedure, $
                    loaded_data, $
                    history_window, $
                    status_bar, $
                    _extra=parameters
  endif else begin
    call_procedure, procedure, $
                    loaded_data, $
                    history_window, $
                    status_bar
  endelse
  
  
end
