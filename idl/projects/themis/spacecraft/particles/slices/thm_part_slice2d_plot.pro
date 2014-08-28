
;+
;Procedure: thm_part_slice2d_plot
;
;Purpose: Create plots for 2D particle slices.
;
;Calling Sequence:
;  thm_part_slice2d_plot, slice
;
;Arguments:
;  SLICE: 2D array of values to plot 
;
;Plotting Keywords:
;  ZRANGE: Two-element array specifying zaxis range (units vary)
;  [XY]RANGE: Two-element array specifying x/y axis range
; 
;  LEVELS: Number of color contour levels to plot (default is 60)
;  OLINES: Number of contour lines to plot (default is 0)
;  PLOTSIZE: The size of the plot in device units (usually pixels)
;            (Not yet implemented for postscript).
;  ZLOG: Boolean indicating logarithmic countours (on by default)
;  SUNDIR: Boolean to plot sun direction vector (on by default)
;  ECIRCLE: Boolean to plot circle(s) designating min/max energy 
;           from distribution (on by default)
;  PLOTAXES: Boolean to plot x=0 and y=0 axes (on by default)
;  PLOTBULK: Boolean to plot projection of bulk velocity vector on the 
;            slice plane (on by default)
;            
;  CLABELS: Boolean to annotate contour lines.
;  CHARSIZE: Specifies character size of annotations (1 is normal)
;  [XYZ]TICKS: Integer(s) specifying the number of ticks for each axis 
;  [XYZ]PRECISION: Integer specifying annotation precision (sig. figs.).
;                  Set to zero to truncate printed values to inegers.
;  [XYZ]STYLE: Integer specifying annotation style:
;             Set to 0 (default) for style to be chosen automatically. 
;             Set to 1 for decimal annotations only ('0.0123') 
;             Set to 2 for scientific notation only ('1.23e-2')
;  WINDOW:  Index of plotting window to be used.
;
;Exporting keywords:
; EXPORT: String designating the path and file name of the desired file. 
;         The plot will be exported to a PNG image by default.
; EPS: Boolean indicating that the plot should be exported to 
;      encapsulated postscript.
;
;
;Created by: A. Flores
;            Based on work by Bryan Kerr and Arjun Raj
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-20 18:54:00 -0700 (Fri, 20 Jun 2014) $
;$LastChangedRevision: 15403 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice2d_plot.pro $
;
;-

pro thm_part_slice2d_plot, slice, $
                     ; Dummy vars to conserve backwards compatibility 
                     ; (should allow oldscripts to be run withouth issue)
                       xgrid, ygrid, slice_info, range=range, $
                     ; Range options
                       xrange=xrange, yrange=yrange, zrange=zrange, $
                     ; Basic plotting options
                       title=title, ztitle=ztitle, $ 
                       xtitle=xtitle, ytitle=ytitle, $
                       xticks=x_ticks, yticks=y_ticks, zticks=z_ticks, $
                       xminor=x_minor, yminor=y_minor, $
                       charsize=charsize, plotsize=plotsize, $
                       zlog=zlog, $
                       window=window, $
                     ; Annotations 
                       xstyle=xstyle, xprecision=xprecision, $
                       ystyle=ystyle, yprecision=yprecision, $
                       zstyle=zstyle, zprecision=zprecision, $
                     ; Contours
                       olines=olines, levels=levels, nlines=nlines, clabels=clabels, $
                     ; Other plotting options
                       plotaxes=plotaxes, ecircle=ecircle, sundir=sundir, $ 
                       plotbulk=plotbulk, $
                     ; Eport
                       export=export, eps=eps, $
                       _extra=_extra

    compile_opt idl2


  ; Return if variables are not set
  if size(slice,/type) ne 8 then begin
    fail = 'No data structure provided, canceling plot.'
    dprint, dlevel=0, fail
    return
  endif


  ; Defaults
  if keyword_set(nlines) and ~keyword_set(levels) then levels = nlines ;backward comp.
  if ~keyword_set(levels) then levels=60
  if slice.type gt 1 then begin
    if undefined(olines)then olines = 20
  endif
  
  if undefined(zlog) then zlog=1b
  if undefined(plotaxes) then plotaxes=1b
;  if size(ecircle,/type) eq 0 then ecircle=1b ;todo: fix
  if undefined(plotbulk) then plotbulk=1b
