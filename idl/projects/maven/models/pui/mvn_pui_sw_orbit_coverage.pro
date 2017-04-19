;20170321 Ali
;orbit coverage statistics

pro mvn_pui_sw_orbit_coverage,trange=trange,plot=plt,res=res

if ~keyword_set(trange) then trange=['14-12-1','17-4-1']
if ~keyword_set(res) then res=60.*10.

;kernels=mvn_spice_kernels(['lsk','spk','std','sck','frm'],/clear,/load,trange=trange)
times=dgen(range=timerange(trange),res=res)

rmars=3400. ;mars radius (km)
pos=spice_body_pos('MAVEN','MARS',frame='MSO',utc=times) ;orbit position (km)
posx=reform(pos[0,*])
posy=reform(pos[1,*])
posz=reform(pos[2,*])
rad=sqrt(total(pos^2,1)) ;orbit radius (km)
alt=rad-rmars ;orbit altitude (km)
posr=sqrt(posy^2+posz^2) ;cylindrical radial distance (km)

ind=where(posx/rmars gt 1. and posx/rmars+.24*(posr/rmars)^2 gt 2.) ;staying outside the bow shock (pretty conservative)

if keyword_set(plt) then begin
  poshist2d=hist_2d(posx[ind]/rmars,posr[ind]/rmars,bin1=.1,bin2=.1,min1=-3.,max1=3.,min2=-3.,max2=3.)
  imx=.1*findgen(61)-3.
  imy=.1*findgen(61)-3.
  g=image(poshist2d,imx,imy,rgb_table=colortable(0,/reverse),axis_style=2,margin=.2)
  c=colorbar(target=g,/orientation)
  mvn_pui_plot_mars_bow_shock,/rm

  store_data,'mvn_pos_x',times,posx
  store_data,'mvn_pos_y',times,posy
  store_data,'mvn_pos_z',times,posz
  store_data,'mvn_pos_r',times,rad
endif

store_data,'mvn_pos_alt',times,alt
alt_sw=replicate(0.,size(times,/dim))
alt_sw[ind]=alt[ind]
store_data,'mvn_pos_sw',times,alt_sw

end