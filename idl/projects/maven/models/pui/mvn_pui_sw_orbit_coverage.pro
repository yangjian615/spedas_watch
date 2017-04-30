;20170321 Ali
;orbit coverage statistics

pro mvn_pui_sw_orbit_coverage,trange=trange,plot=plt,res=res,times=times,spice=spice,alt_sw=alt_sw

if ~keyword_set(trange) then trange=[time_double('14-10-1'),systime(1)]
if keyword_set(spice) then kernels=mvn_spice_kernels(['lsk','spk','std','sck','frm'],/clear,/load,trange=trange)

if ~keyword_set(res) then res=60.*10. ;default time resolution (10 mins)
if ~keyword_set(times) then times=dgen(range=timerange(trange),res=res)

rmars=3400. ;mars radius (km)
pos=spice_body_pos('MAVEN','MARS',frame='MSO',utc=times,check_objects=['MARS','MAVEN_SPACECRAFT']) ;orbit position (km)
posx=reform(pos[0,*])
posy=reform(pos[1,*])
posz=reform(pos[2,*])
rad=sqrt(total(pos^2,1)) ;orbit radius (km)
alt=rad-rmars ;orbit altitude (km)
posr=sqrt(posy^2+posz^2) ;cylindrical radial distance (km)

ind=where(posx/rmars gt 1.1 and posx/rmars+.24*(posr/rmars)^2 gt 2.1) ;staying outside the bow shock (pretty conservative)

if keyword_set(plt) then begin
  poshist2d=hist_2d(posx[ind]/rmars,posr[ind]/rmars,bin1=.1,bin2=.1,min1=0,max1=3.,min2=0,max2=3.)
  imx=.1*findgen(31)
  imy=.1*findgen(31)
  g=image(poshist2d,imx,imy,rgb_table=colortable(0,/reverse),axis_style=2,margin=.2)
  mvn_pui_plot_mars_bow_shock,/rm,/half
  c=colorbar(target=g,/orientation)

  store_data,'mvn_pos_x',times,posx
  store_data,'mvn_pos_y',times,posy
  store_data,'mvn_pos_z',times,posz
  store_data,'mvn_pos_r',times,rad
  store_data,'mvn_pos_alt',times,alt
endif

alt_sw=replicate(!values.f_nan,size(times,/dim))
alt_sw[ind]=alt[ind]
store_data,'mvn_alt_sw_(km)',times,alt_sw

end