;+
;Procedure:
;  yyy_ui_plugin_delete
;
;Purpose:
;  This is an example of a helper routine for GUI plugins.
;  Plugin helper routines perform operations on GUI data
;  and allow those operations to be reproduced when loading
;  GUI documents (see API requirements below).
;
;Calling Sequence:
;  yyy_ui_plugin_delete, loaded_data, history_window, status_bar, 
;                        names=names
;
;API Required Input:
;  loaded_data:  GUI loaded data object
;  history_window:  GUI history window object
;  status_bar:  GUI status bar object
;
;Other Input:
;  names:  (string) Array of names of specifying which variables in
;                   the loaded data object are to be operated on.  
;
;Output:
;  none
;
;API Requirements:
;  -Plugin routines must take the loaded data, history window, and status bar
;   objects as arguments (in that order) and must include the _extra keyword.
;  -All other inputs must be specified in keyword format.
;
;See Also:
;   yyy_ui_plugin
;   yyy_ui_plugin_add
;   yyy_ui_plugin_randomize
;
;Notes:  
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-18 15:28:01 -0800 (Tue, 18 Feb 2014) $
;$LastChangedRevision: 14388 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/api_examples/plugin_menu/yyy_ui_plugin_delete.pro $
;
;-
pro yyy_ui_plugin_delete,$ ;API Required Inputs
                          loaded_data, history_window, status_bar, _extra=_extra, $
                           ;Inputs specific to this routine
                          names=names
                          

  compile_opt idl2, hidden


  status_bar->update, 'Deleting selected variables...'


  ;loop over variables to remove them from the loaded data object
  for i=0, n_elements(names)-1 do begin

    ok = loaded_data->remove(names[i])

  endfor

  status_bar->update, 'Variables deleted.'

end
