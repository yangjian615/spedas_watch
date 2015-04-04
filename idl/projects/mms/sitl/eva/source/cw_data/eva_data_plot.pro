PRO eva_data_plot, wid
  compile_opt idl2
  @eva_logger_com

  ; INITIALIZE
  thm_init
  duration   = wid.duration
  duration  = (str2time(wid.end_time)-str2time(wid.start_time))/86400.d0; duration in unit of days.
  timespan, wid.start_time, duration
  ;eventdate  = wid.eventdate
  ;timespan,eventdate,duration
  pmax_THM = n_elements(wid.probelist_thm)
  pmax_MMS = n_elements(wid.probelist_mms)
  if pmax_THM eq 1 and size(wid.probelist_thm[0],/type) ne 7 then pmax_THM=0
  if pmax_MMS eq 1 and size(wid.probelist_mms[0],/type) ne 7 then pmax_MMS=0
  plst_THM = wid.paramlist_thm
  plst_MMS = wid.paramlist_mms
  plst_STL = wid.paramlist_stlm
  ;probelist  = wid.probelist & pmax = n_elements(probelist)
  ;paramlist  = wid.paramlist & imax = n_elements(paramlist)
  OPOD     = wid.OPOD; One Probe One Display = separate windows
  SORT_BY_VARIABLE = wid.SRTV

  if OPOD then begin; separate windows
    wmax = pmax_THM+pmax_MMS; number of windows (= number of probes)
    vars_arr = ptrarr(wmax)
    ; THEMIS
    if pmax_THM gt 0 then begin
      for p=0,pmax_THM-1 do begin; for each THM probe
        vars = wid.paramlist; Duplicate the grand paramlist (contains * at this point)
        idx = where(strpos(vars,'th*') eq 0, ct); find variables with 'th*'
        vars[idx] = wid.probelist_thm[p]+strmid(vars[idx],3,1000); replace * with probe name
        idx = where(strpos(vars,'mms*') eq 0, ct, complement=idxc); find variables with 'mms*' to be excluded
        vars_arr[p] = ptr_new(vars[idxc])
      endfor
    endif

    ; MMS
    if pmax_MMS gt 0 then begin
      for p=0,pmax_MMS-1 do begin; for each THM probe
        vars = wid.paramlist; Duplicate the grand paramlist (contains * at this point)
        idx = where(strpos(vars,'mms*') eq 0, ct); find variables with 'mms*'
        vars[idx] = wid.probelist_mms[p]+strmid(vars[idx],4,1000); replace * with probe name
        idx = where(strpos(vars,'th*') eq 0, ct, complement=idxc); find variables with 'th*' to be excluded
        vars_arr[p+pmax_THM] = ptr_new(vars[idxc])
      endfor
    endif
  endif else begin; Data from all probes are shown in one display
    vmst = wid.paramlist; Duplicate the grand paramlist (contains * at this point)
    imax = n_elements(vmst)
    vars = ''
    for i=0,imax-1 do begin; for each parameter in 'vmst'
      match=0 ; look for wild card *
      if strpos(vmst[i],'th*') eq 0 then begin; if 'th*' found
        match=1
        for p=0,pmax_THM-1 do begin
          vars = [vars, wid.probelist_thm[p]+strmid(vmst[i],3,1000)]; replace * with probe name
        endfor
      endif
      if strpos(vmst[i],'mms*') eq 0 then begin; if 'mms*' found
        match=1
        for p=0,pmax_MMS-1 do begin
          vars = [vars, wid.probelist_mms[p]+strmid(vmst[i],3,1000)]; replace * with probe name
        endfor
      endif
      if match eq 0 then begin
        vars = [vars,vmst[i]]
      endif
    endfor; for each parameter in 'vmst'
    kmax = n_elements(vars)
    vars = vars[1:kmax-1]

    if ~SORT_BY_VARIABLE then begin; Sort by Probes
      vold = vars
      vnew = ''
      kmax = n_elements(vold)
      krem = kmax
      while (krem gt 0) do begin
        vold_tmp = ''
        pfx = strmid(vold[0],0,3); 1st 3 letters of the top remaining variable
        for k=0,krem-1 do begin; for each of the remaining variables
          if strpos(vold[k], pfx) eq 0 then begin; if same prefix
            vnew = [vnew, vold[k]] ; move it to vnew
          endif else begin
            vold_tmp = [vold_tmp, vold[k]]
          endelse
        endfor
        kk = n_elements(vold_tmp)
        if kk eq 1 then krem = 0 else begin
          vold = vold_tmp[1:kk-1]
          krem = n_elements(vold)
        endelse
      endwhile
      vars = vnew[1:n_elements(vnew)-1]
    endif

    vars_arr = ptrarr(1); only 1 window
    vars_arr[0] = ptr_new(vars)
  endelse


  jmax = n_elements(vars_arr)

  ; PLOT OPTIONS
  tplot_options, 'ystyle', 0; 1) exact 0) not exact
  tplot_options, 'ygap', 0.3
  tplot_options, 'xmargin', [14,10] ;18 characters on left side, 12 on right
  for j=0,jmax-1 do begin
    eva_data_plot_options, *vars_arr[j]; Note again that *vars_arr[j] is still an array
  endfor


  ; XTPLOT
  geo = widget_info(wid.parent,/geometry)
  width_main = geo.xsize
  dim_scr = get_screen_size()
  width = 650 < (dim_scr[0]-width_main-30)
  height= 600 < (dim_scr[1]-60        )
  print, 'dim_scr=',dim_scr
  print, 'width=',width,'height=',height
  xoffset = dim_scr[0]-width

  j=0
  if n_elements(*vars_arr[0]) gt 0 then $
    xtplot, *vars_arr[0], var_lab=var_lab, XSIZE=width, YSIZE=height, $
    XOFFSET = xoffset, GROUP_LEADER=wid.mainbase, widf=widf

  for j=1,jmax-1 do begin
    if n_elements(*vars_arr[j]) gt 0 then $
      xtplot, *vars_arr[j], var_lab=var_lab, XSIZE=width, YSIZE=height, $
      XOFFSET = xoffset-j*30, YOFFSET= j*30, widf=widf, GROUP_LEADER=wid.mainbase,/xtnew
  endfor

  ptr_free, vars_arr
END