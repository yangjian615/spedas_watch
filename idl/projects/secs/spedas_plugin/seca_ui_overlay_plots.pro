pro seca_ui_overlay_plots, trange=trange, createpng=createpng, showgeo=showgeo, showmag=showmag

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
 
  ; Plot the geographic and magnetic grid lines
  loadct2,34  

  ;construct magnetic lats
  aacgmidl
  thm_init
  geographic_lons=[180,210,240,270,300,330,360]
  geographic_lats=[20,30,40,50,60,70,80]
  nmlats=round((max(geographic_lats)-min(geographic_lats))/float(10)+1)
  mlats=min(geographic_lats)+findgen(nmlats)*10
  n2=150
  v_lat=fltarr(nmlats,n2)
  v_lon=fltarr(nmlats,n2)
  height=100.
  help, nmlats, mlats
  help, v_lat, v_lon
  for i=0,nmlats-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r,error,/geo
      v_lat[i,j]=u
      v_lon[i,j]=v
    endfor
  endfor
  ;plot magnetic lats
  if keyword_set(showmag) then begin
     for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1
  endif
  
  ; construct and plot geographic lats
  v1_lat=fltarr(nmlats,n2)
  v1_lon=fltarr(nmlats,n2)
  for i=0,nmlats-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r,error
      v1_lat[i,j]=u
      v1_lon[i,j]=v
    endfor
  endfor
  if keyword_set(whogeo) then begin
     for i=0,nmlats-1 do oplot,v1_lon[i,*],v1_lat[i,*],color=0,thick=contour_thick,linestyle=1
  endif

  ;construct geographic lons
  nmlons=24 ;mlons shown at intervals of 15 degrees or one hour of MLT
  mlon_step=30   ;round(360/float(nmlons))
  n2=20
  u_lat=fltarr(nmlons,n2)
  u_lon=fltarr(nmlons,n2)
  cnv_aacgm, 56.35, 265.34, height, outlat,outlon,r,error   ;Gillam
  mlats=min(geographic_lats)+findgen(n2)/float(n2-1)*(max(geographic_lats)-min(geographic_lats))
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r,error
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor
  ; plot geographic lons
  if keyword_set(showgeo) then begin
     for i=0,nmlons-1 do begin
       idx=where(u_lon[i,*] NE 0)
       oplot,u_lon[i,idx],u_lat[i,idx],color=0,thick=contour_thick,linestyle=1
     endfor
  endif

  ; construct and plot magnetic lons
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r,error,/geo
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor
  if keyword_set(showmag) then begin
     for i=0,nmlons-1 do begin
       idx=where(u_lon[i,*] NE 0)
       oplot,u_lon[i,idx],u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
     endfor
  endif
  
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
  xyouts, 296., 26, '+/- 20000 A',charsize=1.2, charthick=1.25,color=0
  xyouts, 297., 27.5, '+',charsize=1.4, charthick=2,color=250
  oplot, [300.95,300.95], [25.75,25.75], psym=6, color=50
  
  
  if keyword_set(showgeo) && keyword_set(showmag) then begin
     xyouts, 298, 29., 'Geo Black dot line', color=0, charthick=1.25, charsize=1.13
     xyouts, 299.2, 31, 'Mag Red dot line', color=250, charthick=1.2, charsize=1.125
     if is_struct(stations) then xyouts, 300.85, 32.65, 'GMAG green star', color=150, $
       charthick=1.2, charsize=1.125
  endif
  if keyword_set(showgeo) && ~keyword_set(showmag) then begin
    xyouts, 298, 29., 'Geo Black dot line', color=0, charthick=1.25, charsize=1.13
    if is_struct(stations) then xyouts, 299.2, 31, 'GMAG green star', color=150, $
      charthick=1.2, charsize=1.125
  endif
  if ~keyword_set(showgeo) && keyword_set(showmag) then begin
     xyouts, 298, 29., 'Mag Red dot line', color=250, charthick=1.2, charsize=1.125
     if is_struct(stations) then xyouts, 299.2, 31, 'GMAG green star', color=150, $
       charthick=1.2, charsize=1.125
  endif
  if ~keyword_set(showgeo) && ~keyword_set(showmag) then begin
    if is_struct(stations) then xyouts, 298., 29., 'GMAG green star', color=150, $
      charthick=1.2, charsize=1.125
  endif

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
