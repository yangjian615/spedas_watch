;+
;
;Purpose:
;  Output messages to the history window, status bar, and/or dialog message
; 
;Arguments:
;  message: string to be output
;  sb: status bar obj ref (optional)
;  hw: history window obj ref (optional) 
;  dialog: flag to pop-up dialog message (optional) 
; 
;Notes: 
;  _extra can be used to pass keywords to:
;     -history window
;     -dialog_message
; 
;-
pro spd_ui_message, message, sb=sb, hw=hw, dialog=dialog, $
                    _extra=_extra

    compile_opt idl2, hidden

  msg = string(message)

  ;output to the status bar
  if keyword_set(sb) && obj_valid(sb) && obj_isa(sb,'SPD_UI_MESSAGE_BAR') then begin
    sb->update, msg
  endif
  
  ;output to the history window
  if keyword_set(hw) && obj_valid(hw) && obj_isa(hw, 'SPD_UI_HISTORY')then begin
    tb = scope_traceback(/struct)
    prefix = tb[n_elements(tb)-2].routine + ': '
    hw->update, prefix + msg, _extra=_extra
  endif
  
  ;output to dialog message
  if keyword_set(dialog) then begin
    response=dialog_message(msg, /center, _extra=_extra)
  endif

  return

end ;---------------------------------------------
