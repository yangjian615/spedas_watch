; This is the event-handler for the eva_sitl_FOMedit widget.
; The widget allows the user to modify the segment he/she selected.
; The information of the segment to be modified is store in the structure "segSelect".
; The event-handler will basically modify this "segSelect" except that "Save" 
; will pass segSelect to update FOM/BAK structures.
PRO eva_sitl_FOMedit_event, ev
  @moka_logger_com
  widget_control, ev.top, GET_UVALUE=wid
  
  code_exit = 0
  segSelect = wid.segSelect; Each event will modify this "segSelect"
   
  case ev.id of
    wid.ssFOM: begin
      if (ev.type eq 0) or (ev.type eq 4) then begin; (0: text change; 4: slider change)
        FOMvalue = (ev.value < wid.fom_max_value) > wid.fom_min_value
        if ev.type eq 4 then widget_control,wid.ssFOM, SET_VALUE=strtrim(string(FOMvalue),2)
        segSelect.FOM = FOMvalue
      endif
    end
    wid.ssStart: begin
      if (ev.type eq 0) or (ev.type eq 4) then begin
        if ev.type eq 4 then widget_control,wid.ssStart, SET_VALUE=time_string(ev.value)
        segSelect.TS = ev.value
      endif
    end
    wid.ssStop: begin
      if (ev.type eq 0) or (ev.type eq 4) then begin
        if ev.type eq 4 then widget_control,wid.ssStop, SET_VALUE=time_string(ev.value)
        segSelect.TE = ev.value
      endif
    end
    wid.btnSave: begin
      log.o,'***** EVENT: btnSave *****'
      eva_sitl_strct_update, segSelect
      eva_sitl_stack
      code_exit = 1
    end
    wid.btnCancel: begin
      log.o,'***** EVENT: btnCancel *****'
      code_exit = 1 ; Do nothing
    end
    else:
  endcase
  
  if code_exit then begin
    device, set_graphics=wid.old_graphics
    tplot,verbose=0
;    eva_sitl_update_board, wid.state, 1
    widget_control, ev.top, /destroy
  endif else begin
    eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, /rehighlight
    str_element,/add,wid,'segSelect',segSelect
    ;    eva_sitl_update_board, wid.state, 1      ;.................   update dashboard
    widget_control, ev.top, SET_UVALUE=wid
  endelse
end

; This procedure provides a GUI for editing a segment/FOM.
; INPUT:
;   STATE: state for cw_sitl; this information is needed to call >eva_sitl_update_board, wid.state, 1
PRO eva_sitl_FOMedit, state, segSelect
  if xregistered('eva_sitl_FOMedit') ne 0 then return
  
  ;//// user setting  /////////////////////////////
  dTh             = 3600.0 ; one half of the allowable range of time change.
  scroll          = 10.0 ; how many seconds to be moved by sliders
  drag            = 1   ; use drag keyword for sliders?
  fom_min_value   = 2.0  ; min allowable value of FOM
  fom_max_value   = 255.0 ; max allowable value of FOM
  ;////////////////////////////////////

  ; initialize
  device, get_graphics=old_graphics, set_graphics=6
  eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM
  Ts  = segSelect.TS
  Te  = segSelect.TE
  Tc  = 0.5*(Ts+Te)
  start_min_value = Ts-dTh
  start_max_value = Ts+dTh < Tc
  stop_min_value  = Te-dTh > Tc
  stop_max_value  = Te+dTh
  wid = {STATE:state, segSelect:segSelect, SCROLL:scroll, OLD_GRAPHICS:old_graphics, $
    START_MIN_VALUE: start_min_value, STOP_MIN_VALUE: stop_min_value, FOM_MIN_VALUE: fom_min_value, $
    START_MAX_VALUE: start_max_value, STOP_MAX_VALUE: stop_max_value, FOM_MAX_VALUE: fom_max_value }
    
  ; widget layout
  sensitive = (segSelect.BAK eq 0)
  base = widget_base(TITLE='Edit FOM',/column);,/modal,group_leader=group_leader)
  str_element,/add,wid,'ssFOM',sliding_spinner(base,LABEL='FOM',VALUE=strtrim(string(segSelect.FOM),2),$
    MAX_VALUE=255, MIN_VALUE=0, DRAG=drag, XLABELSIZE=40)
  str_element,/add,wid,'ssStart',sliding_spinner(base,LABEL='START',VALUE=time_string(Ts),/time,$
    MAX_VALUE=start_max_value, MIN_VALUE=start_min_value,DRAG=drag,SCROLL=scroll,XLABELSIZE=40,SENSITIVE=sensitive)
  str_element,/add,wid,'ssStop',sliding_spinner(base,LABEL='STOP',VALUE=time_string(Te),/time,$
    MAX_VALUE=stop_max_value, MIN_VALUE=stop_min_value,DRAG=drag,SCROLL=scroll,XLABELSIZE=40,SENSITIVE=sensitive)
  baseDeci = widget_base(base,/ROW)
  str_element,/add,wid,'btnSave',widget_button(baseDeci,VALUE='Save',ACCELERATOR = "Return")
  str_element,/add,wid,'btnCancel',widget_button(baseDeci,VALUE='Cancel')
  widget_control, base, /REALIZE
  scr = get_screen_size()
  geo = widget_info(base,/geometry)
  widget_control, base, SET_UVALUE=wid, XOFFSET=scr[0]*0.5-geo.xsize*0.5, YOFFSET=scr[1]*0.5-geo.ysize*0.5
  xmanager, 'eva_sitl_FOMedit', base,GROUP_LEADER=state.GROUP_LEADER
END
