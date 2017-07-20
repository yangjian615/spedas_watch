pro seca_ui_overlay_plots, trange=trange, createpng=createpng

;  trange=['2015-03-18/0:12:00','2015-03-18/00:12:00']

  ; initialize variables
  defsysv,'!secs',exists=exists
  if not(exists) then secs_init
  defsysv,'!themis',exists=exists
  if not(exists) then thm_init
  thm_config
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  tr[1]=tr[0]
  inten=6001;
  
  ; extract the EICS data from the tplot vars
  ; sort the data into parameters and rotate they for plotxyvec
  secs_load_data, trange=tr,  datatype=['seca'], /get_stations
  get_data, 'secs_seca_latlong', data=latlon
  if ~is_struct(latlon) then begin
      dprint, 'There is no SECS data for date: '+time_string(tr[0])
      return
  endif
  lon=latlon.y[*,1]
  lat=latlon.y[*,0]
  get_data, 'secs_seca_amp', data=amp

  if ~is_struct(amp) then begin
    dprint, 'There is no SECS data for date: '+time_string(tr[0])
    return
  endif
  get_data, 'secs_stations', data=stations
  if ~is_struct(stations) then begin
    dprint, 'There is no Station data for date: '+time_string(tr[0])
  endif

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
    oplot, stations.v[*,1], stations.v[*,0], psym=2, color=150
  endif

  ; overplot the EICs onto the mosaic map
  nidx=where(amp.y LT 0, ncnt)
  pidx=where(amp.y GE 0, pcnt)
  if ncnt GT 0 then oplot, lon[nidx], lat[nidx], psym=6, color=50
  if pcnt GT 0 then oplot, lon[pidx], lat[pidx], psym=1, color=250

  xyouts, 215.5, 20, 'SECS - SECA', color=0, charsize=1.45  
;  xyouts, 297.9, 25, '+/- 20000 A',charsize=1.3, charthick=1.25,color=0
  xyouts, 296., 26, '+/- 20000 A',charsize=1.4, charthick=1.25,color=0
  xyouts, 297., 27.5, '+',charsize=1.4, charthick=2,color=250
  oplot, [300.95,300.95], [25.75,25.75], psym=6, color=50

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
    plotfile = 'ThemisMosaicSECA' + yr + mo + da + '_' + hr + mi + sc
    makepng, plotdir+plotfile, /mkdir
    print, 'PNG file created: ' + plotdir + plotfile 
  endif
  
return
end
