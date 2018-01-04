;+
; NAME: EVA_SITL_FOMEDIT
; 
; COMMENT:
;   This widget allows the user to modify the segment he/she selected.
;   The information of the segment to be modified is store in the structure "segSelect".
;   When "Save" is chosen, the "segSelect" structure will be used to update FOM/BAK structures.
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2017-10-31 19:35:36 -0700 (Tue, 31 Oct 2017) $
; $LastChangedRevision: 24248 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_fomedit.pro $
;
PRO eva_sitl_FOMedit_event, ev
  widget_control, ev.top, GET_UVALUE=wid
  
  code_exit = 0
  segSelect = wid.segSelect; Each event will modify this "segSelect"
  
  idx = where(strmatch(tag_names(ev),'VALUE'),ct)
  if ct eq 1 then begin
    case size(ev.VALUE,/dimension) of
      0: evalue = ev.VALUE
      1: evalue = ev.VALUE[0]
      else: stop
    endcase
  endif
  
  case ev.id of
    wid.ssFOM: begin
      FOMvalue = (evalue < wid.fom_max_value) > wid.fom_min_value
      segSelect.FOM = FOMvalue
      end
    wid.sldStart: begin
      if n_elements(wid.wgrid) gt 1 then begin
        result = min(abs(wid.wgrid-evalue),segSTART)
        result = min(abs(wid.wgrid-segSelect.TE),segSTOP)
        len = segSTOP - segSTART
      endif else begin
        len = (segSelect.TE-evalue)/10.d0
      endelse
      txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
      widget_control, wid.lblBuffs, SET_VALUE=txtbuffs
      segSelect.TS = evalue
      end
    wid.sldStop: begin
      if n_elements(wid.wgrid) gt 1 then begin
        result = min(abs(wid.wgrid-segSelect.TS),segSTART)
        result = min(abs(wid.wgrid-evalue),segSTOP)
        len = segSTOP - segSTART
      endif else begin
        len = (evalue-segSelect.TS)/10.d0
      endelse
      txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
      widget_control, wid.lblBuffs, SET_VALUE=txtbuffs
      segSelect.TE = evalue
      end
    wid.txtDiscussion: begin
      widget_control, ev.id, GET_VALUE=new_discussion;get new discussion
      segSelect.DISCUSSION = new_discussion[0]
      comlen = string(strlen(new_discussion[0]),format='(I4)')
      widget_control, wid.lblDiscussion, SET_VALUE='COMMENT: '+comlen+wid.DISLEN 
      end
    wid.btnSave: begin
      print,'EVA: ***** EVENT: btnSave *****'
      eva_sitl_strct_update, segSelect,BAK=wid.state.pref.EVA_BAKSTRUCT
      eva_sitl_stack
      code_exit = 1
    end
    wid.btnCancel: begin
      print,'EVA: ***** EVENT: btnCancel *****'
      code_exit = 1 ; Do nothing
    end
    else:
  endcase
  
  if code_exit then begin
    device, set_graphics=wid.old_graphics
    tplot,verbose=0
    widget_control, ev.top, /destroy
  endif else begin
    eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, wid.state, /rehighlight
    str_element,/add,wid,'segSelect',segSelect
    widget_control, ev.top, SET_UVALUE=wid
  endelse
end

