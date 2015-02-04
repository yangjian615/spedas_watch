;+
; NAME: XTPLOT
; 
; PURPOSE: A GUI wrapper for tplot
; 
; CALLING SEQUENCE: Use just like 'tplot'
; 
; CREATED BY: Mitsuo Oka   Jan 2015
; 
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2015-02-02 13:34:21 -0800 (Mon, 02 Feb 2015) $
; $LastChangedRevision: 16833 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/xtplot/xtplot.pro $
PRO xtplot_change_tlimit, strcmd
  compile_opt idl2
  @tplot_com.pro

  case strcmd of
    'default':  tshift = 100
    'full':     tshift = 200
    'ignore':   tshift = 300
    'expand':   tshift = [-0.25d, 0.25d] ; total length = 0.5
    'shrink':   tshift = [-1.00d, 1.00d] ; total length = 2.0
    'forward':  tshift = [-0.25d, 0.75d] ; [ 0.50d, 1.50d]  ;[-0.25d,0.75d] ; total length = 1.0
    'backward': tshift = [-0.75d, 0.25d] ; [-1.50d,-0.50d];[-0.75d,0.25d] ; total length = 1.0
  endcase

  case tshift[0] of
    100:  tlimit,/silent
    200:  tlimit,/full,/silent
    300: ; do nothing!
    else: begin
      trange = tplot_vars.options.trange
      tlen   = trange[1] - trange[0]
      trange_new = mean(trange) + tshift*tlen
      tlimit, trange_new,/silent
    end
  endcase

  str_element,/add, tplot_vars,'settings.i_trange_stack',0
  rst = where(strmatch(tag_names(tplot_vars.settings),'trange_stack',/fold_case),count)
  if count eq 0 then $
    str_element,/add,tplot_vars,'settings.trange_stack', [tplot_vars.options.trange,tplot_vars.settings.trange_old] $
  else $
    str_element,/add,tplot_vars,'settings.trange_stack', [tplot_vars.options.trange,tplot_vars.settings.trange_stack]
END

PRO xtplot_recovr_tlimit, strcmd, widf
  compile_opt idl2
  @tplot_com.pro

  i = tplot_vars.settings.i_trange_stack; which step to plot? current--> i=0, one_step_past--> i=1
  case strcmd of
    'undo': i++; one step backward in time
    'redo': i--; one step forward in time
  endcase
  imax = n_elements(tplot_vars.settings.trange_stack)/2
  case 1 of
    i lt 0    : i = 0
    i ge imax : i = imax-1
    else: tlimit, [tplot_vars.settings.trange_stack[2*i],tplot_vars.settings.trange_stack[2*i+1]],/silent
  endcase
  str_element,/add,tplot_vars,'settings.i_trange_stack',i
END

PRO xtplot_change_ylimit, widf
  compile_opt idl2
  widget_control, widf.fldAmin, GET_VALUE=Amin
  widget_control, widf.fldAmax, GET_VALUE=Amax
  range=float([Amin,Amax])
  widget_control, widf.drpTarget, GET_VALUE=names
  index = widget_info(widf.drpTarget, /DROPLIST_SELECT)
  options,names[index],'yrange',range
  options,names[index],'autorange',0
  options,names[index],'ystyle', 1
  tplot,verbose=0
END

