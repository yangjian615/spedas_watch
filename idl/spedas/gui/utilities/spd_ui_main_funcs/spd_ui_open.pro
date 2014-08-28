;+
;
;  Name: SPD_UI_OPEN
;
;  Purpose: Opens a spedas document
;
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_main_funcs/spd_ui_open.pro $
;-
pro spd_ui_open,info

  compile_opt idl2
  
  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  info.ctrl = 0
  
  ;query if users want to delete data.
  del_text=dialog_message('Loading a document will remove all existing plots and pages,' +ssl_newline() +'but you can retain the data.'+ssl_newline() +ssl_newline()$
    +'Do you want to delete the previous data sets?' +ssl_newline()+ssl_newline()+'(''Yes'' is strongly recommended.)' $
    ,/question, /cancel, /center, title='Remove previous data?')
  if strlowcase(del_text) eq 'yes' then begin
    nodelete = 0
    msg = 'Previous data will be deleted.'
    spd_ui_message, msg, sb=info.statusBar, hw=info.historywin
  endif else if strlowcase(del_text) eq 'no' then begin
    nodelete = 1
    msg = 'Previous data will NOT be deleted.'
    spd_ui_message, msg, sb=info.statusBar, hw=info.historywin
  endif else begin
    msg = 'User canceled the loading of a SPEDAS document.'
    spd_ui_message, msg, sb=info.statusBar, hw=info.historywin
    return
  endelse
  
  ; we want 'Open SPEDAS Document' to remember current directory
  if is_string(info.MainFileName) then currentpath = file_dirname(info.MainFileName)
  
  fileName = Dialog_Pickfile(Title='Open SPEDAS Document', $
    Filter='*.tgd', Dialog_Parent=info.master,/must_exist,path=currentpath)
  IF(Is_String(fileName)) THEN BEGIN
    open_spedas_document,info=info,filename=fileName,$
      statusmsg=statusmsg,statuscode=statuscode,nodelete=nodelete
    IF (statuscode LT 0) THEN BEGIN
      ;report an any errors caught in open_spedas_document
      dummy=error_message(statusmsg,/ERROR,/CENTER)
    ENDIF ELSE BEGIN
      ; If successful, sensitize data controls
      FOR i=0, N_Elements(info.dataButtons)-1 DO Widget_Control, info.dataButtons[i], sensitive=1
      ; Put filename in title bar
      activeWindow=info.windowStorage->GetActive()
      activeWindow->GetProperty, Name=name
      ;result=info.windowMenus->SetFilename(name, filename)
      info.mainFileName=filename
      info.gui_title = filename
    ENDELSE
    info.statusBar->Update, statusmsg
    info.historywin->Update,statusmsg
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Invalid Filename'
  ENDELSE
  
  
end