;  if size(sundir,/type) eq 0 then sundir=1b ;may require STATE data

  if undefined(z_ticks) then z_ticks=11

  if undefined(xstyle) then xstyle=0
  if undefined(xprecision) then xprecision=4
  if undefined(ystyle) then ystyle=0
  if undefined(yprecision) then yprecision=4
  if undefined(zstyle) then zstyle=0
  if undefined(zprecision) then zprecision=4

  if ~keyword_set(plotsize) then plotsize = 500.
  plotsize = 100. > plotsize ;min size



  ; X,Y,Z ranges
  if keyword_set(xrange) && ~keyword_set(slice.rlog) then begin
    xrange = minmax(xrange)
  endif else begin
    xrange = minmax(slice.xgrid)
  endelse

  if keyword_set(yrange) && ~keyword_set(slice.rlog) then begin
    yrange = minmax(yrange)
  endif else begin
    yrange = minmax(slice.ygrid)
  endelse

  if keyword_set(range) and ~keyword_set(zrange) then begin
    zrange = range ;maintain backwards compatability
  endif
  if keyword_set(zrange) then begin
    zrange = minmax(zrange)    
  endif else begin
    ; The default range is the nonnegative, nonzero 
    ; min/max of the pre-interpolated data
    zrange = slice.zrange * [0.999,1.001] ;padding, # in thm_ui_slice2d should match this
  endelse
  if zrange[1] eq zrange[0] then begin
    dprint, dlevel=1,'Slice at '+time_string(slice.trange[0])+' has no data.'
    title = 'Error: No data in range!'
    zrange = [1,10.]
  endif 

  
  ; Set color contour levels
  if keyword_set(zlog) then begin
    colorlevels = 10.^(indgen(levels)/float(levels)*(alog10(zrange[1]) - alog10(zrange[0])) + alog10(zrange[0]))
  endif else begin
    colorlevels = (indgen(levels)/float(levels)*(zrange[1]-zrange[0])+zrange[0])
  endelse
  
  
  ; Set colors
  thecolors = round((indgen(levels)+1)*(!d.table_size-9)/levels)+7


  ; Get general annotations
  thm_part_slice2d_getinfo, slice, $
                             title=title, $
;                             subtitle=subtitle, $
                             xtitle=xtitle, $
                             ytitle=ytitle, $
                             ztitle=ztitle


  ; Get the (rough) dimensions of the plot
  ; The values here were largely determined by trial and error
  plotxcsize = plotsize / !d.x_ch_size
  plotycsize = plotsize / !d.y_ch_size
  
  xmargin = [11,15 + (zprecision-3 > 0)]
  ymargin = [4,2]
  
  tsize = strlen(title) * 1.25

  xcsize = (total(xmargin) + plotxcsize) > tsize
  ycsize = (total(ymargin) + plotycsize) 
  
  xsize = xcsize * !d.x_ch_size
  ysize = ycsize * !d.y_ch_size


  ;Open postscript file
  ; -specify aspect ratio to keep output on non-windows systems
  ;  from appearing clipped in that system's viewer
  if keyword_set(export) && keyword_set(eps) then begin
    popen, export, encapsulated = 1, $
           aspect = ysize/xsize, $
           _extra=_extra
  endif


  ;Format the plotting window
  if !d.name ne 'PS' then begin

    device, window_state = wins
    
    ;ensure a free window is used if possible
    if undefined(window) then begin
      wn = !d.window le 1 or !d.window ge 32  ?  $
            min( where(wins eq 0) ) > 2 : !d.window
    endif else begin
      wn = window
    endelse
  
    window, wn, xsize = xcsize * !d.x_ch_size, $
            ysize = ycsize * !d.y_ch_size, $
            title = title

    xmargin[0] = xmargin[0] > 0.5*(xcsize - plotxcsize)
  endif

  
  ; Get tick annotations after window has been initialized, 
  ; this will avoid an extra window from being created by AXIS.
  if keyword_set(slice.rlog) then begin
  
    ; Get ticks for radial log plots
    thm_part_slice2d_getticks_rlog, range=slice.rrange, grid=slice.xgrid, $
                           style=xstyle, precision=xprecision, nticks=x_ticks, $
                           ticks=xticks, tickv=xtickv, tickname=xtickname
                           
    yticks = xticks
    ytickv = xtickv
    ytickname = xtickname
        
  endif else begin 
  
    ; Get x ticks & annotations
    thm_part_slice2d_getticks,nticks=x_ticks, range=xrange, style=xstyle, precision=xprecision, $
                               ticks=xticks, tickv=xtickv, tickname=xtickname, log=0
    
    ; x minor ticks, simulate default if not set
    ; use new name to avoid mutating input
    xminor = size(x_minor,/type) eq 0  ?  round(40./n_elements(xtickv)) : (round(x_minor)+1 > 0)
  
    ; Get y ticks & annotations
    thm_part_slice2d_getticks,nticks=y_ticks, range=yrange, style=ystyle, precision=yprecision, $
                               ticks=yticks, tickv=ytickv, tickname=ytickname, log=0
    
    ; y minor ticks, simulate default if not set
    ; use new name to avoid mutating input
    yminor = size(y_minor,/type) eq 0  ?  round(40./n_elements(ytickv)) : (round(y_minor)+1 > 0)
  
  endelse


  ; Plot
  contour, slice.data, slice.xgrid, slice.ygrid, $
      levels = colorlevels, c_color = thecolors, charsize=charsize, $
      /isotropic, /closed, /follow, $
