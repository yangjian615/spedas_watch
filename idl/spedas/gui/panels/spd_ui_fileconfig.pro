;+
;NAME:
; spd_ui_fileconfig
;
;PURPOSE:
; A widget that allows the user to set some of the fields in the
; !spedas system variable: Also allows the user to set the spedas
; configuration text file, and save it
;
;HISTORY:
; 17-may-2007, jmm, jimm@ssl.berkeley.edu
; 2-jul-2007, jmm, 'Add trailing slash to data directories, if necessary
; 5-may-2008, cg, removed text boxes and replaced with radio buttons or 
;                 pulldowns, fixed reset to default
; 10-aug-2011, lphilpott, Added option to set a template to load on startup of gui. Changed layout of widgets
;              slightly to make things line up in both windows and linux.
; 24-oct-2013 clr, removed graphic buttons and goes wind and istp code. panel is now tabbed
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/panels/spd_ui_fileconfig.pro $
;--------------------------------------------------------------------------------

;SAVE this routine in the event we want to reinstall the graphics buttons
;pro spd_ui_fileconfig_set_draw,state,renderer;;
;
;  if renderer eq 0 && $
;     strlowcase(!VERSION.os_family) eq 'windows' then begin
;    retain = 2
;  endif else begin
;    retain = 1
;  endelse;

;  *state.drawWinPtr->getProperty,current_zoom=cz,virtual_dimensions=virtual_dimensions
;  dimensions = virtual_dimensions / cz 
;  widget_control,*state.drawIdPtr,/destroy
;  *state.drawIdPtr = WIDGET_DRAW(state.graphBase,/scroll,xsize=dimensions[0],ysize=dimensions[1],$
;                            x_scroll_size=state.screenSize[0],y_scroll_size=state.screenSize[1], $
;                            Frame=3, Motion_Event=1, /Button_Event,keyboard_events=2,graphics_level=2,$
;                            renderer=renderer,retain=retain,/expose_events)
;  widget_control,*state.drawIdPtr,get_value=drawWin

  ;replace the cursor on non-windows system
  ;The cursor also needs to be reset when a new window is created.
  ;ATM This only happens when switching between hardware & software render modes and on init
;  if strlowcase(!version.os_family) ne 'windows' then begin
;    spd_ui_set_cursor,drawWin
;  endif
 
;  *state.drawWinPtr = drawWin 
;  state.drawObject->setProperty,destination=drawWin
;  state.drawObject->setZoom,cz
;  state.drawObject->draw
 
 ; drawWin->setCurrentZoom,cz
;  !SPD_GUI.renderer = renderer

;end

;--------------------------------------------------------------------------------

PRO spd_ui_fileconfig_load_template, fileName, topid, statusBar
  
  if(Is_String(fileName)) then begin
    open_spedas_template,template=template,filename=fileName,$
        statusmsg=statusmsg,statuscode=statuscode
    if (statuscode LT 0) then begin
        ok=dialog_message(statusmsg,/ERROR,/CENTER)
        statusBar->Update, 'Error: '+statusmsg
    endif else begin
      !SPD_GUI.templatepath = fileName
      tmppathid = widget_info(topid, find_by_uname='TMPPATH')
      widget_control, tmppathid,set_value=filename
      !SPD_GUI.windowStorage->setProperty,template=template
    ENDELSE
  ENDIF ELSE BEGIN
    statusBar->Update, 'Failed to load template: invalid filename'
  ENDELSE     

END

;--------------------------------------------------------------------------------

PRO spd_ui_fileconfig_init_struct,state,struct

  compile_opt idl2,hidden

  widget_control,state.localdir,set_value=struct.local_data_dir
  widget_control,state.remotedir,set_value=struct.remote_data_dir
  
  if struct.no_download eq 1 then begin
    widget_control,state.nd_off_button,set_button=1
  endif else begin
    widget_control,state.nd_on_button,set_button=1
  endelse
  
  if struct.no_update eq 1 then begin
    widget_control,state.nu_off_button,set_button=1
  endif else begin
    widget_control,state.nu_on_button,set_button=1
  endelse
  
  widget_control,state.v_droplist,set_combobox_select=struct.verbose

END

