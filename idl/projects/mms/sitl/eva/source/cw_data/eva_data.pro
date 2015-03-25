; $LastChangedBy: moka $
; $LastChangedDate: 2015-03-23 22:17:13 -0700 (Mon, 23 Mar 2015) $
; $LastChangedRevision: 17169 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_data/eva_data.pro $

;PRO eva_data_update_date, state, update=update
;  if keyword_set(update) then widget_control, state.fldDate, SET_VALUE=state.eventdate
;  sstime = time_string(str2time(state.eventdate))
;  eetime = time_string(str2time(state.eventdate) + state.duration*86400.d)
;  orbit_state = { stime: sstime, etime: eetime, ttime: state.eventdate, $;location to be emphasized
;    probelist: state.probelist}
;  ;widget_control, wid.orbit, SET_VALUE = orbit_state
;END

PRO eva_data_update_time, state, update=update
  if keyword_set(update) then begin; update the fields
    widget_control, state.fldStartTime, SET_VALUE=state.start_time
    widget_control, state.fldEndTime,   SET_VALUE=state.end_time
  endif
  sstime = time_string(str2time(state.start_time))
  eetime = time_string(str2time(state.end_time))
;  orbit_state = { stime: sstime, etime: eetime, ttime: state.eventdate, $;location to be emphasized
;    probelist: state.probelist}
END

PRO eva_data_set_value, id, value ;In this case, value = activate
  compile_opt idl2, hidden
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  str_element,/add,state,'pref',value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_data_get_value, id
  compile_opt idl2, hidden
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_data_validate_time, str_stime, str_etime
  
  msg = ''
  stime = str2time(str_stime)
  etime = str2time(str_etime)
  timec = systime(/seconds)
  timem = str2time('2015-03-12'); MMS launch date
  
  if stime gt etime then msg = 'Start time must be before end time.'
  
  thm_start = str2time('2007-02-17'); THEMIS launch date
  if stime lt thm_start then msg = 'Start time must be later than 2007-02-17.'  
  
  if etime gt timec then msg = 'Time range must not be a future.'
  
  ttimeS = str2time('2015-04-09/23:00'); This is the time period used for testing
  ttimeE = str2time('2015-04-11/01:00'); rick's fetch routine
  if (timec lt timem) and (ttimeS lt stime) and (etime lt ttimeE) then msg = ''
  
  return, msg
END

FUNCTION eva_data_load_and_plot, state
  @tplot_com
  @moka_logger_com
  
  ; validate time range
  msg = eva_data_validate_time(state.start_time, state.end_time)
  if strlen(msg) gt 0 then begin
    log.o, msg
    result = dialog_message(msg,/center)
    return, state
  endif

  ; validate parameter file
  result = read_ascii(state.paramFileList[state.paramID],template=eva_data_template())
  paramlist = result.param
  if n_elements(paramlist) eq 0 then begin
    msg =  '!!!!! WARNING: Selected parameter set '+state.paramSetList[state.paramID]+$
      ' is not available !!!!!'
    log.o, msg
    result = dialog_message(msg,/center)
    return, state
  endif

  ; initialize
  clock = eva_tic('LOAD_AND_PLOT')
  del_data,'*'  
  plshort = strmid(paramlist,0,2); first 2 letters
  str_element,/add,state,'paramlist',paramlist
  
  ;----------------------
  ; Load SITL
  ;----------------------
  
  idx=where(strpos(paramlist,'stlm') gt 0,ct)
  paramlist_stlm = (ct ge 1) ? paramlist[idx] : ''
  str_element,/add,state,'paramlist_stlm',paramlist_stlm
  rst_stlm = (ct ge 1) ? eva_sitl_load_stlm(state) : 'No'
  log.o, 'load SITL: number of parameters:'+string(ct)

  ;----------------------
  ; Load THEMIS
  ;----------------------
  
  idx=where(strmatch(plshort,'th'),ct)
  paramlist_thm = (ct ge 1) ? paramlist[idx] : ''
  str_element,/add,state,'paramlist_thm',paramlist_thm
  rst_thm = (ct ge 1) ? eva_data_load_thm(state) : 'No'
  log.o, 'load THEMIS: number of parameters:'+string(ct)
  
  ;----------------------
  ; Load MMS
  ;----------------------
  
  idx=where(strmatch(plshort,'mm'),ct)
  paramlist_mms = (ct ge 1) ? paramlist[idx] : ''      
  str_element,/add,state,'paramlist_mms',paramlist_mms
  rst_mms = (ct ge 1) ? eva_data_load_mms(state) : 'No'
  log.o, 'load MMS: number of parameters'+string(ct)
  
  ;----------------------
  ; Plot
  ;----------------------
  if(strcmp(rst_stlm,'Yes') or strcmp(rst_thm,'Yes') or strcmp(rst_mms,'Yes'))then begin
    ; destroy previously displayed windows
    barr = widget_info(/managed); find currently managed windows
    if n_elements(barr) gt 1 then begin
      for b=1,n_elements(barr)-1 do begin ; for each window (except the main window (b=0)),
        widget_control,barr[b],/destroy ; destroy
      endfor
      str_element,/add,tplot_vars,'options.base',-1; reset the 'base' flag
    endif
    ;##############################################################
    eva_data_plot, state; ............. PLOT
    ;##############################################################
    ;
    ;Activate DASHBOARD
    tn = tnames('*_stlm_*',ct); Check for the existence of stlm parameters
    s = (ct gt 0)
    id_sitl = widget_info(state.parent, find_by_uname='eva_sitl')
    widget_control, id_sitl, SET_VALUE=s
  endif
  
  eva_toc,clock,str=str
  log.o,str
  return, state
