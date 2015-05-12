
PRO eva_sitl_cleanup, parent=parent
  @eva_sitl_com
;  id_sitl = widget_info(parent, find_by_uname='eva_sitl')
;  widget_control, id_sitl, GET_VALUE=s
  
  obj_destroy,sg.myview
  obj_destroy,sg.myviewB
  obj_destroy,sg.myfont
  obj_destroy,sg.myfontL
END

PRO eva_sitl_fom_recover,strcmd
  compile_opt idl2
  @eva_sitl_com

  i = i_fom_stack; which step to plot? current--> i=0, one_step_past--> i=1

  imax = n_elements(fom_stack)
  case strcmd of
    'undo': i++; one step backward in time
    'redo': i--; one step forward in time
    'rvrt': i = imax-1
  endcase

  case 1 of
    i lt 0    : i = 0
    i ge imax : i = imax-1
    else: begin
      ptr = fom_stack[i]
      dr = *ptr
      tfom = eva_sitl_tfom(dr.F)
      store_data,'mms_stlm_fomstr',data=eva_sitl_strct_read(dr.F,tfom[0])
      options,'mms_stlm_fomstr','unix_FOMStr_mod',dr.F
      if (n_tags(dr.B) gt 0) then begin
        store_data,'mms_stlm_bakstr',data=eva_sitl_strct_read(dr.B,min(dr.B.START,/nan))
        options,'mms_stlm_bakstr','unix_BAKStr_mod',dr.B
      endif
      eva_sitl_strct_yrange,'mms_stlm_output_fom'
      eva_sitl_strct_yrange,'mms_stlm_fomstr'
      tplot,verbose=0
    end
  endcase
  i_fom_stack = i
END

; This function validates the input 't' and returns the variable "BAK"
; BAK =  1 .... If 't' falls in the BAKStr time
; BAK =  0 .... If 't' falls in the FOMStr time
; BAK = -1 .... If 't' was crossing the FOM/BAK border or too big.
FUNCTION eva_sitl_seg_validate, t
  compile_opt idl2

  get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
  tfom = eva_sitl_tfom(lim.UNIX_FOMSTR_MOD)
  case n_elements(t) of
    1: BAK = (t lt tfom[0])
    2: begin
      r = segment_overlap(t, tfom)
      BAK = -1
      msg = 'ok'
      case r of
        -2: BAK = 1
        -1: msg = 'The selected segment is crossing the FOM/BAK boundary.'
        0: BAK = 0
        1: msg = 'Out of time range'
        2: msg = 'Out of time range'
        3: msg = 'Segment too big.'
        4: msg = 'Segment too big.'
        else: message,'Something is wrong'
      end; case r of
      print, 'EVA: selected segment validate result, r ='+strtrim(string(r),2)
      if ~strmatch(msg,'ok') then rst = dialog_message(msg,/info,/center)
    end; 2:begin
    else: message,'"t" must be 1 or 2 element array.'
  endcase
  return, BAK
END

; For a given time range 'trange', create "segSelect"
; which will be passed to eva_sitl_FOMedit for editing
PRO eva_sitl_seg_add, trange, state=state, var=var
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  ; validation (trange)
  if n_elements(trange) ne 2 then begin
    rst = dialog_message('Select a time interval by two left-clicks.',/info,/center)
    return
  endif

  if trange[1] lt trange[0] then begin
    trange_temp = trange[0]
    trange = [trange[1], trange_temp]
  endif

  BAK = eva_sitl_seg_validate(trange); Validate against FOM time interval
  ; This function validates the input 't' and returns the variable "BAK"
  ; BAK =  1 .... If 't' falls in the BAKStr time
  ; BAK =  0 .... If 't' falls in the FOMStr time
  ; BAK = -1 .... If 't' was crossing the FOM/BAK border or too big.
  
  if BAK eq 1 then begin
    ; validation (BAKStr: make sure 'trange' does not overlap with existing segments)
    get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
    s = lim.unix_BAKStr_mod
    Nsegs = n_elements(s.FOM)

    ct_overlap = 0; count number of overlapped segments
    for N=0,Nsegs-1 do begin
      if ~strcmp(s.STATUS[N],'DELETED') then begin
        if s.START[N] gt s.STOP[N] then stop
        rr = segment_overlap([s.START[N],s.STOP[N]],trange)
        if ((rr eq 4) or (rr eq 3) or (rr eq -1) or (rr eq 1) or (rr eq 0)) then ct_overlap += 1
      endif
    endfor
    NOTOK = (ct_overlap gt 0)
    if NOTOK then begin
      rst = dialog_message('A new segment must not overlap with existing segments.',/info,/center)
      return
    endif
    wgrid = s.TIMESTAMPS
  endif

  if BAK eq 0 then begin
    get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
    wgrid = lim.unix_FOMStr_mod.TIMESTAMPS
  endif
  
  if BAK ne -1 then begin
    ; calculate new FOM value
    ;  tbl       = state.fom_table
    ;  FOMWindow = mms_burst_fom_window(nind,tbl.FOMSlope, tbl.FOMSkew, tbl.FOMBias)
    ;  seg       = Din.y[ind]
    ;  RealFOM   = (total(seg[sort(seg)]*FOMWindow) <255.0) > 2.0
    ;RealFOM = 40
    
    if (state.USER_FLAG eq 4) then begin
      RealFOM = 200
      valval = mms_load_fom_validation()
      tedef = trange[0] + valval.FPI_SEG_BOUNDS[1]*10d0
    endif else begin
      RealFOM = 40
      tedef = trange[1]
    endelse
    
    ; segSelect
    if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
    segSelect = {ts:trange[0], te:tedef, fom:RealFOM, BAK:BAK, discussion:' ', var:var}
    eva_sitl_FOMedit, state, segSelect, wgrid=wgrid ;Here, change FOM value only. No trange change.
  endif