;--------------------------------------------------------------------------------

PRO spd_ui_fileconfig_event, event
  ; Get state structure from the base level 
  Widget_Control, event.handler, Get_UValue=state, /No_Copy
 
  ; get the user value of the widget that caused this event
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg  
    state.statusbar->update,'Error in File Config.' 
    state.historywin->update,'Error in File Config.'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  Widget_Control, event.id, Get_UValue = uval
  
  CASE uval OF
    'LOCALBROWSE':BEGIN

      widget_control, state.localDir, get_value=currentDir
      if currentDir ne '' then path = file_dirname(currentDir)
      dirName = Dialog_Pickfile(Title='Choose a Local Data Directory:', $
      Dialog_Parent=event.top,path=currentDir, /directory); /fix_filter doesn't seem to make a difference on Windows. Does on unix.  
      IF is_string(dirName) THEN BEGIN
          !SPEDAS.local_data_dir = dirName
          widget_control, state.localDir, set_value=dirName             
      ENDIF ELSE BEGIN
          ok = dialog_message('Selection is not a directory',/center)
      ENDELSE
      
    END
    
    'LOCALDIR': BEGIN
    
        widget_control, state.localDir, get_value=currentDir
        !spedas.local_data_dir = currentDir

    END
 
     'REMOTEDIR': BEGIN
    
        widget_control, state.remoteDir, get_value=currentDir
        !spedas.remote_data_dir = currentDir

    END
    
    'VERBOSE': BEGIN

       !spedas.verbose = long(widget_info(state.v_droplist,/combobox_gettext))

    END
    
    
    'USETMP': BEGIN

       btnid = widget_info(event.top,find_by_uname='TMPBUTTON')
       usetemplate = widget_info(btnid, /button_set)
       widget_control, (widget_info(event.top,find_by_uname='TMPPATHBASE')), sensitive=usetemplate
       if usetemplate then begin
       ; if the user turns on template, then load it
         tmppathid = widget_info(event.top, find_by_uname='TMPPATH')
         widget_control, tmppathid, get_value=filename
         if filename ne '' then spd_ui_fileconfig_load_template, filename, event.top, state.statusBar
         state.historywin->update,'Using template ' + filename
       endif else begin
       ; if the user turns off template, close it
         !SPD_GUI.templatepath = ''
         !SPD_GUI.windowStorage->setProperty,template=obj_new('spd_ui_template')
         state.statusbar->update,'Template disabled.'
         state.historywin->update,'Template disabled.'
       endelse

    END
    
    'TMPBROWSE':BEGIN

      tmppathid = widget_info(event.top, find_by_uname='TMPPATH')
      widget_control, tmppathid, get_value=currentfile
      if currentfile ne '' then path = file_dirname(currentfile)
      fileName = Dialog_Pickfile(Title='Choose SPEDAS Template:', $
           Filter='*.tgt',Dialog_Parent=event.top,file=filestring,path=path, /must_exist,/fix_filter); /fix_filter doesn't seem to make a difference on Windows. Does on unix.
      ; check to make sure the file selected actually is a tgt file
      if is_string(fileName) then begin
        if ~stregex(fileName, '.*(.tgt)$',/fold_case,/bool) then begin
          ok = dialog_message('Selected file does not appear to be a SPEDAS Template. Please select a SPEDAS Template (*.tgt) file',/center)
        endif else spd_ui_fileconfig_load_template, filename, event.top, state.statusBar
      endif

    END
    
    'RESET': BEGIN
     
      !SPEDAS=state.thm_cfg_save
      widget_control,state.localdir,set_value=!SPEDAS.local_data_dir
      widget_control,state.remotedir,set_value=!SPEDAS.remote_data_dir
      if !SPEDAS.no_download eq 1 then begin
         widget_control,state.nd_off_button,set_button=1
      endif else begin
         widget_control,state.nd_on_button,set_button=1
      endelse  
      if !SPEDAS.no_update eq 1 then begin
        widget_control,state.nu_off_button,set_button=1
      endif else begin
        widget_control,state.nu_on_button,set_button=1
      endelse  
      widget_control,state.v_droplist,set_combobox_select=!SPEDAS.verbose
      state.historywin->update,'Resetting controls to saved values.'
      state.statusbar->update,'Resetting controls to saved values.'           
               
