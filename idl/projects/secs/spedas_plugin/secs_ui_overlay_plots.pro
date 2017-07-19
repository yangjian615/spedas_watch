pro secs_ui_overlay_plots, trange=trange, createpng=createpng

;  trange=['2015-03-18/0:12:00','2015-03-18/00:12:00']
; trange=['2008-03-09/9:30:00','2008-03-09/09:30:00']
;  trange=['2015-03-17/13:00:00','2015-03-17/13:00:00']
;  trange=['2015-03-17/09:37:00','2015-03-17/09:37:00']

  ; initialize variables
  defsysv,'!secs',exists=exists
  if not(exists) then secs_init
  defsysv,'!themis',exists=exists
  if not(exists) then thm_init
  thm_config
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
;  tr[1]=tr[0]
  inten=6001;
  
  ; extract the EICS data from the tplot vars
  ; sort the data into parameters and rotate they for plotxyvec
  secs_load_data, trange=tr,  datatype=['eics'], /get_stations
  get_data, 'secs_eics_latlong', data=latlon
  if ~is_struct(latlon) then begin
      dprint, 'There is no EICS data for date: '+time_string(tr[0])
      return
  endif
  lon=latlon.y[*,1]+360.
  lat=latlon.y[*,0]
  get_data, 'secs_eics_jxy', data=jxy
  if ~is_struct(jxy) then begin
    dprint, 'There is no EICS data for date: '+time_string(tr[0])
    return
  endif
  scale_factor=max(sqrt(jxy.y[*,0]^2+jxy.y[*,1]^2))
  jy=jxy.y[*,1]   ;/scale_factor
  jx=jxy.y[*,0]   ;/scale_factor
  get_data, 'secs_stations', data=stations
  if ~is_struct(stations) then begin
    dprint, 'There is no Station data for date: '+time_string(tr[0])
    ;return
  endif
  scale_factor=max(sqrt(jx^2+jy^2))
  if scale_factor GT 800. then scale=0.01 else scale=0.02

  ; Make the mosaic
  thm_asi_create_mosaic,time_string(tr[0]),/verbose,$            ; removed /thumb
      central_lon=264.0,central_lat=61.,scale=4.5e7,$         ; set lat to 64.5;set area scale=3.5or2.8e7 or scale=5.5e7,
      no_grid='no_grid',$     
      show  =['atha','fsmi','fykn','gako','gbay','gill','inuv','kapu','kian','kuuj','mcgr','nrsq','pgeo','pina','tpas','rank','snkq','talo','tpas','whit'] ,$
      minval=[0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 01],$
      maxval=[inten, 12000, inten, inten, inten, inten, inten, 8000, inten, inten, inten, inten, inten, 8000, inten, 5000,  8000,  inten,  8000, inten  ];
 
  ; Plot the geographic grid lines
  loadct2,34  
  geographic_lons=[180,210,240,270,300,330,360]
  geographic_lats=[20,30,40,50,60,70,80]
  thm_map_oplot_geographic_grid, $
      geographic_lons=geographic_lons,$
      geographic_lats=geographic_lats, $
      geographic_color=0,$
      geographic_linestyle=1
;stop
  ; Convert geographic lat/long to magnetic
;  aacgmidl
;  cnv_aacgm, geographic_lats, geographic_lons, 100., lat_out, lon_out, r, error 
;stop  
  ; set color table back and labels the grid lines
  loadct2,34
  xyouts, 328.1, 37.75, '330', charsize=1.2, charthick=1.25,color=0
  xyouts, 298., 32.15, '300', charsize=1.2, charthick=1.25,color=0
  xyouts, 268.25, 33.35, '270', charsize=1.2, charthick=1.25,color=0
  xyouts, 238.75, 31.5, '240', charsize=1.2, charthick=1.25,color=0
  xyouts, 209.35, 30.5, '210', charsize=1.2, charthick=1.25,color=0
  xyouts, 207., 38.75, '40', charsize=1.2, charthick=1.25,color=0
  xyouts, 206.75, 49, '50', charsize=1.2, charthick=1.25,color=0
  xyouts, 206.65, 59, '60', charsize=1.2, charthick=1.25,color=0
  xyouts, 206., 69, '70', charsize=1.2, charthick=1.25,color=0
  xyouts, 204., 79, '80', charsize=1.2, charthick=1.25,color=0

  ; plot the gmag stations

  if is_struct(stations) then begin
    oplot, stations.v[*,1], stations.v[*,0], psym=4, color=3
  endif
  ; set up plotting parameters for use by plotxyvec
  ;xrange = [0,90]
  ;yrange = [0,360]
  yrange = [30,80]
  xrange = [220,330]
  rows = 1
  cols = 1
  revrows = 0
  revcols = 0
  current = 0
  pos = !p.position
  plotvec = ptr_new(csvector('start'))

  ; create or update the system variable !tplotxy
  defsysv,'!tplotxy',exists=exists
  if not keyword_set(exists) then begin
    tpxy = { rows:rows,$
        revrows:revrows,$
        cols:cols,$
        revcols:revcols,$
        current:current,$
        pos:pos,$ 
        xrange:xrange,$
        yrange:yrange,$
        panels:ptr_new(), $
        plotvec:plotvec }
    defsysv, '!tplotxy', tpxy
  endif else begin
    !tplotxy.rows=rows
    !tplotxy.revrows=revrows
    !tplotxy.cols=cols
    !tplotxy.revcols=revcols
    !tplotxy.current=current
    !tplotxy.pos=pos
    !tplotxy.xrange=xrange
    !tplotxy.yrange=yrange
    !tplotxy.plotvec=plotvec
  endelse
  
  ; kluge: append unit vector to end of array for displaying legend
  ; todo: this should be working in plotxyvec but it isn't right now. need to debug
  lon=[lon,296.5]
  ;lon=[lon,300.]
  ;lat=[lat,27.75]
  lat=[lat,26]
  jy=[jy,0.]
  jx=[jx,200.]

  ; overplot the EICs onto the mosaic map
  plotxyvec,[[lon],[lat]],[[jy],[jx]],/overplot,color='y', thick=1.475,hsize=0.5, $
    uArrowTextPrecision=3, uarrowside='bottom', uarrowdatasize=200, arrowscale=0.01, $
    uArrowRotation=270.,uarrowtext='mA/m', uarrowoffset=2.2, /noisotropic
  oplot,lon,lat,color=5,psym=2,symsize=0.25,thick=3

  xyouts, 215.5, 20, 'SECs - EICs', color=0, charsize=1.45  
  xyouts, 297.9, 25, '200 mA/m',charsize=1.45, charthick=1.25,color=5

  if keyword_set(createpng) then begin
    ; construct png file name
    tstruc = time_struct(tr[0])
    yr = strmid(time_string(tr[0]),0,4)
    mo = strmid(time_string(tr[0]),5,2)
    da = strmid(time_string(tr[0]),8,2)
    hr = strmid(time_string(tr[0]),11,2)
    mi = strmid(time_string(tr[0]),14,2)
    sc = strmid(time_string(tr[0]),17,2)
    plotdir = !secs.local_data_dir + 'Mosaic/' + yr + '/' + mo + '/' + da + '/' 
    plotfile = 'ThemisMosaicEIC' + yr + mo + da + '_' + hr + mi + sc
    makepng, plotdir+plotfile, /mkdir
    print, 'PNG file created: ' + plotdir + plotfile 
  endif
  
return
end