END



; For a given time 't', find the corresponding segment from
; FOMStr/BAKStr and then create "segSelect" which will be passed
; to eva_sitl_FOMedit for editing
PRO eva_sitl_seg_edit, t, state=state, var=var, delete=delete, split=split

  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
  
  BAK = eva_sitl_seg_validate(t); Validate against FOM time interval
  ; This function validates the input 't' and returns the variable "BAK"
  ; BAK =  1 .... If 't' falls in the BAKStr time
  ; BAK =  0 .... If 't' falls in the FOMStr time
  ; BAK = -1 .... If 't' was crossing the FOM/BAK border or too big.
  print,'EVA: BAK='+string(long(BAK))
  if n_elements(t) eq 1 then begin
    case BAK of
      1: begin
        get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
        s = lim.UNIX_BAKSTR_MOD
        idx = where((s.START le t) and (t le s.STOP), ct)
        if ct eq 1 then begin
          segSelect = {ts:s.START[idx[0]],te:s.STOP[idx[0]],fom:s.FOM[idx[0]],$
            BAK:BAK,discussion:' ', var:var}
        endif else segSelect = 0
        wgrid = s.TIMESTAMPS
      end
      0: begin
        get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
        s = lim.UNIX_FOMSTR_MOD
        stime = s.TIMESTAMPS[s.START]
        etime = s.TIMESTAMPS[s.STOP] + 10.d0
        idx = where((stime le t) and (t le etime), ct)
        if ct eq 1 then begin
          segSelect = {ts:stime[idx[0]],te:etime[idx[0]],fom:s.FOM[idx[0]],$
            BAK:BAK, discussion:s.DISCUSSION[idx[0]], var:var}
        endif else segSelect = 0
        wgrid = s.TIMESTAMPS
      end
      else: segSelect = -1
    endcase
  endif else begin
    if (BAK eq 0) or (BAK eq 1) then begin; Will be important when deleting multiple segments
      segSelect = {ts:t[0], te:t[1], fom:0., BAK: BAK, discussion:' ', var:var}
    endif else segSelect = -1
  endelse

  
  if n_tags(segSelect) eq 6 then begin
    if segSelect.BAK and ~state.pref.EVA_BAKSTRUCT then begin
      msg ='This is a back-structure segment. Ask Super SITL if you really need to modify this.'
      rst = dialog_message(msg,/info,/center)
    endif else begin
      if keyword_set(delete) then begin;....... DELETE
        segSelect.FOM = 0.; See line 102 of eva_sitl_strct_update
        eva_sitl_strct_update, segSelect, user_flag=state.user_flag
        eva_sitl_stack
        tplot,verbose=0
        
      endif; DELETE
      if keyword_set(split) then begin;........... SPLIT
        gTmin = segSelect.TS
        gTmax = segSelect.TE
        ;gTdel = double((mms_load_fom_validation()).NOMINAL_SEG_RANGE[1]*10.)
        if(state.PREF.EVA_SPLIT_SIZE eq 0) then begin
          val = mms_load_fom_validation()
          str_element,/add,state,'pref.EVA_SPLIT_SIZE',val.NOMINAL_SEG_RANGE[1]
        endif
        gTdel = double(state.PREF.EVA_SPLIT_SIZE*10.)
        gFOM = segSelect.FOM
        gBAK = segSelect.BAK
        gDIS = segSelect.DISCUSSION
        gVAR = segSelect.VAR
        nmax = floor((gTmax-gTmin)/gTdel)
        if nmax gt 0 then begin
          
          ; delete the segment
          segSelect.FOM = 0.; See line 102 of eva_sitl_strct_update
          eva_sitl_strct_update, segSelect, user_flag=state.user_flag
          
          ; add split segment
          for n=0,nmax-1 do begin
            Ts = gTmin+gTdel*n
            Te = gTmin+gTdel*(n+1)
            segSelect = {ts:Ts,te:Te,fom:gFOM,BAK:gBAK, discussion:gDIS, var:gVAR}
            eva_sitl_strct_update, segSelect, user_flag=state.user_flag
          endfor
          Ts = gTmin+gTdel*nmax
          Te = gTmax
          segSelect = {ts:Ts,te:Te,fom:gFOM,BAK:gBAK, discussion:gDIS, var:gVAR}
          eva_sitl_strct_update, segSelect, user_flag=state.user_flag
          
        endif; if nmax
        eva_sitl_stack
        tplot,verbose=0
      endif; SPLIT
      if (~keyword_set(delete) and ~keyword_set(split)) then begin;............. EDIT
        eva_sitl_FOMedit, state, segSelect, wgrid=wgrid
      endif
    endelse; if segSelect.BAK
  endif else begin
    print,'EVA: segSelect = '+strtrim(string(segSelect),2)
    ;if segSelect eq 0 then rst = dialog_message('Please choose a segment.',/info,/center)
  endelse
