PRO xtplot_options_panel_event, ev
  compile_opt idl2
  widget_control, ev.top, GET_UVALUE=wid

  code_exit = 0
  code_refresh = 1
  
  ;thisEvent = tag_names(ev,/structure_name)
  
  
  case ev.id of
    ;--------------------------------------------------------------------------------------
    ; TAB SWITCH
    ;--------------------------------------------------------------------------------------
    wid.baseTab: code_refresh = 0
    ;--------------------------------------------------------------------------------------
    ; TRACE
    ;--------------------------------------------------------------------------------------
    wid.btnXloadct: xloadct
    wid.btnXpalette: xpalette
    wid.btnLoadct2: loadct2,34
    wid.fldColor: begin
      widget_control, ev.id, GET_VALUE=new_color
      options,wid.target,'color',new_color
    end
    ;--------------------------------------------------------------------------------------
    ; AXES
    ;--------------------------------------------------------------------------------------
    wid.fldYmin: begin
      ylim, wid.target, ev.value, wid.yrange[1], wid.YLOG
      str_element,/add,wid,'yrange',[ev.value,wid.yrange[1]]
      end
    wid.fldYmax: begin
      ylim, wid.target, wid.yrange[0], ev.value, wid.YLOG
      str_element,/add,wid,'yrange',[wid.yrange[0],ev.value]
      end
    wid.bgYlog: begin
      widget_control,wid.bgYlog,GET_VALUE=value
      ylim, wid.target, wid.yrange[0], wid.yrange[1], value[0]
      str_element,/add,wid,'ylog',value[0]
      end
    ;--------------------------------------------------------------------------------------
    ; FINALIZE
    ;--------------------------------------------------------------------------------------
    wid.btnClose: begin
      print, 'Close'
      code_refresh = 0
      code_exit = 1
    end
    else:
  endcase
  
  if code_exit then begin
    widget_control, ev.top, /destroy
  endif else begin
    widget_control, ev.top, SET_UVALUE=wid
    if code_refresh then tplot
  endelse
END

PRO xtplot_options_panel, group_leader=group_leader, target=target
  compile_opt idl2
  if xregistered('xtplot_options_panel') ne 0 then return

  ;state
  if n_elements(target) eq 0 then begin
    answer=dialog_message('must have a target',/center)
    return
  endif
  wid = {target:target}
  
  ; target - current options
  get_data,target,data=D,dl=dl,lim=lim

  color = 0
  ylog = 0
  yrange = [1e+9, -1e+9]
    
  if n_tags(D) eq 0 then ttnames = D else ttnames = [target]
  nmax = n_elements(ttnames)
  tylog = intarr(nmax)
  tcolor= intarr(nmax)
  for n=0,nmax-1 do begin
    get_data,ttnames[n],data=D,dl=dl,lim=lim
    
    ; YRANGE
    DEFAULT=1
    if n_tags(lim) gt 0 then begin; Check for user-setting
      tn=tag_names(lim)
      idx=where(strmatch(tn,'YRANGE'),ct)
      if ct eq 1 then begin
        if lim.YRANGE[0] lt yrange[0] then yrange[0] = lim.YRANGE[0]
        if lim.YRANGE[1] gt yrange[1] then yrange[1] = lim.YRANGE[1]
        DEFAULT=0
      endif
    endif
    if DEFAULT then begin; Auto-scaling
      this_min = min(D.y,/nan) & if this_min lt yrange[0] then yrange[0] = this_min
      this_max = max(D.y,/nan) & if this_max gt yrange[1] then yrange[1] = this_max
    endif
      
    ; YLOG
    if n_tags(dl) gt 0 then begin; Check for default-setting
      tn=tag_names(dl)
      idx=where(strmatch(tn,'YLOG'),ct)
      if ct eq 1 then tylog[n]=dl.YLOG
    endif
    if n_tags(lim) gt 0 then begin; Check for user-setting (if exists, override default-setting)
      tn=tag_names(lim)
      idx=where(strmatch(tn,'YLOG'),ct)
      if ct eq 1 then tylog[n]=lim.YLOG
    endif
    
    ; COLOR
    if n_tags(dl) gt 0 then begin; Check for default-setting
      tn=tag_names(dl)
      idx=where(strmatch(tn,'COLOR'),ct)
      if ct eq 1 then tcolor[n]=dl.COLOR
    endif
    if n_tags(lim) gt 0 then begin; Check for user-setting (if exists, override default-setting)
      tn=tag_names(lim)
      idx=where(strmatch(tn,'COLOR'),ct)
      if ct eq 1 then tcolor[n]=lim.COLOR
    endif
  end; for n=0,nmax-1 
  if total(tcolor) ne 0 then color = median(tcolor) 
  if total(tylog) eq nmax then ylog = 1
  str_element,/add,wid,'color',color
  str_element,/add,wid,'yrange',yrange
  str_element,/add,wid,'ylog',ylog

  
  ; widget layout
  base = widget_base(TITLE='Panel Options',/column)
    
    str_element,/add, wid, 'fldTarget',cw_field(base, TITLE = "Target:", VALUE=target)
  
    baseTab = widget_tab(base,/align_center)
      str_element,/add,wid,'baseTab',baseTab
      
      baseTabAxes = widget_base(baseTab,title='Axes',/COLUMN)
      str_element,/add,wid,'fldYmin',cw_field(baseTabAxes, TITLE = "Ymin", VALUE=wid.yrange[0],/RETURN_EVENTS)
      str_element,/add,wid,'fldYmax',cw_field(baseTabAxes, TITLE = "Ymax", VALUE=wid.yrange[1],/RETURN_EVENTS)
      str_element,/add,wid,'bgYlog',cw_bgroup(baseTabAxes, 'Ylog',/COLUMN, /NONEXCLUSIVE, $
        SET_VALUE=[wid.YLOG],ypad=0,space=0)
      
      baseTabTrace = widget_base(baseTab,title='Trace',/COLUMN)
        baseXcolor = widget_base(baseTabTrace,/ROW)
          str_element,/add,wid,'btnXloadct',widget_button(baseXcolor,VALUE='XLOADCT')
          str_element,/add,wid,'btnXpalette',widget_button(baseXcolor,VALUE='XPALETTE')
          str_element,/add,wid,'btnLoadct2',widget_button(baseXcolor,VALUE='Default color table')
        str_element,/add,wid,'fldColor',cw_field(baseTabTrace, TITLE = "Trace color index:", VALUE=color,/RETURN_EVENTS)    
      
    baseExit = widget_base(base,/ROW)
      str_element,/add,wid,'btnClose',widget_button(baseExit,VALUE=' Close ')    
    
  widget_control, base, /REALIZE
  scr = get_screen_size()
  geo = widget_info(base,/geometry)
  widget_control, base, SET_UVALUE=wid, XOFFSET=scr[0]*0.5-geo.xsize*0.5, YOFFSET=scr[1]*0.5-geo.ysize*0.5
  
  xmanager, 'xtplot_options_panel', base,GROUP_LEADER=group_leader
END




