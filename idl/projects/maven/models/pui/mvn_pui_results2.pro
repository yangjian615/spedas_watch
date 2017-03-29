;20160525 Ali
;manipulating pickup ion model results, doing statistics, etc.
;can be used to compute exospheric neutral densities using a reverse method

pro mvn_pui_results2

@mvn_pui_commonblock.pro ;common mvn_pui_common

ebinlimo=20 ;energy bin limit for oxygen
ebinlimh=23 ;energy bin limit for hydrogen
radmin=5e3 ;minimum radius (km)
radmax=20e3;maximum radius (km)
szamax=70; max sza (degree)

;mvn_pui_model,/do3d,/exoden,binsize=32,trange=tr
;mvn_pui_tplot,/tplot1d

kefswih3d=pui.model[0].fluxes.swi3d.eflux
kefswio3d=pui.model[1].fluxes.swi3d.eflux
kefstah3d=pui.model[0].fluxes.sta3d.eflux
kefstao3d=pui.model[1].fluxes.sta3d.eflux

;swap swia dimentions to match the model (energy-az-el-time)
;also, reverse the order of elevation (deflection) angles
swiaef3d=reverse(transpose(pui.data.swi.swica.data,[0,2,1,3]),3)

d1eflux=pui.data.sta.d1.eflux

no=swiaef3d/kefswio3d/(~kefswih3d) ;exospheric neutral O density (cm-3) data/model ratio
nh=swiaef3d/kefswih3d/(~kefswio3d) ;exospheric neutral H density (cm-3) data/model ratio

subset=no[0:3,*,*,*]
p=plot(subset,/ylog,'.')
avg=exp(mean(alog(subset),/nan))
stop

end