END

FUNCTION eva_data_probelist, state

  
  
  widget_control,state.bgTHM,GET_VALUE=gvl_thm
  thm_probes = ['thb','thc','thd','tha','the']
  idx = where(gvl_thm eq 1, ct)
  if ct ge 1 then probelist_thm = thm_probes[idx] else probelist_thm = -1
  str_element,/add,state,'probelist_thm',probelist_thm 
  
  widget_control,state.bgMMS,GET_VALUE=gvl_mms
  mms_probes = ['mms1','mms2','mms3','mms4']
  idx = where(gvl_mms eq 1, ct)
  if ct ge 1 then probelist_mms = mms_probes[idx] else probelist_mms = -1
  str_element,/add,state,'probelist_mms',probelist_mms
  
;  probelist = strarr(1)
;  if USE_THEMIS then begin
;    if gvl_thm[0] then probelist = [probelist,'thb']
;    if gvl_thm[1] then probelist = [probelist,'thc']
;    if gvl_thm[2] then probelist = [probelist,'thd']
;    if gvl_thm[3] then probelist = [probelist,'tha']
;    if gvl_thm[4] then probelist = [probelist,'the']
;  endif
;  if USE_MMS then begin; When faking, I recommend using 'b','a','d','e' for mms 1,2,3,4
;    if gvl_mms[0] then probelist = [probelist,'mms1']; (If this first probe is changed,
;    if gvl_mms[1] then probelist = [probelist,'mms2'];  don't forget to update the initialization
;    if gvl_mms[2] then probelist = [probelist,'mms3'];  of probelist in eva_data)
;    if gvl_mms[3] then probelist = [probelist,'mms4'];
;  endif
;  pmax = n_elements(probelist)
;  if pmax gt 1 then begin
;    probelist = probelist[1:pmax-1]
;  endif else begin
;    probelist = -1
;  endelse

  str_element,/add,state,'probelist',probelist
  eva_data_update_time, state,/update
  tot = total(gvl_thm) + total(gvl_mms)
  widget_control,state.bgOPOD,SENSITIVE=(tot gt 1)
  widget_control,state.bgSRTV,SENSITIVE=(tot gt 1)
  return,state
END

