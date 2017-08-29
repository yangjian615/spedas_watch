pro eics_ui_overlay_plots, trange=trange, createpng=createpng, showgeo=showgeo, showmag=showmag

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
 
  ; Plot the geographic and magnetic grid lines
  loadct2,34  

  ;construct magnetic lats
  aacgmidl
  thm_init
  geographic_lons=[150,180,210,240,270,300,330,360]
  geographic_lats=[0,20,30,40,50,60,70,80]
  nmlats=round((max(geographic_lats)-min(geographic_lats))/float(10)+1)
  mlats=min(geographic_lats)+findgen(nmlats)*10
  n2=150
  v_lat=fltarr(nmlats,n2)
  v_lon=fltarr(nmlats,n2)
  height=100.
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
  if keyword_set(showgeo) then begin
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

  ; set up plotting parameters for use by plotxyvec
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
  lat=[lat,26]
  jy=[jy,0.]
  jx=[jx,200.]

  ; overplot the EICs onto the mosaic map
  plotxyvec,[[lon],[lat]],[[jy],[jx]],/overplot,color='y', thick=1.475,hsize=0.5, $
    uArrowTextPrecision=3, uarrowside='bottom', uarrowdatasize=200, arrowscale=scale, $
    uArrowRotation=270.,uarrowtext='mA/m', uarrowoffset=2.2, /noisotropic
  oplot,lon,lat,color=5,psym=2,symsize=0.25,thick=3

  xyouts, 215.5, 20, 'SECS - EICS', color=0, charsize=1.45  
  xyouts, 297.9, 25, '200 mA/m',charsize=1.45, charthick=1.25,color=5
  if keyword_set(showgeo) && keyword_set(showmag) then begin
     xyouts, 297.7, 29.25, 'Geo Black dot line', color=0, charthick=1.25, charsize=1.13
     xyouts, 299.2, 31, 'Mag Red dot line', color=250, charthick=1.2, charsize=1.125
  endif 
  if keyword_set(showgeo) && ~keyword_set(showmag) then begin
     xyouts, 297.7, 29.25, 'Geo Black dot line', color=0, charthick=1.25, charsize=1.13
  endif
  if ~keyword_set(showgeo) && keyword_set(showmag) then begin
     xyouts, 297.7, 29.25, 'Mag Red dot line', color=250, charthick=1.2, charsize=1.125   
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
    plotfile = 'ThemisMosaicEICS' + yr + mo + da + '_' + hr + mi + sc
    makepng, plotdir+plotfile, /mkdir
    print, 'PNG file created: ' + plotdir + plotfile 
  endif
  
return
end