END

PRO eva_sitl_seg_delete, t, state=state, var=var
  eva_sitl_seg_edit, t, state=state, var=var, /delete
END

PRO eva_sitl_seg_split, t, state=state, var=var
  eva_sitl_seg_edit, t, state=state, var=var, /split
END

PRO eva_sitl_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  if n_tags(value) eq 0 then begin
    eva_sitl_update_board, state, value
  endif else begin
    str_element,/add,state,'pref',value
  endelse
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitl_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_sitl_event, ev
  compile_opt idl2
  @eva_sitl_com
  @xtplot_com.pro
 
  
  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  if n_tags(state) eq 0 then return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
    message, /reset
    return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif
  
  set_multi = widget_info(state.cbMulti,/button_set)
  set_trange= widget_info(state.cbWTrng,/button_set)
  submit_code = 0
  sanitize_fpi = 1
  xtplot_right_click = 1
  
  case ev.id of
    state.btnAdd:  begin
      print,'EVA: ***** EVENT: btnAdd *****'
      str_element,/add,state,'group_leader',ev.top
      eva_ctime,/silent,routine_name='eva_sitl_seg_add',state=state,occur=2,npoints=2;npoints
      end
    state.btnEdit:  begin
      print,'EVA: ***** EVENT: btnEdit *****'
      str_element,/add,state,'group_leader',ev.top
      eva_ctime,/silent,routine_name='eva_sitl_seg_edit',state=state,occur=1,npoints=1;npoints
      end
    state.btnDelete:begin
      print,'EVA: ***** EVENT: btnDelete *****'
      npoints = 1 & occur = 1
      eva_ctime,/silent,routine_name='eva_sitl_seg_delete',state=state,occur=occur,npoints=npoints
      end
    state.cbMulti:begin; Delete N segments with N clicks
      print,'EVA: ***** EVENT: cbMulti *****'
      npoints = 2000 & occur = 1
      
      ; The right-click-event during eva_ctime seems to be executed
      ; AFTER this eva_sitl/cbMulti event has ended. So, it is not meaningful to
      ; set xtplot_right_click back to 1 before the end of this event handler.
      ; We set xtplot_right_click 0 here, but we have to execute another widget
      ; event in order to set it back to 1. We have xtplot_right_click=1 at the 
      ; beggining of this event handler so that the right click will be turned back
      ; on after any addition SITL event (except cbMulti).
      xtplot_right_click = 0
    
      eva_ctime,/silent,routine_name='eva_sitl_seg_delete',state=state,occur=occur,npoints=npoints
      end
    state.cbWTrng: begin; Delete N segment within a range specified by 2-clicks
      print,'EVA: ***** EVENT: cbWTrng *****'
      npoints = 2 & occur = 2
      eva_ctime,/silent,routine_name='eva_sitl_seg_delete',state=state,occur=occur,npoints=npoints
      end
    state.btnSplit: begin
      print,'EVA: ***** EVENT: btnSplit *****'
      str_element,/add,state,'group_leader',ev.top
      eva_ctime,/silent,routine_name='eva_sitl_seg_split',state=state,occur=1,npoints=1;npoints
      sanitize_fpi=0
      end
    state.btnUndo: begin
      print,'EVA: ***** EVENT: btnUndo *****'
      eva_sitl_fom_recover,'undo'
      end
    state.btnRedo: begin
      print,'EVA: ***** EVENT: btnRedo *****'
      eva_sitl_fom_recover,'redo'
      end
    state.btnAllAuto: begin
      print,'EVA: ***** EVENT: btnAllAuto *****'
      eva_sitl_fom_recover,'rvrt'
      end
    state.btnValidate: begin
      print,'EVA: ***** EVENT: btnValidate *****'
      title = 'Validation'
      if state.PREF.EVA_BAKSTRUCT then begin
        tn = tnames()
        idx = where(strmatch(tn,'mms_stlm_bakstr'),ct)
        if ct eq 0 then begin
          msg = 'Back-Structure not found. If you wish to'
          msg = [msg, 'submit a FOM structure, please disable the back-']
          msg = [msg, 'structure mode.']
          rst = dialog_message(msg,/error,/center,title=title)
        endif else begin
          get_data,'mms_stlm_bakstr',data=Dmod, lim=lmod,dl=dmod
          get_data,'mms_soca_bakstr',data=Dorg, lim=lorg,dl=dorg
          tai_BAKStr_org = lorg.unix_BAKStr_org
          str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
          str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
          tai_BAKStr_mod = lmod.unix_BAKStr_mod
          str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
          str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
          vsp = '////////////////////////////'
          header = [vsp+' NEW SEGMENTS '+vsp]
          r = eva_sitl_validate(tai_BAKStr_mod, -1, vcase=1, header=header, /quiet); Validate New Segs
          header = [r.msg,' ', vsp+' MODIFIED SEGMENTS '+vsp]
          r2 = eva_sitl_validate(tai_BAKStr_mod, tai_BAKStr_org, vcase=2, header=header); Validate Modified Seg
        endelse; if ct eq 0
      endif else begin
        get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dmod
        get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dorg
        mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
        mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
        header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
        vcase = (state.USER_FLAG eq 4) ? 3 : 0
        r = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, vcase=vcase, header=header)
      endelse
      end
