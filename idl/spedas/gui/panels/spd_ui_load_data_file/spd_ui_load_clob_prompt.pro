;+ 
;
;WARNING:
;  THIS ROUTINE IS DEPRECATED.  PLEASE USE SPD_UI_PROMPT_WIDGET, INSTEAD
;
;
;NAME:  
;  spd_ui_load_clob_prompt
;  
;PURPOSE:
;  Widget for prompting user to decide whether existing GUI variables should be
;  clobbered.  Returns a string ('yes', 'yesall', 'no', 'noall') depending on
;  which button the user has clicked.
;  
;CALLING SEQUENCE:
;  answer = spd_ui_load_clob_prompt(gui_id, historyWin, varname)
;  
;INPUT:
;  gui_id: Id of top level base widget from calling program.
;  historyWin: The variable storing the history window object reference.
;  varname: The name of the variable for which we're prompting the user to 
;           overwrite. 
;            
;KEYWORDS:
;  none
;        
;OUTPUT:
;  A string that represents which button was clicked by the user.
;
;--------------------------------------------------------------------------------


pro spd_ui_load_clob_prompt_event, event

  compile_opt idl2, hidden
  
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      x=state.gui_id
      histobj=state.historywin
    endif
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
       /noname, /center, title='Error in Load Data Clobber Propmt.')
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    if widget_valid(x) && obj_valid(histobj) then begin 
      spd_gui_error,x,histobj
    endif
    RETURN
  ENDIF

  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'SPD_UI_LOAD_DATA: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'NO': *state.answer = 'no'
    'NOALL': *state.answer = 'noall'
    'YES': *state.answer = 'yes'
    'YESALL': *state.answer = 'yesall'
    ELSE: dprint,  'Not yet implemented'
  ENDCASE

  Widget_Control, event.top, Set_UValue=state, /No_Copy
  Widget_Control, event.top, /Destroy

  RETURN
end

function spd_ui_load_clob_prompt, gui_id, historyWin, varname

  compile_opt idl2, hidden
  
  tlb = widget_base(/col, title='LOAD DATA: Variable already exists.', $
                    group_leader=gui_id, /modal, /base_align_center)
  
  text=['The variable ' + strupcase(varname) + ' already exists.  Do you want to ' + $
  'overwrite it with the new variable?', '', 'If you ' + $
  'click "No", the new ' + strupcase(varname) + ' will not be loaded.']

  textBase = widget_text(tlb, value=text, XSize=80, YSize=4)                  
  buttonBase = widget_base(tlb, /row, /align_center)
  
  yesButton = widget_button(buttonBase, value=' Yes ', uvalue='YES', XSize=80, $
                            tooltip='Overwrite '+varname+'.')
  yesAllButton = widget_button(buttonBase, value=' Yes to All ', uvalue='YESALL', $
                               XSize=80, tooltip='Automatically overwrite ' + $
                               'variables for any other duplicates.')
  noButton = widget_button(buttonBase, value=' No ', uvalue='NO', XSize=80, $
                           tooltip=varname+' will not be loaded.')
  noAllButton = widget_button(buttonBase, value=' No to All ', uvalue='NOALL', $
                              XSize=80, tooltip=varname+'Makes sure no existing' + $
                              'variables are overwritten during this load.')
  
  answer = ptr_new('')
  
  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin, answer:answer}
  
  centertlb, tlb
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize
  XManager, 'spd_ui_load_clob_prompt', tlb, /No_Block  
  
  return, *answer
end
