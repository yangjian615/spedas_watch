;+
;NAME:
; spd_ui_spedas_fileconfig
;
;PURPOSE:
; A widget that allows the user to set some of the !spedas environmental variables. The user
; can save the changes permanently to file, reset to default values, or cancel any changes
; made since the panel was displayed.
;
;HISTORY:
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2013-10-26 12:08:47 -0700 (Sat, 26 Oct 2013) $
;$LastChangedRevision: 13403 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/api_examples/file_configuration_tab/spd_ui_spedas_fileconfig.pro $
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

pro spd_ui_spedas_init_struct,state,struct

  compile_opt idl2,hidden
  
  ; Initialize all the widgets on the configuration panel to
  ; the reflect the system variables values (!spedas)
  
  widget_control,state.tempdir,set_value=struct.temp_dir
  widget_control,state.browserexe,set_value=struct.browser_exe
  widget_control,state.tempcdfdir,set_value=struct.temp_cdf_dir  
  widget_control,state.v_droplist,set_combobox_select=struct.verbose
  Widget_Control,  state.fixlinux, Set_Button=struct.linux_fix

end

PRO spd_ui_spedas_fileconfig_event, event

  ; Get State structure from top level base
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
    
    'FIXLINUX': BEGIN      
      id = widget_info(event.top, find_by_uname='FIXLINUX')
      linux_fix = widget_info(id,/button_set)  
      !spedas.linux_fix =  fix(linux_fix)   
      spd_ui_fix_performance, !spedas.linux_fix
    END
  
    'BROWSEREXEBTN':BEGIN
    
    ; get the web browser executable file
    widget_control, state.browserexe, get_value=browser_exe
    if browser_exe ne '' then path = file_dirname(browser_exe)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the web browser executable file:', $
      Dialog_Parent=state.master, /must_exist)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.browser_exe = dirName
      widget_control, state.browserexe, set_value=dirName
    ENDIF ELSE BEGIN
      ;ok = dialog_message('No file was selected',/center)
    ENDELSE
    
  END
  
  'BROWSEREXE': BEGIN

    widget_control, state.browserexe, get_value=currentDir
    !spedas.browser_exe = currentDir

  END
  
  'TEMPCDFDIR': BEGIN

    widget_control, state.tempcdfdir, get_value=currentDir
    !spedas.temp_cdf_dir = currentDir

  END
  

  'TEMPCDFDIRBTN': BEGIN

    widget_control, state.tempcdfdir, get_value=currentDir
    if currentDir ne '' then path = file_dirname(currentDir)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the directory for CDF files:', $
      Dialog_Parent=state.master, /must_exist, /DIRECTORY)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.temp_cdf_dir = dirName
      widget_control, state.tempcdfdir, set_value=dirName
    ENDIF ELSE BEGIN
     ; ok = dialog_message('Selection is not a directory',/center)
    ENDELSE


  END
  
    'TEMPDIR': BEGIN

    widget_control, state.tempDir, get_value=currentDir
    !spedas.temp_dir = currentDir

  END
  
  'TEMPDIRBTN': BEGIN
  
    widget_control, state.tempDir, get_value=currentDir
    if currentDir ne '' then path = file_dirname(currentDir)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the directory for temp files:', $
      Dialog_Parent=state.master, /must_exist, /DIRECTORY)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.temp_dir = dirName
      widget_control, state.tempDir, set_value=dirName
    ENDIF ELSE BEGIN
     ; ok = dialog_message('Selection is not a directory',/center)
    ENDELSE
    
    
  END
  
  'VERBOSE': BEGIN
  
    !spedas.verbose = long(widget_info(state.v_droplist,/combobox_gettext))
    
  END
  
  'RESET': BEGIN
  
    ; set the system variable (!spedas) back to the state it was at the
    ; beginning of the window session. This cancels all changes since
    ; initialization of the configuration window
    !spedas=state.spedas_cfg_save
    widget_control,state.browserexe,set_value=!spedas.browser_exe
    widget_control,state.tempdir,set_value=!spedas.temp_dir
    widget_control,state.tempcdfdir,set_value=!spedas.temp_cdf_dir
    Widget_Control, state.fixlinux, Set_Button=!spedas.linux_fix
    
    !spd_gui.templatepath = ''
    widget_control, (widget_info(event.top, find_by_uname='TMPPATH')), set_value=''
    widget_control, (widget_info(event.top, find_by_uname='TMPBUTTON')), set_button=0
    widget_control, (widget_info(event.top, find_by_uname='TMPPATHBASE')), sensitive = 0

    state.spd_ui_cfg_sav = !spd_gui
    state.spedas_cfg_save = !spedas        
    
    widget_control,state.v_droplist,set_combobox_select=!spedas.verbose
    state.historywin->update,'Resetting controls to saved values.'
    state.statusbar->update,'Resetting controls to saved values.'
    
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
  
  'RESETTODEFAULT': Begin
  
    ; to reset all values to their default values the system
    ; variable needs to be reinitialized
    spedas_init,  /reset
    
    ; used the stored default values to set the download
    ; and update variables
    !spedas.no_download = state.def_values[0]
    !spedas.no_update = state.def_values[1]
    !spedas.downloadonly = state.def_values[2]
    !spedas.verbose = state.def_values[3]
    !spedas.linux_fix = state.def_values[4]
      
    ; reset the widgets to these values
    widget_control,state.tempdir,set_value=!spedas.temp_dir
    widget_control,state.browserexe,set_value=!spedas.browser_exe
    widget_control,state.v_droplist,set_combobox_select=!spedas.verbose
    Widget_Control,  state.fixlinux, Set_Button=!spedas.linux_fix
       
    !spd_gui.templatepath = ''
    widget_control, (widget_info(event.top, find_by_uname='TMPPATH')), set_value=''
    widget_control, (widget_info(event.top, find_by_uname='TMPBUTTON')), set_button=0
    widget_control, (widget_info(event.top, find_by_uname='TMPPATHBASE')), sensitive = 0
 
    state.spd_ui_cfg_sav = !spd_gui
    state.spedas_cfg_save = !spedas
    
    state.historywin->update,'Resetting configuration to default values.'
    state.statusbar->update,'Resetting configuration to default values.'
    
  END
  
  'SAVE': BEGIN
  
    ; write the values to the text file stored on disk
    ; so the values will be set outside of the panel
    ; and/or gui
    ; these values will also be used each time spedas_init is called 
    
    spedas_write_config
    state.statusBar->update,'Saved spedas_config.txt'
    state.historyWin->update,'Saved spedas_config.txt'
    
  END
  
  ELSE:
