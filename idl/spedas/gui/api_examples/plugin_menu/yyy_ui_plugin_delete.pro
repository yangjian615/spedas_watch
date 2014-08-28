;+
;Purpose:
;  Helper function to delete selected variables.
;
;-
pro yyy_ui_plugin_delete, loaded_data, history_window, status_bar, $
                          names=names, $
                          _extra=_extra

  compile_opt idl2, hidden


  status_bar->update, 'Deleting selected variables...'


  ;loop over variables to remove them from the loaded data object
  for i=0, n_elements(names)-1 do begin

    ok = loaded_data->remove(names[i])

  endfor

  status_bar->update, 'Variables deleted.'

end
