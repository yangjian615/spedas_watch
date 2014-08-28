;+
;Procedure:
;  yyy_ui_plugin_delete
;
;Purpose:
;  This is an example of a core routine for GUI plugins.  It can be called
;  by a plugin to perform an operation and re-called later to reproduce
;  that operation when a GUI document is opened.  See yyy_ui_plugin for  
;  an example of its usage.
;
;Calling Sequence:
;  yyy_ui_plugin_add, loaded_data, history_window, status_bar
;
;Input:
;  loaded_data:  GUI loaded data object
;  history_window:  GUI history window object
;  status_bar:  GUI status bar object
;
;Output:
;  none
;
;API Requirements:
;  -Plugin routines must take the loaded data, history window, and status bar
;   objects as arguments (in that order) and must include the _extra keyword.
;  -All other inputs must be specified in keyword format.
;
;Notes:  
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-14 12:17:24 -0800 (Fri, 14 Feb 2014) $
;$LastChangedRevision: 14382 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/api_examples/plugin_menu/yyy_ui_plugin_add.pro $
;
;-
pro yyy_ui_plugin_add,$ ;API Required Inputs
                       loaded_data, history_window, status_bar, _extra=_extra
                        ;No other inputs needed for this example

  compile_opt idl2, hidden

  
  ;Create simple test variable
  ;----------------------------------------------
  test_var = 'test_var'
  status_bar->update, 'Adding test variable: '+test_var

  seed = dindgen(1e4)

  t = seed + time_double('2007-03-23/00')

  d = [ [sin( seed/360 )], $
        [cos( seed/360 )], $
        [sin( seed/180 )]  ]

  ;Add new variable to loaded data object
  ;----------------------------------------------
  ;  Data is added in structure format as in tplot.  Metadata can be specified
  ;  with keyword and/or via the limit and dlimit structures (see yyy_ui_plugin_randomize).
  ;  Here example values are added for tree placement and coordinates.
  ok = loaded_data->addData(test_var, {x:t, y:d}, limit=0, dlimit=0, $
    mission='TEST MISSION', observatory='TEST OBS', instrument='TEST INST', $
    coordsys='gsm', units='eV')

  if ~ok then begin
    ;send message to status bar and history window and display a dialog message
    spd_ui_message, 'Error adding "'+test_var+'".', sb=status_bar, hw=history_window, /dialog, /dontshow
  endif else begin
    status_bar->update, 'Added "'+test_var+'".'
  endelse


end

