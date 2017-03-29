;20160705 Ali
;routine to plot exospheric density profiles used in mvn_pui_model
;
pro mvn_pui_plot_exoden,noo=noo,noh=noh,overplot=overplot,xrange=xrange,yrange=yrange

rmars=3400. ;mars radius (km)

alt=1e3*findgen(300)/3 ;altitude (km)
rtot=1e3*(alt+rmars) ;radial distance (m)

nnh=mvn_pui_exoden(rtot,species='h') ;H density (cm-3)
nno=mvn_pui_exoden(rtot,species='o') ;O density (cm-3)

if ~keyword_set(xrange) then xrange=[1,1e6]
if ~keyword_set(yrange) then yrange=[1e2,1e5]
p=plot([0],overplot=overplot,/xlog,/ylog,xrange=xrange,yrange=yrange,title='',xtitle='$Mars Exospheric Neutral Density (cm^{-3})$',ytitle='Altitude (km)')
if ~keyword_set(noo) then p=plot(nno,alt,color='r',/o)
if ~keyword_set(noh) then p=plot(nnh,alt,color='b',/o)

end