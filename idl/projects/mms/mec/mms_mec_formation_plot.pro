;+
; PROCEDURE:
;       mms_mec_formation_plot
;
; PURPOSE:
;       Creates a plot showing the spacecraft formation
;       at a given time
;       
; INPUT:
;       time:   string containing the date and time to create 
;               the plot for. e.g., 'YYYY-MM-DD/HH:MM'
; 
; KEYWORDS:
;       projection:   project the spacecraft positions 
;               onto all planes
;       
;       xy_projection: project the S/C positions onto the XY plane
;       xz_projection: project the S/C positions onto the XZ plane
;       yz_projection: project the S/C positions onto the YZ plane
;               
;       quality_factor: include the tetrahedron quality factor
;               
; EXAMPLES:
;       mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection
;       
;       should create something like:
;       
;       https://lasp.colorado.edu/mms/sdc/public/data/sdc/mms_formation_plots/mms_formation_plot_20160108023624.png
;       
; HISTORY:
;       Most of this (the good stuff) comes from the 
;       SDC version, which was written by Kris Larsen 
;       and Kim Kokkonen at LASP
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-23 15:40:10 -0700 (Wed, 23 Mar 2016) $
; $LastChangedRevision: 20568 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_mec_formation_plot.pro $
;-

pro mms_mec_formation_plot, time, projection=projection, quality_factor=quality_factor, $
  xy_projection=xy_projection, xz_projection=xz_projection, yz_projection=yz_projection
  
  ; load one minute of position data
  current_time = [time_double(time), time_double(time)+60.]
  mms_load_mec, trange=current_time, probes=[1, 2, 3, 4], varformat='*_r_gse', /time_clip
  
  if keyword_set(quality_factor) then begin
      ; load the tetrahedron quality factor
      mms_load_tetrahedron_qf, trange=current_time
      
      get_data, 'mms_tetrahedron_qf', data=tqf
  endif

  get_data, 'mms1_mec_r_gse', data=d1
  get_data, 'mms2_mec_r_gse', data=d2
  get_data, 'mms3_mec_r_gse', data=d3
  get_data, 'mms4_mec_r_gse', data=d4
  
  if ~is_struct(d1) || ~is_struct(d2) || ~is_struct(d3) || ~is_struct(d4) then begin
    dprint, dlevel = 0, 'Error, couldn''t find the spacecraft position for one or more MMS spacecraft. Try a different time'
    return
  endif
  

  xes = [d1.Y[0, 0], d2.Y[0, 0], d3.Y[0, 0], d4.Y[0, 0]]
  yes = [d1.Y[0, 1], d2.Y[0, 1], d3.Y[0, 1], d4.Y[0, 1]]
  zes = [d1.Y[0, 2], d2.Y[0, 2], d3.Y[0, 2], d4.Y[0, 2]]

  xes = (xes - mean(xes))
  yes = (yes - mean(yes))
  zes = (zes - mean(zes))

  ; get ranges
  xrange = 1.3 * [min(xes), max(xes)]
  yrange = 1.3 * [min(yes), max(yes)]
  zrange = 1.3 * [min(zes), max(zes)]

  ; edges between vertices
  xes1 = [xes[0], xes[1], xes[2], xes[3], xes[0], xes[3], xes[1], xes[0], xes[2]]
  yes1 = [yes[0], yes[1], yes[2], yes[3], yes[0], yes[3], yes[1], yes[0], yes[2]]
  zes1 = [zes[0], zes[1], zes[2], zes[3], zes[0], zes[3], zes[1], zes[0], zes[2]]

  margin=0.3

  spacecraft_colors = [[40,40,40],[213,94,0],[0,158,115],[86,180,233]]
  spacecraft_names = ['MMS1','MMS2','MMS3','MMS4']

  ;test = plot3d(xes, yes, zes, linestyle='none', color='black', sym_object = orb(), $
  ;   sym_size=3, /sym_filled, vert_colors=spacecraft_colors, margin=margin)

  p = plot3d(xes1, yes1, zes1, thick=2, color='dim grey', $
    axis_style=2, xtitle='X, km', ytitle='Y, km', ztitle='Z, km', $
    xrange=xrange, yrange=yrange, zrange=zrange, $
    perspective=perspective, margin=margin)

  plot2 = plot3d(xes, yes, zes, linestyle='none', color='black', sym_object = orb(), $
    sym_size=3, /sym_filled, vert_colors=spacecraft_colors, perspective=1, $
    margin=margin, /overplot)
    
  ; draw spacecraft projections
  sym_transparency = 60
  
  if keyword_set(xy_projection) || keyword_set(projection) then begin
      z_projection = make_array(4, value=zrange[0])
      plot3z = plot3d(xes, yes, z_projection, 'o', linestyle='none', $
        sym_size=2, /sym_filled, sym_transparency=sym_transparency, vert_colors=spacecraft_colors, $
        /overplot, perspective=perspective, margin=margin)
  endif

  if keyword_set(xz_projection) || keyword_set(projection) then begin
      y_projection = make_array(4, value=yrange[1])
      plot3y = plot3d(xes, y_projection, zes, 'o', linestyle='none', $
        sym_size=2, /sym_filled, sym_transparency=sym_transparency, vert_colors=spacecraft_colors, $
        /overplot, perspective=perspective, margin=margin)
  endif
  
  if keyword_set(yz_projection) || keyword_set(projection) then begin
      x_projection = make_array(4, value=xrange[1])
      plot3x = plot3d(x_projection, yes, zes, 'o', linestyle='none', $
        sym_size=3, /sym_filled, sym_transparency=sym_transparency, vert_colors=spacecraft_colors, $
        /overplot, perspective=perspective, margin=margin)
  endif

  ; mark origin on xy plane
  w = min(abs([xrange, yrange]))/10
  p1 = plot3d([-w, w], [0, 0], make_array(2, value=zrange[0]), thick=1, color='black', $
    /overplot, perspective=perspective, buffer=buffer, margin=margin)
  p1 = plot3d([0, 0], [-w, w], make_array(2, value=zrange[0]), thick=1, color='black', $
    /overplot, perspective=perspective, buffer=buffer, margin=margin)

  ; setup the axes
  ax = p.axes
  ax[0].tickfont_size = 7
  ax[1].tickfont_size = 7
  ax[8].showtext = 1
  ax[8].tickfont_size = 7
  ax[2].hide=1
  ax[6].hide=1
  ax[7].hide=1

  x1 = 0.33
  yl = 0.03
  for s=0,n_elements(spacecraft_names)-1 do begin
    xs = x1 + 0.13*s
    s1 = symbol(xs,yl,symbol='o', sym_color=spacecraft_colors[*,s], overplot=1, /sym_filled, sym_size=2.0)
    t1 = text(xs + 0.02, yl-0.015, spacecraft_names[s], font_size=12, font_color=spacecraft_colors[*,s])
  endfor

  title_string = 'MMS Formation'
  ; report the exact requested time
  ; even though the actual result time may be a few seconds different
  title_string2 = time_string(d1.X[0], tformat='YYYY-MM-DD/hh:mm:ss') + ' UTC'
  if ~undefined(tqf) then title_string3 = 'TQF=' + string(tqf.Y[0],format="(%'%5.3f')")

  t = text(x1,.93,title_string,/current,font_size=16, font_color='black')
  t = text(x1,.87,title_string2,/current,font_size=16, font_color='black')
  if ~undefined(tqf) then t = text(x1,.81,title_string3,/current,font_size=16, font_color='black')

  t1 = text(0.5, yl+0.05, 'GSE Coordinates, Sun to the right', font_size=8, font_color='black')
  t1 = text(0.5, yl+0.025, 'Origin at MMS centroid', font_size=8, font_color='black')
end