PRO eva_sitl_message_display_event, ev
  widget_control, ev.top, GET_UVALUE=wip
  exitcode=0
  
  case ev.id of
    wip.btnOK:exitcode=1
    else:
  endcase
  
  widget_control, ev.top, SET_UVALUE=wip
  if exitcode then widget_control, ev.top, /destroy
end


PRO eva_sitl_message_display, GROUP_LEADER=group_leader,VALUE=value
  if n_elements(value) eq 0 then value=' '
  
  base = widget_base(TITLE='SITL VALIDATION MESSAGE',/column,/frame)
  txt = widget_text(base, xsize=80, ysize=20, /SCROLL, value=value,/wrap)
  baseBtn = widget_base(base,/row)
    str_element,/add,wip,'btnOK',widget_button(baseBtn,VALUE='Close',xsize=60)

  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wip
  eva_dialog_place,base
  xmanager, 'eva_sitl_message_display', base,  /NO_BLOCK, GROUP_LEADER=group_leader
END

