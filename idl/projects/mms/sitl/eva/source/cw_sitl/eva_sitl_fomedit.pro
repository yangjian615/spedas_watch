;+
; NAME: EVA_SITL_FOMEDIT
; 
; COMMENT:
;   This widget allows the user to modify the segment he/she selected.
;   The information of the segment to be modified is store in the structure "segSelect".
;   When "Save" is chosen, the "segSelect" structure will be used to update FOM/BAK structures.
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2015-05-07 15:47:03 -0700 (Thu, 07 May 2015) $
; $LastChangedRevision: 17514 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_fomedit.pro $
;
PRO eva_sitl_FOMedit_event, ev
  widget_control, ev.top, GET_UVALUE=wid
  
  code_exit = 0
  segSelect = wid.segSelect; Each event will modify this "segSelect"
   
  case ev.id of
    wid.ssFOM: begin
      FOMvalue = (ev.value < wid.fom_max_value) > wid.fom_min_value
      segSelect.FOM = FOMvalue
      end
    wid.sldStart: begin
      len = (segSelect.Te-ev.value)/10.d0
      txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
      widget_control, wid.lblBuffs, SET_VALUE=txtbuffs
      segSelect.TS = ev.value
      end
    wid.sldStop: begin
      len = (ev.value-segSelect.Ts)/10.d0
      txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
      widget_control, wid.lblBuffs, SET_VALUE=txtbuffs
      segSelect.TE = ev.value
      end
    wid.txtDiscussion: begin
      widget_control, ev.id, GET_VALUE=new_discussion;get new discussion
      segSelect.DISCUSSION = new_discussion[0]
      comlen = string(strlen(new_discussion[0]),format='(I4)')
      widget_control, wid.lblDiscussion, SET_VALUE='COMMENT: '+comlen+wid.DISLEN 
      end
    wid.btnSave: begin
      print,'EVA: ***** EVENT: btnSave *****'
      eva_sitl_strct_update, segSelect
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
    eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, segSelect.VAR, /rehighlight
    str_element,/add,wid,'segSelect',segSelect
    widget_control, ev.top, SET_UVALUE=wid
  endelse
end

; INPUT:
;   STATE: state for cw_sitl; this information is needed to call >eva_sitl_update_board, wid.state, 1
PRO eva_sitl_FOMedit, state, segSelect, wgrid=wgrid
  if xregistered('eva_sitl_FOMedit') ne 0 then return
  
  ;//// user setting  /////////////////////////////
  dTfrac          = 0.3; fraction of the current time range --> range of time change
  ;dTh             = 50.0 ; one half of the allowable range of time change.
  scroll          = 1.0 ; how many seconds to be moved by sliders
  drag            = 1   ; use drag keyword for sliders?
  fom_min_value   = 2.0  ; min allowable value of FOM
  fom_max_value   = 255.0 ; max allowable value of FOM
  dislen          = ' characters (max 250)'; label for the Discussion Text Field
  ;////////////////////////////////////

  ; initialize
  device, get_graphics=old_graphics, set_graphics=6
  eva_sitl_highlight, segSelect.TS, segSelect.TE, segSelect.FOM, segSelect.VAR
  if n_elements(wgrid) eq 0 then message, "Need wgrid"
  
  time = timerange(/current)
  dTh = double(dTfrac)*(time[1]-time[0])
  ;dTh = double(dTh)
  Ts  = segSelect.TS
  Te  = segSelect.TE
  Tc  = 0.5*(Ts+Te)
  start_min_value = Ts-dTh > time[0]
  start_max_value = Ts+dTh < Tc
  stop_min_value  = Te-dTh > Tc
  stop_max_value  = Te+dTh < time[1]
  len = (Te-Ts)/10.d0
  wid = {STATE:state, segSelect:segSelect, SCROLL:scroll, OLD_GRAPHICS:old_graphics, DISLEN:dislen, $
    START_MIN_VALUE: start_min_value, STOP_MIN_VALUE: stop_min_value, FOM_MIN_VALUE: fom_min_value, $
    START_MAX_VALUE: start_max_value, STOP_MAX_VALUE: stop_max_value, FOM_MAX_VALUE: fom_max_value,$
    WGRID: wgrid }
    
  ; widget layout
  sensitive = (segSelect.BAK eq 0)
  base = widget_base(TITLE='Edit FOM',/column);,/modal,group_leader=group_leader)
  str_element,/add,wid,'ssFOM',eva_slider(base,title=' FOM ',VALUE=segSelect.FOM,MAX_VALUE=255, MIN_VALUE=0)
  txtbuffs = 'SEGMENT SIZE: '+string(len,format='(I5)')+' buffers'
  str_element,/add,wid,'lblBuffs',widget_label(base,VALUE=txtbuffs)
  str_element,/add,wid,'sldStart',eva_slider(base,title='Start',SENSITIVE=sensitive,$
    VALUE=Ts, MIN_VALUE=start_min_value, MAX_VALUE=start_max_value,  WGRID=wgrid, /time)
  str_element,/add,wid,'sldStop',eva_slider(base,title='Stop ',SENSITIVE=sensitive,$
    VALUE=Te, MIN_VALUE=stop_min_value, MAX_VALUE=stop_max_value, WGRID=wgrid, /time)
  comlen = string(strlen(segSelect.DISCUSSION), format='(I4)')
  str_element,/add,wid,'lblDiscussion',widget_label(base,VALUE='COMMENT: '+comlen+wid.DISLEN)
  str_element,/add,wid,'txtDiscussion',widget_text(base,VALUE=segSelect.DISCUSSION,/all_events,/editable)
  


    
  baseDeci = widget_base(base,/ROW)
  str_element,/add,wid,'btnSave',widget_button(baseDeci,VALUE='Save',ACCELERATOR = "Return")
  str_element,/add,wid,'btnCancel',widget_button(baseDeci,VALUE='Cancel')
  widget_control, base, /REALIZE
  scr = get_screen_size()
  geo = widget_info(base,/geometry)
  widget_control, base, SET_UVALUE=wid, XOFFSET=scr[0]*0.5-geo.xsize*0.5, YOFFSET=scr[1]*0.5-geo.ysize*0.5
  xmanager, 'eva_sitl_FOMedit', base,GROUP_LEADER=state.GROUP_LEADER
END