; Do not delete in case we reinstall  graphics buttons
;      !spd_gui.renderer = state.spd_ui_cfg_sav.renderer
;      !spd_gui.templatepath = state.spd_ui_cfg_sav.templatepath
        
;      if !spd_gui.renderer eq 0 then begin
;        widget_control,state.gr_hard_button,/set_button
;        spd_ui_fileconfig_set_draw,state,0
;      endif else begin
;        widget_control,state.gr_soft_button,/set_button
;        spd_ui_fileconfig_set_draw,state,1
;      endelse
      !spd_gui.templatepath = ''
      widget_control, (widget_info(event.top, find_by_uname='TMPPATH')), set_value=''
      widget_control, (widget_info(event.top, find_by_uname='TMPBUTTON')), set_button=0
      widget_control, (widget_info(event.top, find_by_uname='TMPPATHBASE')), sensitive = 0
      
      state.spd_ui_cfg_sav = !spd_gui

    END
    
   'RESETTODEFAULT': BEGIN

      state.historywin->update,'Resetting configuration to default values.'
      state.statusbar->update,'Resetting configuration to default values.'
      thm_init,  /reset      
      !spedas.no_download = state.def_values[0]
      !spedas.no_update = state.def_values[1]      
      !spedas.downloadonly = state.def_values[2]
      !spedas.verbose = state.def_values[3]        
      widget_control, state.LocalDir, set_value=!spedas.local_data_dir
      widget_control, state.RemoteDir, set_value=!spedas.remote_data_dir
;      Do Not delete may reinstall at later date    
;      !spd_gui.renderer = 1
;      widget_control,state.gr_soft_button,/set_button
;      spd_ui_fileconfig_set_draw,state,1
      !spd_gui.templatepath = ''
      widget_control, (widget_info(event.top, find_by_uname='TMPPATH')), set_value=''
      widget_control, (widget_info(event.top, find_by_uname='TMPBUTTON')), set_button=0
      widget_control, (widget_info(event.top, find_by_uname='TMPPATHBASE')), sensitive = 0
      
      state.spd_ui_cfg_sav = !spd_gui
                   
    END
    
    'SAVE': BEGIN

       thm_write_config
       state.statusBar->update,'Saved thm_config.txt'
       state.historyWin->update,'Saved thm_config.txt'
       
    END

    ELSE:

  ENDCASE
  
  widget_control, event.handler, set_uvalue=state, /NO_COPY

  RETURN
  
END 

;--------------------------------------------------------------------------------

PRO spd_ui_fileconfig, tab_id, historyWin, statusBar

  defsysv, '!SPEDAS', exists=exists
  if not keyword_set(exists) then thm_init
  thm_cfg_save = !spedas
  spd_ui_cfg_sav = !spd_gui
  
;Build the widget bases
  master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top) 

;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, /align_top)
  top = widget_base(vmaster,/row)

;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center)
  ll = max(strlen([!spedas.local_data_dir, !spedas.remote_data_dir]))+12
;Now create directory text widgets

  configbase = widget_base(vmaster,/col)

  lbase = widget_base(configbase, /row, /align_left)
  flabel = widget_label(lbase, value = 'Local data directory:    ')
  localdir = widget_text(lbase, /edit, /all_events, xsiz = ll, $
                         uval = 'LOCALDIR', val = !spedas.local_data_dir)
  loc_browsebtn = widget_button(lbase,value='Browse', uval='LOCALBROWSE',/align_center)

  rbase = widget_base(configbase, /row, /align_left)
  flabel = widget_label(rbase, value = 'Remote data directory: ')
  remotedir = widget_text(rbase, /edit, /all_events, xsiz = ll, $
                          uval = 'REMOTEDIR', val = !spedas.remote_data_dir)

