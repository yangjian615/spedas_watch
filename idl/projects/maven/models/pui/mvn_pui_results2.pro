;20170417 Ali
;statistical analysis of pickup ion model results
;can be used to compute exospheric neutral densities using a reverse method

pro mvn_pui_results2

@mvn_pui_commonblock.pro ;common mvn_pui_common

  kefswih3d=transpose(pui.model[0].fluxes.swi3d.eflux,[3,0,1,2])
  kefswio3d=transpose(pui.model[1].fluxes.swi3d.eflux,[3,0,1,2])
  kefstah3d=transpose(pui.model[0].fluxes.sta3d.eflux,[3,0,1,2])
  kefstao3d=transpose(pui.model[1].fluxes.sta3d.eflux,[3,0,1,2])

  ;swap swia dimentions to match the model (time-energy-az-el)
  ;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
  swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
  d1eflux=transpose(pui.data.sta.d1.eflux,[4,0,1,2,3])

swio=swiaef3d/kefswio3d/(~kefswih3d) ;exospheric neutral O density (cm-3) data/model ratio
swih=swiaef3d/kefswih3d/(~kefswio3d)
stao=d1eflux[*,*,*,*,4]/kefstao3d
stah=d1eflux[*,*,*,*,0]/kefstah3d

subset=stah[*,0:24,*,*]
p=plot(transpose(subset),/ylog,'.')
avg=exp(mean(alog(subset),/nan))
stop

end
