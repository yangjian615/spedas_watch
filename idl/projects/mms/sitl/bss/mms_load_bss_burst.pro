PRO mms_load_bss_burst, trange=trange
  compile_opt idl2
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()
  mms_init
  
  ;-------------------
  ; DATA
  ;-------------------
  s = mms_bss_load(trange=trange)
  if n_tags(s) lt 10 then return
  
  ;-------------------
  ; FIRST POINT
  ;-------------------
  bar_x = trange[0]
  bar_y = !VALUES.F_NAN

  ;-------------------
  ; MAIN LOOP
  ;-------------------
  nan = !VALUES.F_NAN
  Nsegs = n_elements(s.FOM)
  for n=0,Nsegs-1 do begin; for each segment
    ss = double(s.START[N])
    se = double(s.STOP[N]+10.d0)
    bar_x = [bar_x, ss, ss, se, se]
    bar_y = [bar_y, nan, 0.,0., nan]
  endfor
  
  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  store_data,'mms_bss_burst',data={x:bar_x, y:bar_y}
  options,'mms_bss_burst',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=0.01,colors=4

END