FUNCTION eva_data_login, state, evTop
  compile_opt idl2
  @moka_logger_com
  
  log.o,'accessing MMS SDC...'

  ;---------------------
  ; Establish Connection
  ;---------------------
  r = get_mms_sitl_connection(group_leader=evTop); establish connection with login-widget 
  type = size(r, /type) ;will be 11 if object has been created
  connected = (type eq 11)
  user_flag = state.USER_FLAG  
  FAILED=1

  if connected then begin
    
    ;----- Update CW_DATA -----
    state.paramID = 0
    state = eva_data_paramSetList(state)
    widget_control, state.sbMMS, SENSITIVE=1
    widget_control, state.drpSet, SET_VALUE=state.paramSetList
    
    ;---------------------
    ; Get Target Time
    ;---------------------

    ;unix_FOMstr = eva_sitl_load_soca_getfom(state.PREF.CACHE_DATA_DIR, evTop)
    unix_FOMstr = eva_sitl_load_soca_getfom(state.PREF, evTop)
    if n_tags(unix_FOMstr) gt 0 then begin
      nmax = n_elements(unix_FOMstr.timestamps)
      start_time = time_string(unix_FOMstr.timestamps[0],precision=3)
      end_time = time_string(unix_FOMstr.timestamps[nmax-1],precision=3)
      
      ;---- Update CW_SITL ----
      lbl = ' '+start_time+' - '+end_time
      log.o,'updating cw_sitl target_time label:'
      log.o, lbl
      id_sitl = widget_info(state.parent, find_by_uname='eva_sitl')
      sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
      widget_control, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY;******* GET
      widget_control, sitl_state.lblTgtTimeMain, SET_VALUE=lbl
      widget_control, sitl_state.bsAction0, SENSITIVE=(user_flag ge 2);...... SITL
      widget_control, sitl_state.bsActionSubmit, SENSITIVE=(user_flag ge 2)
      this_hlSet = (user_flag ge 3) ? sitl_state.hlSet2 : sitl_state.hlSet;...Super-SITL
      widget_control, sitl_state.drpHighlight, SET_VALUE=this_hlSet
      widget_control, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY;******* SET
  
      ;---- Update CW_DATA ----
      log.o,'updating cw_data start and end times'
      str_element,/add,state,'start_time',start_time
      str_element,/add,state,'end_time',end_time
      eva_data_update_time, state,/update
      FAILED=0
    endif; if n_tags(unix_FOMstr)
  endif
;  msg = (FAILED) ? 'Log-in Failed' : 'Logged in as a '+state.userType[user_flag]+'!'
  if FAILED then begin
    str_element,/add,state,'user_flag',0
    widget_control, state.drpUserType, SET_DROPLIST_SELECT=0
    msg = 'Log-in Failed'
  endif else begin
    msg = 'Logged-in!'
    if(user_flag ge 2)then begin
      ut = state.userType[user_flag]
      nl = ssl_newline()
      msg = 'Logged-in! with '+ut+' features enabled.'+nl+nl+$
        'If you are not an active member of '+ut+', you can still play'+nl+$
        'around with the features, but your submission will be rejected'+nl+$
        'by the SDC.'
    endif 
  endelse
  answer = dialog_message(msg,/info,title='MMS LOG-IN',/center)
  return, state
END

FUNCTION eva_data_paramSetList, state
  user_flag = state.USER_FLAG
  ; 'dir' produces the directory name with a path separator character that can be OS dependent.
  dir = file_search(ProgramRootDir(/twoup)+'parameterSets',/MARK_DIRECTORY,/FULLY_QUALIFY_PATH); directory
  paramFileList_tmp = file_search(dir,'*',/FULLY_QUALIFY_PATH,count=cmax); full path to the files
  filename = strmid(paramFileList_tmp,strlen(dir),1000); extract filenames only
  paramSetList = ['dummy']
  paramFileList = ['dummy']
  for c=0,cmax-1 do begin; for each file
    spl = strsplit(filename[c],'_',/extract)
    case spl[0] of
      'THM': skip = 0
      'MMS': skip = (user_flag eq 0); skip if guest_user
      'SITL': skip = (user_flag eq 0) ; skip if guest_user
      else: skip = 0
    endcase
    if ~skip then begin
      tmp = strjoin(spl,' '); replace '_' with ' '
      paramSetList = [paramSetList, strmid(tmp,0,strlen(tmp)-4)]; remove file extension .txt etc.
      paramFileList = [paramFileList, paramFileList_tmp[c]]
    endif
  endfor
  str_element,/add,state,'paramSetList',paramSetList[1:*]
  str_element,/add,state,'paramFileList',paramFileList[1:*]
  return, state
END

FUNCTION eva_data_event, ev
  compile_opt idl2
  @moka_logger_com
  
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return, {ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif

  
  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  exitcode=0

  ;-----
  case ev.id of
    state.drpUserType: begin
      log.o,'***** EVENT: drpUserType *****'
      str_element,/add,state,'user_flag',ev.INDEX
      
      if state.USER_FLAG eq 0 then begin
        log.o,'resetting cw_data start and end times'
        start_time = strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)+'/00:00:00'
        end_time   = strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)+'/24:00:00'
        str_element,/add,state,'start_time',start_time
        str_element,/add,state,'end_time',end_time
        eva_data_update_time, state,/update
        state = eva_data_paramSetList(state)
        widget_control, state.sbMMS, SENSITIVE=0
        widget_control, state.drpSet, SET_VALUE=state.paramSetList
      endif else begin
        state = eva_data_login(state,ev.TOP)
      endelse
      end
