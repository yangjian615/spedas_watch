;+
;Purpose:
;  Helper function to add example variable.
;
;-
pro yyy_ui_plugin_add, loaded_data, history_window, status_bar, $
                       _extra=_extra

  compile_opt idl2, hidden


  test_var = 'test_var'
  status_bar->update, 'Adding test variable: '+test_var

  seed = dindgen(1e4)

  t = seed + time_double('2007-03-23/00')

  d = [ [sin( seed/360 )], $
    [cos( seed/360 )], $
    [sin( seed/180 )]  ]

  ;Add new variable to loaded data object
  ;  Data is added in structure format as in tplot.  Metadata can be specified
  ;  with keyword and/or via the limit and dlimit structures (see yyy_ui_plugin_randomize).
  ;  Here example values are added for tree placement and coordinates.
  ok = loaded_data->addData(test_var, {x:t, y:d}, limit=0, dlimit=0, $
    mission='TEST MISSION', observatory='TEST OBS', instrument='TEST INST', $
    coordsys='gsm', units='eV')

  if ~ok then begin
    spd_ui_message, 'Error adding "'+test_var+'".', sb=status_bar, hw=history_window, /dialog, /dontshow
  endif else begin
    status_bar->update, 'Added "'+test_var+'".'
  endelse


end