ENDCASE

widget_control, event.handler, set_uval = state, /no_copy

Return
END ;--------------------------------------------------------------------------------


PRO spd_ui_spedas_fileconfig, tab_id, historyWin, statusBar

  ;check whether the !spedas system variable has been initialized
  defsysv, '!spedas', exists=exists
  if not keyword_set(exists) then spedas_init
  spedas_cfg_save = !spedas
  spd_ui_cfg_sav = !spd_gui
  linux_fix = !spedas.linux_fix 
  
  ;Build the widget bases
  master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top)
  
  ;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, /align_top)
  top = widget_base(vmaster,/row)
  
  ;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center, ypad=7)
  ll = max(strlen([!spedas.local_data_dir, !spedas.remote_data_dir]))+12
  
  ;Now create directory text widgets
  configbase = widget_base(vmaster,/col)
  gbase = widget_base(configbase, /row, /align_left, ypad=3)
  genlabel = widget_label(gbase, value = 'General Settings for SPEDAS    ')
  
  lbase = widget_base(configbase, /row, /align_left, ypad=1)
  flabel = widget_label(lbase,  value = 'Web browser executable:    ')
  browserexe = widget_text(lbase, /edit, xsiz = 50, /all_events, uval='BROWSEREXE', val = !spedas.browser_exe)
  loc_browsebtn = widget_button(lbase,value='Browse', uval='BROWSEREXEBTN',/align_center)
  
  rbase = widget_base(configbase, /row, /align_left, ypad=1)
  flabel1 = widget_label(rbase, value = 'Temp directory:                    ')
  tempdir = widget_text(rbase, /edit, xsiz = 50, /all_events, uval='TEMPDIR', val = !spedas.temp_dir)
  temp_dirbtn = widget_button(rbase,value='Browse', uval='TEMPDIRBTN', /align_center)

  rbase1 = widget_base(configbase, /row, /align_left, ypad=1)  
  flabel2 = widget_label(rbase1, value = 'Directory for CDAWeb files:  ')
  tempcdfdir = widget_text(rbase1, /edit, xsiz = 50, /all_events, uval='TEMPCDFDIR', val = !spedas.temp_cdf_dir)
  tempcdfdirbtn = widget_button(rbase1,value='Browse', uval='TEMPCDFDIRBTN', /align_center)
  
  v_base = widget_base(configbase, /row, ypad=7)
  v_label = widget_label(v_base, value='Verbose level for tplot (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE', /align_center)
  
  n_base = widget_base(configbase,/row,/nonexclusive,uval='FL')
  fixlinux = widget_button(n_base,value=' Fix drawing performance  ',uval='FIXLINUX',uname='FIXLINUX') 
  Widget_Control, fixlinux, Set_Button=!spedas.linux_fix 
  
  ; buttons to save or reset the widget values
  savebut = widget_button(bmaster, value = '    Save to File     ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')
      
  ; Template
  grtemp_base = widget_base(vmaster,/col,/align_left)
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
  
  ;defaults for Cancel:
  def_values=['0','0','0','2',0]
  
  state = {spedas_cfg_save:spedas_cfg_save, spd_ui_cfg_sav:spd_ui_cfg_sav, $
    master:master, browserexe:browserexe, tempdir:tempdir, tempcdfdir:tempcdfdir, $
    v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, fixlinux:fixlinux, $
    def_values:def_values, historyWin:historyWin, tab_id:tab_id, linux_fix:linux_fix}
    
  spd_ui_spedas_init_struct,state,!spedas
  
  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif
  
  xmanager, 'spd_ui_spedas_fileconfig', master, /no_block
  
END ;--------------------------------------------------------------------------------