;Next radio buttions
  nd_base = widget_base(configbase, /row, /align_left)
  nd_labelbase = widget_base(nd_base,/col,/align_center)
  nd_label = widget_label(nd_labelbase, value='Download Data:',/align_left, xsize=95)
  nd_buttonbase = widget_base(nd_base, /exclusive, column=2, uval="ND",/align_center)
  nd_on_button = widget_button(nd_buttonbase, value='Automatically    ', uval='NDON',/align_left,xsize=120)
  nd_off_button = widget_button(nd_buttonbase, value='Use Local Data Only', uval='NDOFF',/align_left)

  nubase = widget_base(configbase, /row, /align_left)
  nu_labelbase = widget_base(nubase,/col,/align_center)
  nu_label = widget_label(nu_labelbase, value='Update Files:',/align_left, xsize=95)
  nu_buttonbase = widget_base(nubase, /exclusive, column=2, uval="NU",/align_center)
  nu_on_button = widget_button(nu_buttonbase, value='Update if Newer  ', uval='NUON',/align_left,xsize=120)
  nu_off_button = widget_button(nu_buttonbase, value='Use Local Data Only', uval='NUOFF',/align_left)

  v_base = widget_base(configbase, /row)
  v_label = widget_label(v_base, value='Verbose (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE', /align_center)

  ;base for graphics and template
  grtemp_base = widget_base(vmaster,/col,/align_left)
  ; Graphics mode
  ; DO NOT delete in case we want to reinstall grahics buttons
;  gr_base = widget_base(grtemp_base, /row, /align_left)
;  gr_labelbase = widget_base(gr_base,/col,/align_center)
;  gr_label = widget_label(gr_labelbase, value='Graphics Mode:   ',xsize=95,/align_left)
;  gr_buttonbase = widget_base(gr_base, /exclusive, column=2, uval="GR",/align_center)
;  gr_hard_button = widget_button(gr_buttonbase, value='Hardware Render     ', uval='GRHARD',xsize=120,/align_left)
;  gr_soft_button = widget_button(gr_buttonbase, value='Software Render   ', uval='GRSOFT',/align_left)
  
;  if !SPD_GUI.renderer then begin
;    widget_control,gr_soft_button,/set_button
;  endif else begin
;    widget_control,gr_hard_button,/set_button
;  endelse

; Template
  tmp_base = widget_base(grtemp_base, row=2,/align_left,uname='TMPBASE')
  tmp_labelbase = widget_base(tmp_base, /align_center,/col)
  tmp_label = widget_label(tmp_labelbase, value='Template:            ',/align_left,xsize=97)
  tmp_buttonbase = widget_base(tmp_base,/row,/nonexclusive,uval='TMP',/align_center)
  tmp_button = widget_button(tmp_buttonbase,value='Load Template',uval='USETMP',uname='TMPBUTTON')
  
  tmp_pathbase = widget_base(tmp_base,/row,/align_center,uname='TMPPATHBASE')
  tmp_label = widget_label(tmp_pathbase, value='',xsize=100)
  tmppath = widget_text(tmp_pathbase, xsize = 56, $
                         uval = 'TMPPATH',uname='TMPPATH',/align_center)
  tmp_browsebtn = widget_button(tmp_pathbase,value='Browse', uval='TMPBROWSE',/align_center)
  if !SPD_GUI.templatepath ne '' then begin
    widget_control, tmp_button,/set_button
    widget_control, tmppath, /sensitive, set_value = !SPD_GUI.templatepath
  endif else widget_control, tmp_pathbase, sensitive=0

;buttons
  savebut = widget_button(bmaster, value = '   Save To File  ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')

  ;defaults for reset:
  def_values=[0,0,0,2]
 
  ;store these guys in pointers so that they
  ;are easy to return from event handler

  state = {spd_ui_cfg_sav:spd_ui_cfg_sav, thm_cfg_save:thm_cfg_save, $
          localdir:localdir, remotedir:remotedir, $
          nd_on_button:nd_on_button, nd_off_button:nd_off_button, $
          nu_on_button:nu_on_button, nu_off_button:nu_off_button, $
          v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, $
          def_values:def_values, $
          historyWin:historyWin, tab_id:tab_id, master:master}

  spd_ui_fileconfig_init_struct,state,!spedas

  Widget_Control, master, Set_UValue=state, /No_Copy
  widget_control, master, /realize
  Widget_Control, widget_info(tab_id, /child), Set_UValue=state, /No_Copy

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_fileconfig', master, /no_block

END ;--------------------------------------------------------------------------------



