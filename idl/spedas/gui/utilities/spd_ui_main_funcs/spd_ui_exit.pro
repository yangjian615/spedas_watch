;+
;
;  Name: SPD_UI_EXIT
;  
;  Purpose: Exits the GUI
;  
;  Inputs: The info structure from the main gui
;          The event that led to this function call
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_main_funcs/spd_ui_exit.pro $
;-
pro spd_ui_exit,event,info=info

  compile_opt idl2
  
 Print, 'Main SPEDAS GUI exited'
  IF N_Elements(info) NE 0 THEN BEGIN
  
    if obj_valid(info.historyWin) then begin
      info.historyWin->saveHistoryFile
    endif
  
    obj_destroy,info.historywin
    Obj_Destroy,info.statusBar
    Obj_Destroy,info.pathBar
    obj_destroy,info.drawObject
    obj_destroy,info.loadedData
    obj_destroy,info.windowStorage
  ENDIF
  Widget_Control, event.TOP, /Destroy
 ; if logical_true(!journal) then Journal
 ; WHILE !D.Window NE -1 DO WDelete, !D.Window
  RETURN
  
end