;    state.btnLogin: begin
;      log.o,'***** EVENT: login *****' 
;      state = eva_data_login(state,ev.TOP)
;      end
    state.fldStartTime: begin
      log.o,'***** EVENT: fldStartTime *****'
      widget_control, ev.id, GET_VALUE=new_time;get new eventdate
      str_element,/add,state,'start_time',new_time
      eva_data_update_time, state ; not updating fldStartTime
    end
    state.fldEndTime: begin
      log.o,'***** EVENT: fldEndTime *****'
      widget_control, ev.id, GET_VALUE=new_time;get new eventdate
      str_element,/add,state,'end_time',new_time
      eva_data_update_time, state ; not updating fldEndTime
    end
    state.calStartTime: begin
      log.o,'***** EVENT: calStartTime *****'
      otime = obj_new('spd_ui_time')
      otime->SetProperty,tstring=state.start_time
      spd_ui_calendar,'EVA Calendar',otime,ev.top
      otime->GetProperty,tstring=tstring         ; get tstring
      str_element,/add,state,'start_time',tstring; put tstring into state structure
      widget_control, state.fldStartTime, SET_VALUE=state.start_time; update GUI field
      eva_data_update_time, state
      obj_destroy, otime
    end
    state.calEndTime: begin
      log.o,'***** EVENT: calEndTime *****'
      otime = obj_new('spd_ui_time')
      otime->SetProperty,tstring=state.end_time
      spd_ui_calendar,'EVA Calendar',otime,ev.top
      otime->GetProperty,tstring=tstring
      str_element,/add,state,'end_time',tstring
      widget_control, state.fldEndTime, SET_VALUE=state.end_time
      eva_data_update_time, state
      obj_destroy, otime
    end
    ;    state.btnCal: begin
    ;      otime = obj_new('spd_ui_time')
    ;      otime->SetProperty,tstring=state.eventdate
    ;      spd_ui_calendar,'EVA Calendar',otime,ev.top
    ;      otime->GetProperty,tstring=tstring
    ;      str_element,/add,state,'eventdate',strmid(tstring,0,10)
    ;      widget_control, state.fldDate, SET_VALUE=state.eventdate
    ;      eva_data_update_date, state
    ;    end
    ;    state.fldDura:  begin
    ;      widget_control, ev.id, GET_VALUE=new_duration
    ;      new_duration = double(new_duration[0]); in unit of days
    ;      str_element,/add,state,'duration',new_duration
    ;      eva_data_update_date, state
    ;    end
    ;    state.fldDate:   begin
    ;      widget_control, ev.id, GET_VALUE=new_eventdate;get new eventdate
    ;      str_element,/add,state,'eventdate',new_eventdate
    ;      eva_data_update_date, state ; not updating fldDate
    ;    end
    ;    state.btnDateF:  begin
    ;      new_eventdate = strmid(time_string(str2time(state.eventdate)+86400.d*state.stepdate),0,10)
    ;      str_element,/add,state,'eventdate',new_eventdate
    ;      eva_data_update_date, state,/update
    ;    end
    ;    state.btnDateP:  begin
    ;      new_eventdate = strmid(time_string(str2time(state.eventdate)-86400.d*state.stepdate),0,10)
    ;      str_element,/add,state,'eventdate',new_eventdate
    ;      eva_data_update_date, state,/update
    ;    end
    ;    state.fldDateS:  begin
    ;      widget_control, ev.id, GET_VALUE=new_step
    ;      str_element,/add,state,'stepdate',new_step
    ;    end
    
    state.bgTHM: state = eva_data_probelist(state)
    state.bgMMS: state = eva_data_probelist(state)
    state.drpSet: begin
      log.o,'***** EVENT: drpSet *****'
      str_element,/add,state,'paramID',ev.index
      fname = state.paramFileList[state.paramID]
      fname_broken=strsplit(fname,'/',/extract,count=count)
      fname_param = fname_broken[count-1]
      result = read_ascii(fname,template=eva_data_template(),count=count)
      if count gt 0 then begin
        str_element,/add,state,'paramlist',result.param
        log.o, 'reading '+fname_param
      endif else begin; if parameterSet list invalid
        msg = 'The selected parameter-set is not valid. Check the file: '+fname_param
        result = dialog_message(msg,/center)
        log.o,msg
      endelse
    end
    state.load: begin
      log.o,'***** EVENT: load *****'
      state = eva_data_load_and_plot(state)
      end
    state.bgOPOD: str_element,/add,state,'OPOD',ev.select
    state.bgSRTV: str_element,/add,state,'SRTV',ev.select
    else:
    endcase
    ;-----

WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_data, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, XSIZE = xsize, YSIZE = ysize
  compile_opt idl2
  
  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for eva_data'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_data'
  
  ; ----- INITIALIZE -----
  
  eventdate = strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)
  start_time = strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)+'/00:00:00'
  end_time   = strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)+'/24:00:00'
  ProbeNamesTHM = ['P1 (THB)','P2 (THC)','P3 (THD)','P4 (THA)','P5 (THE)']
  ProbeNamesMMS = ['MMS 1', 'MMS 2', 'MMS 3', 'MMS 4']
  SetTimeList = ['Default','SITL Current Target Time', 'SITL Back-Structure Time']
  user_flag = 0
  userType = ['Guest','MMS member','SITL','Super SITL','FPI cal']
  
  ;----- PREFERENCES -----
  cd,current = c
  pref = {CACHE_DATA_DIR: c+'/eva_cache/', $
    TESTMODE: 1}
  
  ;----- STATE ----- 
  state = { $
    pref:          pref,         $; preferences
    parent:        parent,       $; parent widget ID (EVA's main window widget)
    eventdate:     eventdate,    $;
    start_time:    start_time,   $;
    end_time:      end_time,     $
    duration:      1.0,          $;
    stepdate:      1,            $; how many days to increment
    paramID:       0,            $; which parameter set to be used
    OPOD:          0,            $; One Plot One Display
    SRTV:          0,            $; Sort by Variables when display
    probelist_thm: 'thb',        $; which THM probe(s) to be used
    probelist_mms: -1,           $; which MMS probe(s) to be used
    paramSetList:  '', $; List of ParameterSets
    paramFileList: '',$
    userType: userType, $
    user_flag: user_flag}
  state = eva_data_paramSetList(state)
  
  ; ----- CONFIG (READ and VALIDATE) -----
  cfg = eva_config_read()         ; Read config file and
  pref = eva_config_push(cfg,pref); push the values into preferences
  ll = strmid(pref.CACHE_DATA_DIR, strlen(pref.CACHE_DATA_DIR)-1, 1); validate
  if ~(ll eq '/' or ll eq '\') then pref.cache_data_dir += '/'
  str_element,/add,state,'pref',pref
  
  ;----- CACHE DIRECTORY -----
  found = file_test(pref.cache_data_dir); check if the directory exists
  if not found then file_mkdir, pref.cache_data_dir
  found = file_test(pref.cache_data_dir+'/abs_data')
  if not found then file_mkdir, pref.cache_data_dir+'/abs_data'
  
  
  
  ; ----- WIDGET LAYOUT -----
  
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, /column,$
    EVENT_FUNC = "eva_data_event", $
    FUNC_GET_VALUE = "eva_data_get_value", $
    PRO_SET_VALUE = "eva_data_set_value", $
    XSIZE = xsize, YSIZE = ysize)
  str_element,/add,state,'mainbase',mainbase
  
;  baseInit = widget_base(mainbase,/row, SPACE=0, YPAD=0)
  str_element,/add,state,'drpUserType',widget_droplist(mainbase,VALUE=state.userType,$
    TITLE='User Type ')
  ;str_element,/add,state,'btnLogin',widget_button(baseInit,VALUE=' Log-in to MMS SOC ')
  ;str_element,/add,state,'lblLogin0',widget_label(baseInit,VALUE='   ')
  
  
  ; calendar icon
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, parent, cal; thm_ui_match_background
  
  baseStartTime = widget_base(mainbase,/row, SPACE=0, YPAD=0)
  lblStartTime = widget_label(baseStartTime,VALUE='Start Time',/align_left,xsize=70)
  str_element,/add,state,'fldStartTime',cw_field(baseStartTime,VALUE=state.start_time,TITLE='',/ALL_EVENTS,XSIZE=24)
  str_element,/add,state,'calStartTime',widget_button(baseStartTime,VALUE=cal)
  
  baseEndTime = widget_base(mainbase,/row)
  lblEndTime = widget_label(baseEndTime,VALUE='End Time',/align_left,xsize=70)
  str_element,/add,state,'fldEndTime',cw_field(baseEndTime,VALUE=state.end_time,TITLE='',/ALL_EVENTS,XSIZE=24)
  str_element,/add,state,'calEndTime',widget_button(baseEndTime,VALUE=cal)
  
  ;  baseDate = widget_base(mainbase,/row)
  ;    baseDateMain = widget_base(baseDate,/column)
  ;      baseDate1 = widget_label(baseDateMain, VALUE='Date',/align_left)
  ;      baseDate2 = widget_base(baseDateMain,/row)
  ;      str_element,/add,state,'fldDate',cw_field(baseDate2,VALUE=state.eventdate,TITLE='',/ALL_EVENTS,XSIZE=10)
  ;      getresourcepath,rpath
  ;      cal = read_bmp(rpath + 'cal.bmp', /rgb)
  ;      thm_ui_match_background, parent, cal
  ;      str_element,/add,state,'btnCal',widget_button(baseDate2,VALUE=cal)
  ;    baseDateStep = widget_base(baseDate,/column)
  ;      baseDateStep1 = widget_label(baseDateStep,VALUE='Step',/align_left)
  ;      baseDateStep2 = widget_base(baseDateStep,/row)
  ;      str_element,/add,state,'btnDateP',widget_button(baseDateStep2,VALUE='<')
  ;      str_element,/add,state,'fldDateS',widget_text(baseDateStep2,VALUE='1',/ALL_EVENTS,/EDITABLE,XSIZE=2)
  ;      str_element,/add,state,'btnDateF',widget_button(baseDateStep2,VALUE='>')
  ;    baseDateDur = widget_base(baseDate,/column)
  ;      baseDateDur1 = widget_label(baseDateDur,VALUE='Duration',/align_left)
  ;      baseDateDur2 = widget_base(baseDateDur,/row)
  ;      str_element,/add,state,'fldDura',widget_text(baseDateDur2,VALUE=string(fix(state.duration)),/ALL_EVENTS,/EDITABLE,XSIZE=4)
  ;      str_element,/add,state,'lblUnit',widget_label(baseDateDur2,VALUE='Day')
  
  
  subbase = widget_base(mainbase,/row,/frame, space=0, ypad=0)
    str_element,/add,state,'bgTHM',cw_bgroup(subbase, ProbeNamesTHM, /COLUMN, /NONEXCLUSIVE,$
      SET_VALUE=[1,0,0,0,0],BUTTON_UVALUE=bua,ypad=0,space=0)
    sbMMS = widget_base(subbase,space=0,ypad=0,SENSITIVE=0)
      str_element,/add,state,'sbMMS',sbMMS
      str_element,/add,state,'bgMMS',cw_bgroup(sbMMS, ProbeNamesMMS, /COLUMN, /NONEXCLUSIVE,$
        SET_VALUE=[0,0,0,0],BUTTON_UVALUE=bua,ypad=0,space=0)
    bsCtrl = widget_base(subbase, /COLUMN,/align_center, space=0, ypad=0)
      str_element,/add,state,'lblPS',widget_label(bsCtrl,VALUE='Parameter Set')
      str_element,/add,state,'drpSet',widget_droplist(bsCtrl,VALUE=state.paramSetList,$
        TITLE='')
      str_element,/add,state,'bgOPOD',cw_bgroup(bsCtrl,'separate windows', /NONEXCLUSIVE,$
        SET_VALUE=0)
      widget_control,state.bgOPOD,SENSITIVE=0
      str_element,/add,state,'bgSRTV',cw_bgroup(bsCtrl,'sort by variables', /NONEXCLUSIVE,$
        SET_VALUE=0)
      widget_control,state.bgSRTV,SENSITIVE=0

  str_element,/add,state,'load',widget_button(mainbase, VALUE = 'LOAD',ysize=30,$;xsize=330,$
    TOOLTIP='Restore from .tplot files or load from THEMIS archive server.')
    
  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  
  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
END