; INPUT:
;   STATE: state for cw_sitl; this information is needed to call >eva_sitl_update_board, wid.state, 1
PRO eva_sitl_FOMedit, state, segSelect, wgrid=wgrid
  if xregistered('eva_sitl_FOMedit') ne 0 then return
  
  ;//// user setting  /////////////////////////////
  dTfrac          = 0.5; fraction of the current time range --> range of time change
  scroll          = 1.0 ; how many seconds to be moved by sliders
  drag            = 1   ; use drag keyword for sliders?
  fom_min_value   = 2.0  ; min allowable value of FOM
  fom_max_value   = 255.0 ; max allowable value of FOM
  dislen          = ' characters (max 250)'; label for the Discussion Text Field
  ;////////////////////////////////////
  
  ; initialize
  device, get_graphics=old_graphics, set_graphics=6
  eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, state
  if n_elements(wgrid) eq 0 then message, "Need wgrid"
  
  time = timerange(/current)
  ts_limit = time[0]
  te_limit = time[1]
  idx = where(strmatch(strlowcase(tag_names(segSelect)),'ts_limit'),ct)
  if ct eq 1 then ts_limit = segSelect.TS_LIMIT 
  idx = where(strmatch(strlowcase(tag_names(segSelect)),'te_limit'),ct)
  if ct eq 1 then te_limit = segSelect.TE_LIMIT
  
  dTh = double(dTfrac)*(te_limit-ts_limit)
  Ts  = segSelect.TS
  Te  = segSelect.TE
  Tc  = 0.5*(Ts+Te)
  start_min_value = Ts-dTh > ts_limit
  start_max_value = Ts+dTh < Tc
  stop_min_value  = Te-dTh > Tc
  stop_max_value  = Te+dTh < te_limit
  
  if n_elements(wgrid) gt 1 then begin
    result = min(abs(wgrid-Ts),segSTART)
    result = min(abs(wgrid-Te),segSTOP)
    len = segSTOP - segSTART
  endif else begin
    len = (Te-Ts)/10.d0
  endelse
  
  
  wid = {STATE:state, segSelect:segSelect, SCROLL:scroll, OLD_GRAPHICS:old_graphics, DISLEN:dislen, $
    START_MIN_VALUE: start_min_value, STOP_MIN_VALUE: stop_min_value, FOM_MIN_VALUE: fom_min_value, $
    START_MAX_VALUE: start_max_value, STOP_MAX_VALUE: stop_max_value, FOM_MAX_VALUE: fom_max_value,$
    WGRID: wgrid }
    
  ; widget layout
  
  base = widget_base(TITLE='Edit FOM',/column)
  
  disable=0
  
  if (segSelect.BAK) and (n_tags(segSelect) eq 16) then begin
    str_element,/add,wid,'lblBuffs',-1L
    str_element,/add,wid,'sldStart',-1L
    str_element,/add,wid,'sldStop',-1L
    lblTitle  = widget_label(base,VALUE='SEGMENT STATUS INFO')
    baseSeg = widget_base(base,/column,/base_align_left,/frame)
    valPlay = (segSelect.INPLAYLIST) ? 'Yes' : 'No'
    valPend = (segSelect.ISPENDING) ? 'Yes' : 'No'
    lblID     = widget_label(baseSeg,VALUE='ID: '+strtrim(string(segSelect.DATASEGMENTID),2))
    lblFOM    = widget_label(baseSeg,VALUE='FOM: '+string(segSelect.FOM,format='(F7.3)'))
    lblStatus = widget_label(baseSeg,VALUE='STATUS:  '+segSelect.STATUS)
    lblPlay   = widget_label(baseSeg,VALUE='inPLAYLIST: '+valPlay)
    lblPend   = widget_label(baseSeg,VALUE='isPENDING : '+valPend)
    lblLengths= widget_label(baseSeg,VALUE='SEGLENGTHS: '+strtrim(string(segSelect.SEGLENGTHS),2))
    lblSrcID  = widget_label(baseSeg,VALUE='SOURCE-ID: '+segSelect.SOURCEID)
    lblDiscuss= widget_label(baseSeg,VALUE='DISCUSSION: '+segSelect.DISCUSSION)
    lblStart  = widget_label(baseSeg,VALUE='FIRST BUFFER: '+time_string(segSelect.TS))
    lblStop   = widget_label(baseSeg,VALUE='LAST BUFFER: '+time_string(segSelect.TE-10.d0))
    lblCreate = widget_label(baseSeg,VALUE='CREATE-TIME: '+segSelect.CREATETIME)
    lblFinish = widget_label(baseSeg,VALUE='FINISH-TIME: '+segSelect.FINISHTIME)
    lblNumEval= widget_label(baseSeg,VALUE='NUM-EVAL-CYCLES: '+strtrim(string(segSelect.NUMEVALCYCLES),2))
    lblParamID= widget_label(baseSeg,VALUE='PARAMETER-SET-ID:'+segSelect.PARAMETERSETID)
    disable = strmatch(strlowcase(segSelect.STATUS),'*finished*') 
    if disable then ssFOM = -1 else ssFOM = eva_slider(base,title=' FOM ',VALUE=segSelect.FOM,MAX_VALUE=255, MIN_VALUE=0) 
    str_element,/add,wid,'ssFOM',ssFOM
    txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
  endif else begin
    str_element,/add,wid,'ssFOM',eva_slider(base,title=' FOM ',VALUE=segSelect.FOM,MAX_VALUE=255, MIN_VALUE=0)
    txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
    str_element,/add,wid,'lblBuffs',widget_label(base,VALUE=txtbuffs)
    str_element,/add,wid,'sldStart',eva_slider(base,title='Start',$
      VALUE=Ts, MIN_VALUE=start_min_value, MAX_VALUE=start_max_value,  WGRID=wgrid, /time)
    str_element,/add,wid,'sldStop',eva_slider(base,title='Stop ',$
      VALUE=Te, MIN_VALUE=stop_min_value, MAX_VALUE=stop_max_value, WGRID=wgrid, /time)
    str_element,/add,wid,'drpStatus',-1L    
  endelse
  
  if disable then begin
    comment = 'This is a FINISHED segment. No need to edit.'
    txtDiscuss = -1
  endif else begin
    comlen = string(strlen(segSelect.DISCUSSION), format='(I4)')
    comment = 'COMMENT: '+comlen+wid.DISLEN
    txtDiscuss = widget_text(base,VALUE=segSelect.DISCUSSION,/all_events,/editable)
  endelse
  str_element,/add,wid,'lblDiscussion',widget_label(base,VALUE=comment)
  str_element,/add,wid,'txtDiscussion',txtDiscuss
  
  
  
  baseDeci = widget_base(base,/ROW)
  str_element,/add,wid,'btnSave',widget_button(baseDeci,VALUE='Save',ACCELERATOR = "Return",SENSITIVE=~disable)
  str_element,/add,wid,'btnCancel',widget_button(baseDeci,VALUE='Cancel')
  widget_control, base, /REALIZE
  
  ;-----------------
  ; WIDGET POSITION
  ;-----------------
  scr = get_screen_size()
  geo = widget_info(base,/geometry)
  basepos = state.pref.EVA_BASEPOS
  if basepos le 0 then begin
    xoffset = scr[0]*0.5-geo.xsize*0.5
  endif else begin
    xoffset = basepos
  endelse
  yoffset = scr[1]*0.5-geo.ysize*0.5
  widget_control, base, SET_UVALUE=wid, XOFFSET=xoffset, YOFFSET=yoffset
  xmanager, 'eva_sitl_FOMedit', base,GROUP_LEADER=state.GROUP_LEADER
END
