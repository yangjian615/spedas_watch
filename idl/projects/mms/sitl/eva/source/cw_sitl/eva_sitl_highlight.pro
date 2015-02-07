PRO eva_sitl_highlight, left_edges, right_edges, data, $
  color=color, target=target, rehighlight=rehighlight
  compile_opt idl2
  @xtplot_com
;  @tplot_com
  @eva_sitl_com
  @moka_logger_com
  
  nmax = n_elements(left_edges)
  if (nmax ne n_elements(right_edges)) or (nmax ne n_elements(data)) then begin
    message,'edges and data must have the same number of elements'
    return
  endif
  if n_elements(color) eq 0 then color=1; 128
  if n_elements(target) eq 0 then target='mms_stlm_output_fom'
  
  ; target panel position
  widget_control, xtplot_base, GET_UVALUE=widf; get widf which contains plot_pos
  ind = where(strcmp(tnames(/tplot),target)); find target 
  pos = widf.plot_pos[*,ind[0]]
  xs = pos[0] & ys = pos[1] & xe = pos[2] & ye = pos[3]
  
  
  ; timerange (data-x)
  time = timerange(/current)
  ts = time[0]
  te = time[1]
  
  ; frange (data-y)
  eva_sitl_strct_yrange, target, yrange=frange
  fmin = frange[0]
  fmax = frange[1]

;  ysetting = tplot_vars.settings.y
;  fmin = ysetting[ind].crange[0]
;  fmax = ysetting[ind].crange[1]
;  log.o,'fmin='+string(fmin,format='(F15.8)')
;  log.o,'fmax='+string(fmax,format='(F15.8)') 
  
  ; coefficients
  xc = (xe-xs)/(te-ts)
  yc = (ye-ys)/(fmax-fmin)
  
  ; data points in normal coordinate
  for n=0,nmax-1 do begin
    x0 = xc*(left_edges[n] -ts)+xs > xs
    x1 = xc*(right_edges[n]-ts)+xs < xe
    y0 = yc*(0.0-fmin)+ys > ys
    y1 = yc*(data[n]-fmin)+ys < ye
    
    if keyword_set(rehighlight) then begin
      polyfill, old_polygonx, old_polygony, color=color, /norm
    endif
    polyfill, [x0,x0,x1,x1],[y0,y1,y1,y0],color=color, /norm
    old_polygonx = [x0,x0,x1,x1]
    old_polygony = [y0,y1,y1,y0]
    old_tstart = ts
    old_tend   = te 
  endfor
END