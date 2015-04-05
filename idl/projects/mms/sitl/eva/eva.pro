;+
; NAME: EVA
;
; PURPOSE: The burst-trigger management tool for MMS-SITL 
;
; CALLING SEQUENCE: Type in 'eva' into the IDL console and hit return.
;
; CREATED BY: Mitsuo Oka   Jan 2015
;
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-04-03 21:07:50 -0700 (Fri, 03 Apr 2015) $
; $LastChangedRevision: 17237 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/eva.pro $
PRO eva_event, event
  @tplot_com
  compile_opt idl2
  widget_control, event.top, GET_UVALUE=wid


  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    return
  endif

  exitcode = 0
  case event.id of
    wid.base        : if strmatch(tag_names(event,/structure_name),'WIDGET_KILL_REQUEST') then exitcode=1
    wid.exit        : exitcode = 1
    wid.mnPref      : eva_pref, GROUP_LEADER = event.top
    wid.mnHelp_about: answer=dialog_message('EVA 1.0 beta (Created by Mitsuo Oka at UC Berkeley)',/info,/center)
    ;wid.mnH_Guide  :   begin
    ;fullpath = filepath(root_dir=ProgramRootDir(), 'eva_help.pdf')
    ;online_help,'Getting Started', BOOK=fullpath,/full_path;fullpath,/full_path
    ;end
    else:
  endcase

  if exitcode then begin
    tplot_options,'base',-1
    ;obj_destroy, obj_valid()
    idx = where(strmatch(strlowcase(tag_names(wid)),'sitl'),ct)
    if ct eq 1 then begin
      eva_sitl_cleanup
    endif
    
    widget_control, event.top, /DESTROY
    
    if (!d.flags and 256) ne 0  then begin    ; windowing devices
      str_element,tplot_vars,'options.window',!d.window,/add_replace
      str_element,tplot_vars,'settings.window',!d.window,/add_replace
    endif
  endif else begin
    widget_control, event.top, SET_UVALUE=wid
  endelse
END

PRO eva
  @eva_logger_com

  ;////////// INITIALIZE /////////////////////////////////

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif
  
  If(xregistered('eva') ne 0) then begin
    message, /info, 'You are already running EVA.'
    answer = dialog_message('You are already running EVA.',title='EVA (Event Search and Analysisl)',/center)
    return
  endif
  
  vsn=float(strmid(!VERSION.RELEASE,0,3))
  if vsn eq 8.0 then begin
    answer = dialog_message("You are using IDL version 8.0. With IDL 8.0, "+ $
      "TDAS fails to process SST (high energy particle) data. If a system-error message appeared "+ $
      "while using EVA, please punch OK and EVA should continue running but without SST data.")
  endif


  thm_init
  mms_init
  
  ;cfg = eva_config_read()
  ;if n_tags(cfg) eq 0 then dir = eva_config_filedir(); create config directory if not found

  log = eva_logger(/on)
  ; Force logging during development. For an official release,
  ; enable the LOG keyword by using the following line.
  ; d = eva_logger(on=keyword_set(log), no_file=~keyword_set(log))
  log.o, '--------'
  log.o, ' LAUNCH '
  log.o, '--------'
    
  !EXCEPT = 0; stop reporting of floating point errors
  ;use themis bitmap as toolbar icon for newer versions
  if double(!version.release) ge 6.4d then begin
    getresourcepath,rpath
    palettebmp = read_bmp(rpath + 'thmLogo.bmp', /rgb)
    palettebmp = transpose(palettebmp, [1,2,0])
    _extra = {bitmap:palettebmp}
  endif

  ;////////// WIDGET LAYOUT /////////////////////////////////


  scr_dim    = get_screen_size()
  xoffset = scr_dim[0]*0.3 > 0.;-650.-286-50. > 0.

  ; Top Level Base
  base = widget_base(TITLE = 'EVA',MBAR=mbar,_extra=_extra,/column,$
    XOFFSET=xoffset, YOFFSET=0,TLB_KILL_REQUEST_EVENTS=1,space=7,resource_name="testWidget")
  str_element,/add,wid,'base',base

  ; menu
  mnFile = widget_button(mbar, VALUE='File', /menu)
  str_element,/add,wid,'mnPref',widget_button(mnFile,VALUE='Preference')
  str_element,/add,wid,'exit',widget_button(mnFile,VALUE='Exit',/separator)
  ;    mnPref = widget_button(mbar, VALUE='Preference',/menu)
  ;      str_element,/add,wid,'mnPref_path',widget_button(mnPref,VALUE='Path',/checked_menu)
  ;      mnPref_orb = widget_button(mnPref,VALUE='Orbit',/menu)
  ;        str_element,/add,wid,'mnPref_orbs',widget_button(mnPref_orb,VALUE='Show')
  ;        str_element,/add,wid,'mnPref_orbs_hide',-1
  ;        str_element,/add,wid,'mnPref_orbu',widget_button(mnPref_orb,VALUE='Update data')
  mnHelp = widget_button(mbar, VALUE='Help',/menu)
  ;str_element,/add,wid,'mnHelp_Guide',widget_button(mnHelp,VALUE='SDC SITL DOC')
  str_element,/add,wid,'mnHelp_about',widget_button(mnHelp,VALUE='About EVA')

  ;---------------------------------
  ;  DATA
  ;---------------------------------
  str_element,/add,wid,'data',eva_data(base,xsize=330); DATA MODULE
  baseTab = widget_tab(base)

  ;---------------------------------
  ;  SITL
  ;---------------------------------
  str_element,/add,wid,'sitl', eva_sitl(baseTab,xsize=330); SITL MODULE

  ;---------------------------------
  ;  ORBIT
  ;---------------------------------
  ;str_element,/add,wid,'orbit', cw_orbit(baseTab); ORBIT MODULE

  ; Orbit Module NOTE: set ysize=1 before setting map=0 at line 352 (widget_control, wid.orbit, map=0)

  widget_control, base, /REALIZE

  ; initiate modules
  widget_control, wid.sitl,  SET_VALUE=2
  ;widget_control, wid.orbit, SET_VALUE=1


  ; str_element,/add,wid,'d',d

  ; end of initialization
  widget_control, base, SET_UVALUE=wid
  xmanager, 'eva', base, /no_block;, GROUP_LEADER=group_leader
END
