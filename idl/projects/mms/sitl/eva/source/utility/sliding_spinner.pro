;+
; NAME:
;   sliding_spinner
;
; PURPOSE:
;   A compound 'spinner' widget for editing numerical values.
;   Consists of a text field for display and direct editing of the value and 
;   a slider for rapid editing of the value.
;
; CALLING SEQUENCE:
;   Result = SLIDING_SPINNER(parent)
;
; KEYWORD PARAMETERS:
;    VALUE: Initial value (string)
;    TIME:  1 if the value is time. 0 if the value is not time.
;    LABEL: String to be used as the widget's label
;    XLABELSIZE: Size of the text label in points
;    TEXT_BOX_SIZE: Size of the text box in # of characters
;    MAX_VALUE: The maximum allowed value for the spinner (optional)
;    MIN_VALUE: The minimum allowed value for the spinner (optional)
;    
; EVENT STRUCTURE:
;   When the field is modified either directly or by the slider,
;   the following event is returned:
;   {ID: id, TOP: top, HANDLER: handler, VALUE: value, VALID: valid, TYPE: type}
;
;   VALUE: formatted, double precision number from this widget
;   VALID: 0 if value is not a recogizable/convertable number, or if buttons
;         attempt to go outside min/max range, 1 otherwise
;   TYPE: indicates the type of specific event being reported. Based on TYPE of widget_text event
;   'BASE'           :-1, 
;   'WIDGET_TEXT_CH' : 0, 
;   'WIDGET_TEXT_STR': 1, 
;   'WIDGET_TEXT_DEL': 2, 
;   'WIDGET_TEXT_SEL': 3,
;   'SLIDER'         : 4 
;         
;         
PRO sliding_spinner_set_value, id, strValue ; in this case, a string
  compile_opt idl2, hidden
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  numValue = state.time_set ? str2time(strValue) : double(strValue)
  widget_control, state.slider, set_value=numValue
  widget_control, state.text, set_value=strValue, input_focus=1
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION sliding_spinner_get_value, id
  compile_opt idl2, hidden
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION sliding_spinner_event, ev
  compile_opt idl2, hidden
  parent=ev.handler; the base of this compound widget
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
    
  case ev.id of
    state.text: begin
      if tag_names(ev,/Structure_Name) ne 'WIDGET_TEXT_SEL' then begin
        widget_control,state.text,get_value=strValue
        numValue = state.time_set ? str2time(strValue) : double(strValue)
      endif else begin
        numValue = state.value
      endelse
      type = ev.type; return type ('WIDGET_TEXT_CH':0, 'WIDGET_TEXT_STR':1, 'WIDGET_TEXT_DEL':2, 'WIDGET_TEXT_SEL':3      
      end
    state.slider: begin
      numValue=ev.value
      type = 4
      end
    else: begin
      numValue = state.value
      type = -1
      end
  endcase

  valid = is_numeric(string(numValue))
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:ev.handler, VALUE:double(numValue), VALID:valid, TYPE:type }  
END

FUNCTION sliding_spinner, parent,          $
  DRAG = drag,                      $
  LABEL=label_set,                      $
  VALUE=strValue,                       $
  XLABELSIZE=label_size_set,            $
  TEXT_BOX_SIZE=text_box_size,          $
  MAX_VALUE=max_value_set,              $
  MIN_VALUE=min_value_set,              $
  SCROLL=scroll,                        $
  ;UNIT_VALUE = unit_value_set,          $ 
  TIME=time_set,                        $
  FRAME=frame,                          $
  XPAD=xpad,                            $
  YPAD=ypad,                            $
  SENSITIVE=sensitive,$
  _EXTRA=_extra
  
  compile_opt idl2, hidden
  
  ;----- Initialize -----
  

  ; convert input string to number
  if keyword_set(time_set) then begin; input is time string
    numValue = keyword_set(strValue) ? str2time(strValue) : 0
  endif else begin
    numValue = keyword_set(strValue) ? double(strValue) : 0
    time_set = 0
  endelse
  
  tboxsize = keyword_set(text_box_size) ? text_box_size : 20
  
  
  ; if value has been given, ensure max and min are moved to allow it
  if n_elements(max_value_set) then begin
    maxValue = keyword_set(strValue) ? (double(max_value_set) > numValue) : double(max_value_set)
  endif else maxValue = !values.d_nan
  if n_elements(min_value_set) then begin
    minvalue = keyword_set(strValue) ? (double(min_value_set) < numValue) : double(min_value_set)
  endif else minValue = !values.d_nan
  
  state = {VALUE: numValue, MAXVALUE: maxValue, MINVALUE: minValue, TIME_SET:time_set}
    
  ;----- Widget Layout -----
  base = widget_base(parent,/ROW,XPAD=XPAD,YPAD=YPAD,FRAME=frame,$
    EVENT_FUNC     = "sliding_spinner_event", $
    FUNC_GET_VALUE = "sliding_spinner_get_value", $
    PRO_SET_VALUE  = "sliding_spinner_set_value")
    str_element,/add,state,'base',base
    
  if keyword_set(label_set) then begin
    str_element,/add,state,'label',widget_label(base,VALUE=label_set,XSIZE=label_size_set)
  endif
    
  str_element,/add,state,'text', widget_text(base, /editable, /all_events,   $
    IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'],    $
    VALUE=strValue, XSIZE=tboxsize, SENSITIVE=sensitive)
    
  str_element,/add,state,'slider',widget_slider(base,DRAG=drag,MAX=maxValue,MIN=minValue,$
    VALUE=numValue,/sup,SCROLL=scroll,SENSITIVE=sensitive)



  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=state, /NO_COPY
  
  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.  
  RETURN, base
END