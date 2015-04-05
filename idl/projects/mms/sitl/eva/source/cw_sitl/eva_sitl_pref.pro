
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
  @eva_logger_com
  
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
      pref.EVA_BAKSTRUCT = ev.SELECT 
      widget_control, state.STATE_SITL.drpSave, SENSITIVE=(~ev.SELECT)
      end
    state.bgTestmode:  begin;{ID:0L, TOP:0L, HANDLER:0L, SELECT:0, VALUE:0 }
      pref.EVA_TESTMODE_SUBMIT = ev.SELECT
      end
    state.btnSplitNominal: begin
      val = mms_load_fom_validation()
      pref.EVA_SPLIT_SIZE = val.NOMINAL_SEG_RANGE[1]
      widget_control, state.fldSplit, SET_VALUE=strtrim(string(pref.EVA_SPLIT_SIZE),2)
      end
    state.btnSplitMaximum: begin
      val = mms_load_fom_validation()
      pref.EVA_SPLIT_SIZE = val.SEG_BOUNDS[1]
      widget_control, state.fldSplit, SET_VALUE=strtrim(string(pref.EVA_SPLIT_SIZE),2)
      end
    state.fldSplit: begin
      pref.EVA_SPLIT_SIZE = long(ev.VALUE)
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

  ; ----- GET STATE FROM EACH MODULE -----
  widget_control, widget_info(group_leader,find='eva_sitl'), GET_VALUE=state_sitl
  widget_control, widget_info(group_leader,find='eva_data'), GET_VALUE=state_data

  ; ----- STATE OF THIS WIDGET -----  
  state = {pref:state_sitl.PREF, state_sitl:state_sitl}
    
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitl_pref_event", $
    FUNC_GET_VALUE = "eva_sitl_pref_get_value", $
    PRO_SET_VALUE = "eva_sitl_pref_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1)
  str_element,/add,state,'mainbase',mainbase

  val = mms_load_fom_validation()
  str_nl = strtrim(string(val.nominal_seg_range[1]),2)
  str_ml = strtrim(string(val.seg_bounds[1]),2)
  str_cs = strtrim(string(state.PREF.EVA_SPLIT_SIZE),2)
  baseSplit = widget_base(mainbase,space=0,ypad=0,/ROW)
  str_element,/add,state,'fldSplit',cw_field(baseSplit,VALUE=str_cs,TITLE='Split Size: ',/ALL_EVENTS,XSIZE=7)
  str_element,/add,state,'btnSplitNominal',widget_button(baseSplit,VALUE=' Nominal Limit '+str_nl+' ')
  str_element,/add,state,'btnSplitMaximum',widget_button(baseSplit,VALUE=' Maximum Limit '+str_ml+' ')
  
    
  bsAdvanced = widget_base(mainbase,space=0,ypad=0,SENSITIVE=(state_data.USER_FLAG eq 3)); Super SITL only
    str_element,/add,state,'bsAdvanced',bsAdvanced
    str_element,/add,state,'bgAdvanced',cw_bgroup(bsAdvanced,'Enable advanced features (for Super SITL)',$
     /NONEXCLUSIVE,SET_VALUE=state.PREF.EVA_BAKSTRUCT)
  
  str_element,/add,state,'bgTestmode',cw_bgroup(mainbase,'Test Mode',$
     /NONEXCLUSIVE,SET_VALUE=state.PREF.EVA_TESTMODE_SUBMIT)


  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  RETURN, mainbase
END