PRO xtplot_event, event
  compile_opt idl2
  @tplot_com.pro
  @xtplot_com.pro

  ; initialize
  widget_control, event.top, GET_UVALUE=widf



  tplot_vars = widf.tplot_vars
  code_exit=0

  ; main
  case event.id of

    widf.btnTlm:      begin
      xtplot_right_click = 0 
      xtplot_change_tlimit,'default'
      xtplot_right_click = 1
      end
    widf.btnTlmRedo:  xtplot_recovr_tlimit,'redo'
    widf.btnTlmUndo:  xtplot_recovr_tlimit,'undo'
    widf.btnTlmFull:  xtplot_change_tlimit,'full'
    widf.btnTlmRefresh: begin
      tplot,verbose=0, get_plot_pos = plot_pos
      str_element,/add,widf,'plot_pos',plot_pos
    end
    widf.btnExpand:   xtplot_change_tlimit,'expand'
    widf.btnShrink:   xtplot_change_tlimit,'shrink'
    widf.btnForward:  xtplot_change_tlimit,'forward'
    widf.btnBackward: xtplot_change_tlimit,'backward'


    ;    widf.btnAuto:     begin
    ;      widget_control, widf.drpTarget, GET_VALUE=names
    ;      index = widget_info(widf.drpTarget, /DROPLIST_SELECT); which variable?
    ;      checked = widget_info(widf.btnAuto,/BUTTON_SET); is is checked?
    ;      if checked then begin
    ;        widget_control, widf.baseManu, SENSITIVE = 0
    ;;        yrange_auto = xtplot_minmax(names[index])
    ;        options,names[index],'yrange',/delete;yrange_auto
    ;        options,names[index],'autorange',1
    ;        tplot,verbose=0
    ;      endif else begin
    ;        get_data, names[index], limit=limit
    ;        index=where(strmatch(tag_names(limit),'yrange',/fold_case),count)
    ;        if count ne 0 then yrng = limit.yrange else yrng = [0.,0.]
    ;        widget_control, widf.baseManu, SENSITIVE = 1
    ;        widget_control, widf.fldAmin, SET_VALUE=yrng[0]
    ;        widget_control, widf.fldAmax, SET_VALUE=yrng[1]
    ;        options,names[index],'autorange',0
    ;      endelse
    ;      end


    widf.baseTL:      begin
      thisEvent = tag_names(event,/structure_name)
      case thisEvent of
        'WIDGET_KILL_REQUEST': code_exit=1
        'WIDGET_BASE'       : begin; Resize Event
          geoB = widget_info(widf.baseTL,/geometry)
          ;geoD = widget_info(widf.drwPlot,/geometry)
          ;print, 'OLD (x,y)=(', geoB.xsize,',', geoB.ysize,')'
          ;print, 'NEW (x,y)=(', event.x,',',event.y,')'
          if (abs(geoB.xsize-event.x) gt 5.) or (abs(geoB.ysize-event.y) gt 5.) then begin  
            widget_control, widf.drwPlot, Draw_XSize=(event.x)>0, Draw_YSize=(event.y-floor(widf.resYsize))>0
            widget_control, widf.baseTL, xsize=(event.x), ysize=(event.y)
            tplot,verbose=0, get_plot_pos = plot_pos
            str_element,/add,widf,'plot_pos',plot_pos
          endif
          end
        else:
      endcase
    end
    widf.drwPlot: begin
      thisEvent = tag_names(event,/structure_name)
      if strmatch(thisEvent,'WIDGET_DRAW') then begin

        ; converting plot_pos --> time
        time = timerange(/current)
        tL = time[0]; left edge
        tR = time[1]; right edge
        geo = widget_info(widf.drwPlot, /geo)
        xL = widf.plot_pos[0,0]; left edge
        xR = widf.plot_pos[2,0]; right edge
        xC = event.x/geo.xsize ; clicked position
        tC = (xC-xL)*((tR-tL)/(xR-xL)) + tL; clicked time

        ; updating selected time interval
        if widf.selected.state ge 1 then begin; if left-button has been pressed
          tL = widf.selected.tL
          if abs(tL-tC) gt 0 then begin ; if cursor has moved since the first left-press
            if widf.selected.state eq 2 then begin
              xtplot_timebar,widf.selected.oldtC,/transient; Delete Line 2
            endif else str_element,/add,widf,'selected.state',2
            xtplot_timebar,tC,/transient; Plot Line 2
            str_element,/add,widf,'selected.oldtC',tC
          endif
        endif

        ;cursor and status bar
        sz=size(widf.plot_pos,/dim); to obtain number of panels
        if n_elements(sz) gt 1 then begin
          mmax = sz[1]
          yBarr = fltarr(mmax)
          yTarr = fltarr(mmax)
          yBarr[0:mmax-1] = widf.plot_pos[1,0:mmax-1]
          yTarr[0:mmax-1] = widf.plot_pos[3,0:mmax-1]
        endif else begin
          mmax = 1
          yBarr = fltarr(mmax)
          yTarr = fltarr(mmax)
          yBarr[0] = widf.plot_pos[1]
          yTarr[0] = widf.plot_pos[3]
        endelse
        value = 0.0
        ylog = 0
        tn = ''
        for m=0,mmax-1 do begin; for each panel
          yB = yBarr[m];widf.plot_pos[1,m]; bottom
          yT = yTarr[m];widf.plot_pos[3,m]; top
          yC   = event.y/geo.ysize; clicked position
          if (yB le yC) and (yC le yT) then begin
            ; check ylog setting
            tn = tplot_vars.options.def_datanames[m]
            get_data,tn,data=D,dl=dl,lim=lim
            if n_tags(dl) ne 0 then begin
              index = where(strmatch(strlowcase(tag_names(dl)),'ylog'),c); look for tag 'ylog'
              if c then ylog = dl.ylog
            endif
            ; get yrange from the plot
            ysetting = tplot_vars.settings.y
            fmin = ysetting[m].crange[0]
            fmax = ysetting[m].crange[1]
            value = ((yC-yB)/(yT-yB))*(fmax-fmin) + fmin
            if ylog then value = 10^value
          endif
        endfor
        widget_control,widf.lblBar,SET_VALUE=time_string(tC) + $
          ', value = '+strtrim(string(value),2)+' ( '+tn+' )'

        ; RIGHT CLICK EVENT
        if (event.release EQ 4) and (xtplot_right_click=1) then begin
          print,'right clicked on '+tn
          xtplot_options_panel, group_leader=widf.baseTL, target=tn
        endif

        ; XTPLOT_MOUSE_EVENT
        if xtplot_mouse_event then begin
          if event.press eq 4 then begin; right-press
            ; WIDGET_DISPLAYCONTEXTMENU, Parent, X, Y, ContextBase_ID
            print,'tC=',tC
          endif
          if event.press eq 1 then begin; left-press
            xtplot_timebar,tC ;.............. Plot Line 1
            str_element,/add,widf,'selected.tL',tC
            str_element,/add,widf,'selected.state',1
            str_element,/add,widf,'selected.oldtC',tC
            str_element,/add,widf,'selected.xL',xC
          endif
          if event.release eq 1 then begin; left-release
            str_element,/add,widf,'selected.xR',xC
            str_element,/add,widf,'selected.tR',tC
            tL = widf.selected.tL & xL = widf.selected.xL
            tR = widf.selected.tR & xR = widf.selected.xR
            if tL gt tR then begin
              temp = tL & tL = tR & tR = temp
              temp = xL & xL = xR & xR = temp
              str_element,/add,widf,'selected.tL',tL
              str_element,/add,widf,'selected.tR',tR
              str_element,/add,widf,'selected.xL',xL
              str_element,/add,widf,'selected.xR',xR
            endif

            xtplot_timebar,widf.selected.tL,/transient;....... Delete Line 1

            if widf.selected.state eq 2 then begin; cursor moved
              xtplot_timebar,widf.selected.oldtC,/transient; ... Delete Line 2
              if abs(tL-tR) gt 0 then begin
                ;//////////////////////////////////////////////////////////
                call_procedure, xtplot_routine_name, widf.selected
                ;//////////////////////////////////////////////////////////
                xtplot_change_tlimit,'ignore'; add to stack list
              endif
            endif
            str_element,/add,widf,'selected.state',0
          endif; left-release
        endif

      endif

    end
    widf.mnClip:      begin
      widget_control, widf.drwPlot, GET_VALUE=win1
      clipboard,win1
    end
    widf.mnExJPG:     begin
      makejpg,'xtplot'
    end
    widf.mnExPNG:     makepng,'xtplot'
    widf.mnExGIF:     makegif,'xtplot'
    widf.mnConfig:    begin
      formInfo = cmps_form(Cancel=canceled, Create=create, Defaults=widf.ps_config, $
        /color, parent=widf.baseTL)
      if not canceled then begin
        if create then begin
          thisDevice = !D.Name
          Set_Plot, "PS"
          Device, _Extra=formInfo
          tplot,verbose=0
          Device, /Close
          Set_Plot, thisDevice
        endif
        str_element,/add,widf,'ps_config',formInfo
        init_devices
      endif
    end
    widf.mnPrin:      begin
      result = dialog_printersetup()
      if result ne 0 then begin
        def_device = !D.NAME
        set_plot, 'PRINTER',/copy,/interpolate
        tplot,verbose=0
        device,/CLOSE_DOCUMENT
        set_plot, def_device
      endif
    end
    widf.mnExit:      code_exit=1
    widf.mnC_UseMouse:xtplot_change_tlimit,'default'
    widf.mnC_Redo:    xtplot_recovr_tlimit,'redo'
    widf.mnC_Undo:    xtplot_recovr_tlimit,'undo'
    widf.mnC_100:     xtplot_change_tlimit,'full'
    widf.mnC_ZoomIn:  xtplot_change_tlimit,'expand'
    widf.mnC_ZoomOut: xtplot_change_tlimit,'shrink'
    widf.mnC_Forward: xtplot_change_tlimit,'forward'
    widf.mnC_Backward:xtplot_change_tlimit,'backward'
    widf.mnC_Refresh: begin
      tplot,verbose=0, get_plot_pos = plot_pos
      str_element,/add,widf,'plot_pos',plot_pos
    end
    widf.mnP_Pick:    begin
      tplot,/pick, get_plot_pos = plot_pos, verbose=0
      str_element,/add,widf,'plot_pos',plot_pos
    end
    widf.mnP_Rmv:     begin
      ctime, panel=pan
      tnms = tnames(/tplot); variables used in tplot
      rnms = tnms[pan]; variables to be removed
      nnms  = strarr(1); variable to be remained
      imax = n_elements(tnms)
      for i=0,imax-1 do begin
        index = where(strmatch(rnms,tnms[i]), count); check if tnms[i] is to be removed
        if count eq 0 then begin; tnms[i] is NOT to be removed
          nnms = [nnms, tnms[i]]
        endif
      endfor
      tplot, nnms, verbose=0, get_plot_pos = plot_pos
      str_element,/add,widf,'plot_pos',plot_pos
    end
    widf.mnP_AddRmv:  xtplot_panel
    widf.mnP_Restore: begin
      tplot, tplot_vars.options.def_datanames, get_plot_pos = plot_pos, verbose=0
      str_element,/add,widf,'plot_pos',plot_pos
    end
    widf.mnO_AutoExec: xtplot_options
    widf.mnO_PanelOptions: begin
      ctime,prompt='Click on desired panels. (button 3 to quit)',panel=mix,/silent,npoints=1
      tn = tplot_vars.options.def_datanames[mix]
      xtplot_options_panel, group_leader=widf.baseTL, target=tn
    end
    widf.mnO_TplotOptions: print,'Sorry....this feature is under development.'
    ;    widf.mnH_Guide:   begin
    ;      fullpath = filepath(root_dir=ProgramRootDir(), 'xtplot.pdf')
    ;      online_help,'Getting Started', BOOK=fullpath,/full_path;fullpath,/full_path
    ;      end
    widf.mnH_About:    answer=dialog_message('XTPLOT Ver. Beta',/info,/center)
  endcase

  ; finalize
  str_element,/add,widf,'tplot_vars',tplot_vars

  widget_control, event.top, SET_UVALUE=widf
  if code_exit then begin
    chsize = !p.charsize
    if chsize eq 0. then chsize=1.
    def_opts= {ymargin:[4.,2.],xmargin:[12.,12.],position:fltarr(4), $
      title:'',ytitle:'',xtitle:'', xrange:dblarr(2),xstyle:1,    $
      version:3, window:-1, wshow:0,charsize:chsize,noerase:0,overplot:0,spec:0,base:-1}
    extract_tags,tplot_vars.options, def_opts
    str_element,/add,tplot_vars,'options.trange',tplot_vars.options.trange_full
    str_element,/add,tplot_vars,'options.base',-1
    widget_control, widf.baseTL, /DESTROY
    init_devices
  endif
