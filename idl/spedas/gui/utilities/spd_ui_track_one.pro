;+
;Procedure:
;  spd_ui_track_one
;
;Purpose:
;  Switches on single-panel tracking by setting the appropriate flags
;  in the GUI's main storage structure.  This is a temporary solution
;  until the tracking options can be re-worked. 
;
;Calling Sequence:
;  spd_ui_track_one, infoptr
;
;Input:
;  infoptr:  Pointer to GUI's main storage structure.
;
;Output:
;  none
;
;Notes:
;  Moved from call sequence object.
;
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;
;-
pro spd_ui_track_one, infoptr
  if ~undefined(infoptr) && ptr_valid(infoptr) then begin
      (*infoptr).tracking = 1
      (*infoptr).trackall = 0
      (*infoptr).trackone = 1
      (*infoptr).trackingv = 1
      (*infoptr).trackingh = 1
      (*infoptr).drawObject->vBarOn
      (*infoptr).drawObject->hBarOn
      (*infoptr).drawObject->legendOn
      widget_control, (*infoptr).trackhmenu, set_button=1
      widget_control, (*infoptr).trackvmenu, set_button=1
      widget_control, (*infoptr).trackallmenu, set_button=0
      widget_control, (*infoptr).trackonemenu, set_button=1
      widget_control, (*infoptr).showpositionmenu,set_button=1
      widget_control, (*infoptr).trackMenu,set_button=1
  endif

end