;    state.btnEmail: begin
;      print,'EVA: ***** EVENT: btnEmail *****'
;      if state.PREF.EVA_BAKSTRUCT then begin
;        msg = 'Email for Back Structure Mode is under construction.'
;        result = dialog_message(msg,/center)
;      endif else begin
;        get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dmod
;        mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
;        header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
;        body = ''
;        nmax = n_elements(header)
;        for n=0,nmax-1 do begin
;          body += header[n] + 'rtn'
;        endfor
;        email_address = 'mitsuo.oka@gmail.com'
;        syst = systime(/utc)
;        oUrl = obj_new('IDLnetUrl')
;        txturl = 'http://www.ssl.berkeley.edu/~moka/evasendmail.php?email='$
;          +email_address+'&fomstr='+body+'&time='+syst
;        ok = oUrl->Get(URL=txturl,/STRING_ARRAY)
;        obj_destroy, oUrl
;        result=dialog_message('Email sent to '+email_address,/center,/info)
;      endelse
;      end
    state.drpHighlight: begin
      print,'EVA: ***** EVENT: drpHighlight *****'
      tplot
      type = state.hlSet2[ev.index]
      status = ''
      skip=0
      case type of
        'Default'  : begin
          isPending=0 & inPlaylist=0 & status = '' & skip=1
        end
        'isPending': isPending=1
        'inPlaylist': inPlaylist=1
        else: begin
          isPending=0 & inPlaylist=0 & status = type
        end
      endcase
      if ~skip then begin
        get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
        if n_tags(lim) gt 0 then begin
          D = eva_sitl_strct_read(lim.unix_BAKStr_mod, 0.d0,$
            isPending=isPending,inPlaylist=inPlaylist,status=status)
          nmax = n_elements(D.x)
          if nmax ge 5 then begin
            left_edges  = D.x[1:nmax-1:4]
            right_edges = D.x[4:nmax-1:4]
            data        = D.y[2:nmax-1:4]
            eva_sitl_highlight, left_edges, right_edges, data, /noline
            
          endif; if nmax
        endif; if n_tags
      endif;if~skip
      end
    state.drpSave: begin
      print,'EVA: ***** EVENT: drpSave *****'
      type = state.svSet[ev.index]
      case type of
        'Save': eva_sitl_save,/auto
        'Restore': eva_sitl_restore,/auto
        'Save As': eva_sitl_save
        'Restore From': eva_sitl_restore
        else: answer = dialog_message('Something is wrong.')
      endcase
      end
    state.btnSubmit: begin
      print,'EVA: ***** EVENT: btnSubmit *****'
      print,'EVA: TESTMODE='+string(state.PREF.EVA_TESTMODE_SUBMIT)
      submit_code = 1
      if state.PREF.EVA_BAKSTRUCT then begin 
        eva_sitl_submit_bakstr,ev.top, state.PREF.EVA_TESTMODE_SUBMIT
      endif else begin
        vcase = (state.USER_FLAG eq 4) ? 3 : 0
        eva_sitl_submit_fomstr,ev.top, state.PREF.EVA_TESTMODE_SUBMIT, vcase, user_flag=state.USER_FLAG
      endelse
      end
    state.drDash: begin
      ;print,'EVA: ***** EVENT: drDash *****'
      widget_control,state.drDash,TIMER=1; from /expose keyword of drDash
      sanitize_fpi=0
      end
    else:
  endcase

  FPI = (state.USER_FLAG eq 4)
  if(FPI and sanitize_fpi) then begin; Revert hacked FOMstr (i.e. remove the fake segment)
    get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
    s = lim.unix_FOMstr_mod
    snew = s
    if (s.NSEGS gt 1) and (s.START[0] eq 0) and (s.STOP[0] eq 1) and (s.FOM[0] eq 0.) then begin
      str_element,/add,snew, 'FOM', s.FOM[1:s.NSEGS-1]
      str_element,/add,snew, 'START', s.START[1:s.NSEGS-1]
      str_element,/add,snew, 'STOP', s.STOP[1:s.NSEGS-1]
      str_element,/add,snew, 'NSEGS', s.NSEGS-1L
      str_element,/add,snew, 'NBUFFS', s.NBUFFS-1L
      str_element,/add,snew, 'FPICAL', 0L; Set 0 because the dummy segment does not exist anymore
      str_element,/add,lim,'unix_FOMstr_mod',snew
      D_hacked = eva_sitl_strct_read(snew,min(snew.START,/nan))
      store_data,'mms_stlm_fomstr',data=D_hacked,lim=lim,dl=dl
    endif
  endif
  
  if ~submit_code then begin
    tn = tnames('*_stlm_*',ct)
    if ct gt 0 then s=1 else s=0
    eva_sitl_update_board, state, s
    if (s eq 1) and (state.stack eq 0) then begin; At the first call to eva_sitl_update_board
      eva_sitl_stack                             ; with mms_sitl_ouput_fom, we initiate
      str_element,/add,state,'stack',1           ; stacking.
    endif
  endif
  

  
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitl, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  compile_opt idl2
  ;@xtplot_com.pro

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'

  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitl'
  if not (keyword_set(title)) then title='   SITL   '

  ;val = mms_load_fom_validation()
  
  ; ----- STATE -----
  pref = {$
    EVA_BAKSTRUCT: 0,$
    EVA_TESTMODE_SUBMIT: 1,$
    EVA_SPLIT_SIZE:0, $; val.NOMINAL_SEG_RANGE[1]}
    EVA_STLM_INPUT:'soca',$;
    EVA_STLM_UPDATE:1 }
    
  socs  = {$; SOC Auto Simulated
    pmdq: ['a','b','c','d'], $ ; probes to be used for calculating MDQs
    input: 'thm_archive'}    ; input to be used for simulating SOC-Auto
  stlm  = {$; SITL Manu
    input: 'socs', $ ; input type (default: 'soca'; or 'socs','stla')
    update_input: 1 } ; update input data everytime plotting STLM variables
  state = {$
    pref:pref, $
    socs:socs, $
    stlm:stlm, $
    stack: 0, $
    set_multi: 0,$
    set_trange: 0,$
    rehighlight: 0,$
    launchtime: systime(1,/utc),$
    user_flag: 0, $
    userType: ['Guest','MMS member','SITL','Super SITL','FPI cal']}

  ; ----- CONFIG (READ) -----
  cfg = mms_config_read()         ; Read config file and
  pref = mms_config_push(cfg,pref); push the values into preferences
  pref.EVA_BAKSTRUCT = 0
  str_element,/add,state,'pref',pref

  
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize

  hlSet = ['Default','isPending','inPlaylist']
  hlSet2 = [hlSet, 'New', 'Held', 'Realloc', 'Deferred', 'Derelict', 'Demoted',$
    'Modified','Deleted','Aborted','Incomplete','Complete','Finished']
  svSet = ['Save','Restore','Save As', 'Restore From']
  
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitl_event", $
    FUNC_GET_VALUE = "eva_sitl_get_value", $
    PRO_SET_VALUE = "eva_sitl_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1, SPACE=0, YPAD=0)
  str_element,/add,state,'mainbase',mainbase
  str_element,/add,state,'lblTgtTimeMain',widget_label(mainbase,VALUE='(Select a paramter-set for SITL)',/align_left,xsize=xsize)

  subbase = widget_base(mainbase,/column,sensitive=0)
  str_element,/add,state,'subbase',subbase

  bsAction = widget_base(subbase,/COLUMN,/frame)
  ;#####################################################################
  str_element,/add,state,'drDash', widget_draw(bsAction,graphics_level=2,xsize=xsize-20,ysize=150,/expose_event)
  ;#####################################################################

  bsAction0 = widget_base(bsAction,/COLUMN,space=0,ypad=0, SENSITIVE=0)
  str_element,/add,state,'bsAction0',bsAction0
    bsActionButton = widget_base(bsAction0,/ROW)
    str_element,/add,state,'btnAdd',widget_button(bsActionButton,VALUE='  Add  ')
    str_element,/add,state,'btnEdit',widget_button(bsActionButton,VALUE='  Edit  ')
    str_element,/add,state,'btnDelete',widget_button(bsActionButton,VALUE=' Del ');,/TRACKING_EVENTS)
    bsActionCheck = widget_base(bsActionButton,/COLUMN);,/NONEXCLUSIVE)
    str_element,/add,state,'cbMulti',widget_button(bsActionCheck, VALUE='Delete multi seg',SENSITIVE=1)
    str_element,/add,state,'cbWTrng',widget_button(bsActionCheck, VALUE='Delete w/in a range',SENSITIVE=1)
    bsActionHistory = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
    str_element,/add,state,'btnUndo',widget_button(bsActionHistory,VALUE=' Undo ')
    str_element,/add,state,'btnRedo',widget_button(bsActionHistory,VALUE=' Redo ')
    str_element,/add,state,'btnAllAuto',widget_button(bsActionHistory,VALUE=' Revert to Auto ')
    str_element,/add,state,'bsDummy',widget_base(bsActionHistory,xsize=40)
    str_element,/add,state,'btnSplit',widget_button(bsActionHistory,VALUE=' Split ')
    bsActionHighlight = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
      str_element,/add,state,'drpHighlight',widget_droplist(bsActionHighlight,VALUE=hlSet,$
        TITLE='Status:',SENSITIVE=1)
        str_element,/add,state,'hlSet',hlSet
        str_element,/add,state,'hlSet2',hlSet2
    ;bsActionSave = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
      str_element,/add,state,'drpSave',widget_droplist(bsActionHighlight,VALUE=svSet,$
        TITLE='FOM:',SENSITIVE=1)
        str_element,/add,state,'svSet',svSet

  bsActionSubmit = widget_base(subbase,/ROW, SENSITIVE=0)
  str_element,/add,state,'bsActionSubmit',bsActionSubmit
    str_element,/add,state,'btnValidate',widget_button(bsActionSubmit,VALUE=' Validate ')
;    str_element,/add,state,'btnEmail',widget_button(bsActionSubmit,VALUE=' Email ')
    dumSubmit2 = widget_base(bsActionSubmit,xsize=80); Comment out this line when using Email
    dumSubmit = widget_base(bsActionSubmit,xsize=60)
    str_element,/add,state,'btnSubmit',widget_button(bsActionSubmit,VALUE='   SUBMIT   ')
  
  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
END