END

pro xtplot,datanames,     $
  WINDOW = wind,         $
  NOCOLOR = nocolor,     $
  VERBOSE = verbose,     $; Choose 0 to show only serious errors. Choose 4 to show all messages
  wshow = wshow,         $
  OPLOT = oplot,         $
  OVERPLOT = overplot,   $
  TITLE = title,         $
  LASTVAR = lastvar,     $
  ADD_VAR = add_var,     $
  LOCAL_TIME= local_time,$
  REFDATE = refdate,     $
  VAR_LABEL = var_label, $
  OPTIONS = opts,        $
  T_OFFSET = t_offset,   $
  TRANGE = trng,         $
  NAMES = names,         $
  PICK = pick,           $
  new_tvars = new_tvars, $
  old_tvars = old_tvars, $
  get_plot_position=pos, $
  help = help,           $
  ; XTPLOT only
  BASE  = base,          $
  XTNEW = xtnew,         $ ; Set this keyword to create a new window. Window ID will be automatically given by IDL.
  XSIZE = xsize,         $
  YSIZE = ysize,         $
  XOFFSET = xoffset,     $
  YOFFSET = yoffset,     $
  EXECCOM = execcom,     $
  MOUSE_EVENT  = mouse_event, $
  ROUTINE_NAME = routine_name,$; this routine is called everytime a time interval is selected by mouse. Valid only when MOUSE_EVENT=1
  widf    = widf, $
  GROUP_LEADER = group_leader
  compile_opt idl2
  @tplot_com.pro
  @xtplot_com.pro

  ;===== initialize ===================================================================

  ; xtplot_com
  
  xtplot_right_click = 1
  if ~keyword_set(mouse_event) then mouse_event = 0; obsolete?
  xtplot_mouse_event = mouse_event
  if ~keyword_set(routine_name) then routine_name = 'xtplot_tlimit'; obsolete?
  xtplot_routine_name = routine_name
  
  ; window size
  factor    = 0.9
  this_screen_size = get_screen_size()
  if ~keyword_set(xsize)   then xsize   = this_screen_size[0]*0.5*factor
  if ~keyword_set(ysize)   then ysize   = this_screen_size[1]*0.5*factor
  if ~keyword_set(xoffset) then xoffset = this_screen_size[0]*0.5
  if ~keyword_set(yoffset) then yoffset = 0
  str_element,/add,widf,'xsize', xsize
  draw_ysize = ysize - 45; this number is obtained empirically. See geo.ysize at the end of this program.

  ; tplot_vars
  tplot_options,title=title,var_label=var_label,refdate=refdate, wind=wind, options = opts
  if keyword_set(old_tvars) then tplot_vars = old_tvars
  if keyword_set(xtnew) then str_element,tplot_vars,'options.base',-1,/add_replace
  if keyword_set(help) then begin
    printdat,tplot_vars.options,varname='tplot_vars.options'
    new_tvars = tplot_vars
    return
  endif
  if keyword_set(base) then begin
    base_valid = widget_info(base,/valid_id)
    if base_valid then begin
      str_element,tplot_vars,'options.base',base,/add_replace
    endif else begin
      answer = dialog_message('XTPLOT '+strtrim(string(base),2)+ $
        ' is unavailable. Use XTNEW keyword to launch a new window.',title='XTPLOT WARNING')
      return
    endelse
  endif

  ; widget_setting (drpTarget)
  dt = size(/type,datanames)
  ndim = size(/n_dimen,datanames)
  if dt ne 0 then begin; if dt is defined
    if dt ne 7 or ndim ge 1 then dnames = strjoin(tnames(datanames,/all),' ') $; if not string
    else dnames=datanames
  endif else begin; if dt is undefined, get a list from tplot_vars.options.datanames
    tpv_opt_tags = tag_names( tplot_vars.options)
    idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
    if icnt gt 0 then begin
      dnames=tplot_vars.options.datanames
    endif else begin; no data names in tplot_vars.options
      dprint,dlevel=0,verbose=verbose,'No valid variable names found to tplot (use TPLOT_NAMES to display)'
      return
    endelse
  endelse
  dnarr = strsplit(dnames,/extract)
  if n_elements(execcom) eq 0 then execcom=''

  ; datanames check
  varnames = tnames(dnames,nd,ind=ind,/all)
  if nd eq 0 then begin
    dprint,dlevel=0,verbose=verbose,'No valid variable names found to tplot! (use TPLOT_NAMES to display)'
    return
  endif
  str_element,/add,tplot_vars,'options.def_datanames',datanames

  ; time range
  if keyword_set(trange) then begin
    strTmin = time_string(trange[0])
    strTmax = time_string(trange[1])
  endif else begin
    strTmin = time_string(tplot_vars.options.trange[0])
    strTmax = time_string(tplot_vars.options.trange[1])
  endelse

  ;  ; options
  ;  imax = n_elements(dnarr)
  ;  for i=0,imax-1 do begin
  ;    options, dnarr[i], 'autorange', 1
  ;    options, dnarr[i], 'ynozero', 1
  ;  endfor

  ; xtp_opts
  xtp_opts={base:-1}; this '-1' remains if tplot_vars was undefined
  extract_tags,xtp_opts,tplot_vars.options  ; overriden by tplot_vars.option
  tplot_options, 'xmargin', [15,9]

  ; postscript printer
  ps_config = cmps_form(/Initialize)
  str_element,/add,widf,'ps_config',ps_config

  ; click info
  str_element,/add,widf,'selected.state',0

  ;===== widget layout ===================================================================

  if xtp_opts.base eq -1 then begin

    ; master base
    baseTL = widget_base( $
      MBAR=mbar, $ ; menu bar$
      ;    _extra=_extra, $  ; window icon
      TITLE = 'XTPLOT',  XOFFSET = xoffset, YOFFSET = yoffset, Base_Align_center=0,XSIZE=xsize, $
      tab_mode=1 ,/column,ypad=0,xpad=0,$
      TLB_SIZE_EVENTS=1, KBRD_FOCUS_EVENTS=1, TLB_KILL_REQUEST_EVENTS=1, CONTEXT_EVENTS=1)
    str_element,/add,widf,'baseTL',baseTL
    str_element,/add,tplot_vars,'options.base',baseTL; to be stored in widf

    ; bitmap
    if double(!version.release) ge 6.4d then begin
      getresourcepath,rpath
      zoomInBMP = read_bmp(rpath + 'magnifier_zoom.bmp',/rgb)
      zoomOutBMP = read_bmp(rpath + 'magnifier_zoom_out.bmp',/rgb)
      plotBMP = read_bmp(rpath + 'np_icon.bmp',/rgb)
      shiftRBMP = read_bmp(rpath + 'control.bmp',/rgb)
      shiftLBMP = read_bmp(rpath + 'control_180.bmp',/rgb)
      spd_ui_match_background, baseTL, zoomInBMP
      spd_ui_match_background, baseTL, zoomOutBMP
      spd_ui_match_background, baseTL, plotBMP
      spd_ui_match_background, baseTL, shiftRBMP
      spd_ui_match_background, baseTL, shiftLBMP
    endif

    ; menu
    mnFile = widget_button(mbar, VALUE='File', /menu)
    mnExpr = widget_button(mnFile,VALUE='Export to Image Files',/menu)
    str_element,/add,widf,'mnClip',widget_button(mnExpr,VALUE='clipboard')
    str_element,/add,widf,'mnExJPG',widget_button(mnExpr,VALUE='JPG')
    str_element,/add,widf,'mnExPNG',widget_button(mnExpr,VALUE='PNG')
    str_element,/add,widf,'mnExGIF',widget_button(mnExpr,VALUE='GIF')
    str_element,/add,widf,'mnConfig',widget_button(mnFile,VALUE='Export to PS/EPS Files')
    str_element,/add,widf,'mnPrin',widget_button(mnFile,VALUE='Print')
    str_element,/add,widf,'mnExit',widget_button(mnFile,VALUE='Exit',/separator)
    mnCtrl  = widget_button(mbar, VALUE='View', /menu)
    str_element,/add,widf,'mnC_UseMouse',widget_button(mnCtrl,VALUE='Use Mouse',ACCELERATOR='Ctrl+m',/separator)
    str_element,/add,widf,'mnC_Redo',widget_button(mnCtrl,VALUE='Redo',ACCELERATOR='Ctrl+y')
    str_element,/add,widf,'mnC_Undo',widget_button(mnCtrl,VALUE='Undo',ACCELERATOR='Ctrl+z')
    str_element,/add,widf,'mnC_100',widget_button(mnCtrl,VALUE='100%',ACCELERATOR='Ctrl+w')
    str_element,/add,widf,'mnC_Forward',widget_button(mnCtrl,VALUE='Forward',ACCELERATOR='Ctrl+f')
    str_element,/add,widf,'mnC_Backward',widget_button(mnCtrl,VALUE='Backward',ACCELERATOR='Ctrl+b')
    str_element,/add,widf,'mnC_ZoomIn',widget_button(mnCtrl,VALUE='Zoom In',ACCELERATOR='Ctrl+i')
    str_element,/add,widf,'mnC_ZoomOut',widget_button(mnCtrl,VALUE='Zoom Out',ACCELERATOR='Ctrl+o')
    str_element,/add,widf,'mnC_Refresh',widget_button(mnCtrl,VALUE='Refresh',ACCELERATOR='Ctrl+r')
    mnPanel = widget_button(mbar, VALUE='Panels', /menu)
    str_element,/add,widf,'mnP_Pick',widget_button(mnPanel,VALUE='Pick by Click')
    str_element,/add,widf,'mnP_Rmv', widget_button(mnPanel,VALUE='Remove by Click')
    str_element,/add,widf,'mnP_AddRmv',widget_button(mnPanel,VALUE='Edit Panels',/separator)
    str_element,/add,widf,'mnP_Restore',widget_button(mnPanel,VALUE='Restore Panels')
    mnOptions = widget_button(mbar, VALUE='Options', /menu)
    str_element,/add,widf,'mnO_PanelOptions',widget_button(mnOptions,VALUE='Panel Options')
    str_element,/add,widf,'mnO_TplotOptions',widget_button(mnOptions,VALUE='Tplot Options')
    mnMacros = widget_button(mbar, VALUE='Macros', /menu)
    str_element,/add,widf,'mnO_AutoExec',widget_button(mnMacros,VALUE='Auto Exec')
    mnHelp = widget_button(mbar, VALUE='Help',/menu)
    ;str_element,/add,widf,'mnH_Guide',widget_button(mnHelp,VALUE='Getting Started (PDF)')
    str_element,/add,widf,'mnH_About',widget_button(mnHelp,VALUE='About XTPLOT')

    ; toolbar
    sxsize=10
    bsTool = widget_base(baseTL,/row)
    str_element,/add,widf,'bsTool',bsTool
    str_element,/add,widf,'btnTlm', widget_button(bsTool,VALUE='Time Range',$
      TOOLTIP='Left-click twice to define a time range (call to "tlimit")')

    bsSpace1 = widget_base(bsTool,XSIZE=sxsize)
    str_element,/add,widf,'btnBackward',widget_button(bsTool,VALUE=shiftlbmp,/Bitmap,$
      Tooltip='Shift Backward')
    str_element,/add,widf,'btnForward', widget_button(bsTool,VALUE=shiftrbmp,/Bitmap,$
      Tooltip='Shift Forward')

    bsSpace2 = widget_base(bsTool,XSIZE=sxsize)
    str_element,/add,widf,'btnExpand',widget_button(bsTool,VALUE=zoominbmp,/Bitmap,$
      Tooltip='Zoom-In')
    str_element,/add,widf,'btnShrink',widget_button(bsTool,VALUE=zoomoutbmp,/Bitmap,$
      Tooltip='Zoom-Out')
    str_element,/add,widf,'btnTlmFull', widget_button(bsTool,VALUE='100%', $
      TOOLTIP='Reset to full time range')

    bsSpace3 = widget_base(bsTool,XSIZE=sxsize)
    str_element,/add,widf,'btnTlmUndo', widget_button(bsTool,VALUE='Undo', $
      TOOLTIP='Undo time-range selection')
    str_element,/add,widf,'btnTlmRedo', widget_button(bsTool,VALUE='Redo', $
      TOOLTIP='Redo time-range selection')
    str_element,/add,widf,'btnTlmRefresh',widget_button(bsTool,VALUE='Refresh', $
      TOOLTIP='Refresh the plot')

    ; plot
    str_element,/add,widf,'drwPlot',widget_draw(baseTL,XSIZE=xsize,YSIZE=draw_ysize, $
      /BUTTON_EVENTS,/MOTION_EVENTS,/TRACKING_EVENTS)

    ; status bar
    str_element,/add,widf,'lblBar',widget_label(baseTL,XSIZE=xsize,VALUE='XTPLOT',/align_left)


    ; realization and additional adjustments
    widget_control, baseTL, /REALIZE
    widget_control, widf.drwPlot, GET_VALUE=drwin
    widget_control, baseTL, BASE_SET_TITLE = 'XTPLOT '+strtrim(string(drwin),2)
    widget_control, baseTL, SET_UVALUE=widf
    xmanager, 'xtplot', baseTL,  /NO_BLOCK, GROUP_LEADER=group_leader

    w = drwin
    b = baseTL
  endif else begin
    b = xtp_opts.base
  endelse

  ;===== tplot ===================================================================

  tplot, datanames, WINDOW = w,$
    NOCOLOR = nocolor, VERBOSE = verbose, OPLOT = oplot, OVERPLOT = overplot,$
    TITLE = title, LASTVAR = lastvar, ADD_VAR = add_var, LOCAL_TIME= local_time, $
    REFDATE = refdate, VAR_LABEL = var_label, OPTIONS = opts, T_OFFSET = t_offset,$
    TRANGE = trng, NAMES = names, PICK = pick, new_tvars = new_tvars, $
    old_tvars = tplot_vars, $; old_tvars is replaced at the beginning of xtplot
    help=help, get_plot_position=plot_pos

  widget_control, b, GET_UVALUE=widf

  geo1 = widget_info(b,/geometry)
  geo2 = widget_info(widf.drwPlot,/geometry)
  str_element,/add,widf,'resYsize',geo1.ysize-geo2.ysize
  str_element,/add,widf,'tplot_vars',tplot_vars
  str_element,/add,widf,'plot_pos',plot_pos

  widget_control, b, SET_UVALUE=widf
  xtplot_base = b

  return
end