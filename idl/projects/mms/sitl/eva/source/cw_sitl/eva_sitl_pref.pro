
PRO eva_sitl_pref_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ;eva_sitl_update_board, state, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitl_pref_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY  
  return, ret
END

FUNCTION eva_sitl_pref_event, ev
  compile_opt idl2
  @eva_sitl_com
  @moka_logger_com
  
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif
  
  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  if n_tags(state) eq 0 then return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  pref = state.pref
  
  ;-----
  case ev.id of
    state.bgAdvanced:  begin;{ID:0L, TOP:0L, HANDLER:0L, SELECT:0, VALUE:0 }
      pref.ENABLE_ADVANCED = ev.SELECT 
      widget_control, state.MODULE_STATE.drpSave, SENSITIVE=(~ev.SELECT)
      end
    else:
  endcase
  ;-----
  
  str_element,/add,state,'pref',pref
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitl_pref, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  
  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitl_pref'
  if not (keyword_set(title)) then title='   SITL   '

  ; ----- GET CURRENT PREFERENCES FROM THE MAIN MODULE -----
  widget_control, widget_info(group_leader,find='eva_sitl'), GET_VALUE=module_state
  state = {pref:module_state.PREF, module_state:module_state}
  
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitl_pref_event", $
    FUNC_GET_VALUE = "eva_sitl_pref_get_value", $
    PRO_SET_VALUE = "eva_sitl_pref_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1)
  str_element,/add,state,'mainbase',mainbase

  bsAdvanced = widget_base(mainbase,space=0,ypad=0,SENSITIVE=(module_state.PREF.user_flag ge 3))
    str_element,/add,state,'bsAdvanced',bsAdvanced
    str_element,/add,state,'bgAdvanced',cw_bgroup(bsAdvanced,'Enable advanced features (for Super SITL)',$
     /NONEXCLUSIVE,SET_VALUE=state.PREF.ENABLE_ADVANCED)


  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  RETURN, mainbase
END