;      /cell_fill,  $     ; Cell fill does not appear necessary here
      /fill, $
      title = title, $
      xmargin = xmargin, $
      ymargin = ymargin, $
      xstyle = 1, $    ; Force range
      ystyle = 1, $    ;
      ticklen = 0.01,$
      xtickname = xtickname,$  ; 2012-June: Annotations now controled by 
      ytickname = ytickname,$  ;            formatannotation
      xminor = xminor,$   ; Allow minor ticks to persist
      yminor = yminor,$   ; when specifying # of major ticks
      xtickv = xtickv,$  ; 2013-April: Specify values to avoid inconsistencies
      ytickv = ytickv,$  ;             
      xticks = xticks, $  ; Number of ticks must be passed in with values 
      yticks = yticks, $  ; for them to be placed correctly
      xrange = xrange,$
      yrange = yrange,$
      xtitle = xtitle,$
      ytitle = ytitle


  ; Get z axis ticks
  thm_part_slice2d_getticks,nticks=z_ticks, range=zrange, log=zlog, $
                             style=zstyle, precision=zprecision, $
                             ticks=zticks, tickv=ztickv, tickname=ztickname
                             
  
  ; Draw z axis color bar
  ;  - both the number of ticks and the tick values must 
  ;    be passed in for them to be placed correctly
  draw_color_scale,range=zrange, log=zlog,title=ztitle, charsize=charsize, $
                   yticks=zticks, ytickv=ztickv, ytickname=ztickname



  ;Other Plotting Options
  ;----------------------

  ; Plot contour lines
  if keyword_set(olines) then begin

    ; set contour levels
    if keyword_set(zlog) then begin
      linelevels = 10.^(indgen(olines)/float(olines)*(alog10(zrange[1]) - alog10(zrange[0])) + alog10(zrange[0]))
    endif else begin
      linelevels = (indgen(olines)/float(olines)*(zrange[1]-zrange[0])+zrange[0])
    endelse

    contour, slice.data, slice.xgrid, slice.ygrid, $
        levels = linelevels, charsize=charsize,  $
        /overplot, /closed, /isotropic, $
        follow = clabels
  endif


  ; Plot axes
  if keyword_set(plotaxes) then begin
    oplot, [0.,0.], yrange, linestyle=2, thick = 1
    oplot, xrange, [0.,0.], linestyle=2, thick = 1
  endif
  

  ; Plot circle for minimum/maximum velocity 
  ; (based off energy limits) 
  if keyword_set(ecircle) then begin
    degrees = findgen(360)*!dtor
    
    ocircy=sin(degrees) * slice.rrange[1]
    ocircx=cos(degrees) * slice.rrange[1]
    icircy=sin(degrees) * slice.rrange[0]
    icircx=cos(degrees) * slice.rrange[0]
    
    
    ;adjust for subtraction of bulk velocity
    if keyword_set(slice.shift) then begin
      ocircy -= slice.shift[1]
      ocircx -= slice.shift[0]
      icircy -= slice.shift[1]
      icircx -= slice.shift[0]
    endif
    
    if slice.rrange[1] gt 0 then $
      oplot,ocircx,ocircy,thick = 1
    if slice.rrange[0] gt (yrange[1]-yrange[0])*0.015 then $
      oplot,icircx,icircy,thick = 1
  endif
  
  
  ; Plot the bulk velocity
  if keyword_set(plotbulk) and keyword_set(slice.bulk) $
    and ~keyword_set(shift) then begin
    ; bulk velocity should already be in the coords defined for
    ; the slice plane
    oplot, [0,slice.bulk[0]], [0,slice.bulk[1]], color=!d.table_size-9
  endif


  ; Plot sun direction
  ; loading of state data moved to thm_part_dist_array 2012-12
  if keyword_set(sundir) then begin
    if keyword_set(slice.sunvec) then begin
      sund_p = slice.sunvec[0:1] ;already in slice plane's coords
      sv_length = sqrt( max(xrange)^2 + max(yrange)^2 ) * 2
      oplot,[0,sund_p[0]*sv_length],[0,sund_p[1]*sv_length]
    endif else begin
      dprint, dlevel=1, 'To plot sun direction /GET_SUN_DIRECTION must'+ $ 
                        ' be used on call to thm_part_dist_array.' 
    endelse
  endif


  ; Finish export:  write .png or close postscript file 
  if keyword_set(export) then begin
    if keyword_set(eps) then begin
      pclose
    endif else begin
      makepng, export, /mkdir, _extra=_extra
    endelse
  endif


end
