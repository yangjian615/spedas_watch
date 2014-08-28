;+
;Procedure:
;  yyy_ui_plugin_randomize
;
;Purpose:
;  This is an example of a core routine for GUI plugins.  It can be called
;  by a plugin to perform an operation and re-called later to reproduce
;  that operation when a GUI document is opened.  See yyy_ui_plugin for  
;  an example of its usage.
;
;Calling Sequence:
;  yyy_ui_plugin_randomize, loaded_data, history_window, status_bar, 
;                           names=names, trange=trange
;
;Input:
;  loaded_data:  GUI loaded data object
;  history_window:  GUI history window object
;  status_bar:  GUI status bar object
;  names:  (string) Array of names of specifying which variables in
;                   the loaded data object are to be operated on.  
;  trange:  (double) Two element array specifying a time range [tmin,tmax].
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/api_examples/plugin_menu/yyy_ui_plugin_randomize.pro $
;
;-
pro yyy_ui_plugin_randomize,$ ;API Required Inputs
                             loaded_data, history_window, status_bar, _extra=_extra, $
                              ;Inputs specific to this routine
                             names=names, trange=trange
                             

  compile_opt idl2, hidden


  ;loop over selected variables
  for i=0, n_elements(names)-1 do begin

    name = names[i]

    ;Get pointers to data and metadata
    ;----------------------------------------------
    ;  The limit and dlimit structures store metadata and are analagous
    ;  to the structures used in tplot.
    loaded_data->GetVarData, name=name, time=t, data=d, yaxis=y, limit=l, dlimit=dl


    ;Perform operation
    ;----------------------------------------------
    ;  This example multiplies the data by a scaled random factor
    
    ;find data within time range
    idx = where(*t ge trange[0] and *t le trange[1], n)
    if n lt 2 then begin
      ;send message to status bar and history window
      spd_ui_message, 'Too few points in time range to randomize "'+name+'".', sb=status_bar, hw=history_window
      return
    endif

    ;multiply by scaled random factor
    scale = ceil( alog10(max(*d)-min(*d)) /2. )
    dim = size(*d,/dim)
    rand_data = *d * randomu(42,dim) * scale

    ;copy to new array
    data = *d
    data[idx,*] = rand_data[idx,*]


    ;Add new variable to loaded data object
    ;----------------------------------------------
    ;  Data is added in structure format as in tplot.  Metadata can be added
    ;  with the limit and dlimit  keywords and/or via keywords (see yyy_ui_plugin_add).
    ;  Here the original variable's metadata is transfered to the new variable.
    ok = loaded_data->addData(name+'_rand', {x:*t, y:data, v:*y}, limit=*l, dlimit=*dl)

    if ~ok then begin
      ;send message to status bar and history window and display a dialog message
      spd_ui_message, 'Error randomizing "'+name+'".', sb=status_bar, hw=history_window, /dialog
    endif else begin
      status_bar->update, 'Variable(s) "randomized".'
    endelse

  endfor



end
