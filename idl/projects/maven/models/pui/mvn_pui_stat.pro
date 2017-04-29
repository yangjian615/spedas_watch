;20170424 Ali
;pickup ion statistical analysis of several days of data

pro mvn_pui_stat,nospice=nospice

@mvn_pui_commonblock.pro ;common mvn_pui_common

xsize=3000
ysize=1500
wi,0,wsize=[xsize,ysize]
wi,10,wsize=[xsize,ysize]
wi,20,wsize=[xsize,ysize]
wi,30,wsize=[xsize,ysize]
wi,31,wsize=[xsize,ysize]
g=window(background_color='k',dim=[400,200])

secinday=86400L ;number of seconds in a day
trange=['14-12-1','15-3-1']
;trange=['14-12-1','14-12-3']
trange=time_double(trange)
ndays=round((trange[1]-trange[0])/secinday) ;number of days

if ~keyword_set(nospice) then begin
  timespan,trange
  kernels=mvn_spice_kernels(/all,/clear)
  spice_kernel_load,kernels,verbose=3
  maven_orbit_tplot,colors=[4,6,2],/loadonly ;loads the color-coded orbit info
endif

stat=replicate({date:'',d2m:replicate({sep:replicate(0.,2),swi:0.,sta:0.},2)},ndays)

for j=0,ndays-1 do begin ;loop over days
  tr=trange[0]+[j,j+1]*secinday
  mvn_pui_model,bin=32.01,np=2017,/do3d,/savetplot,/nospice,trange=tr
  swalt=pui.data.swalt
  d2msw=pui[where(finite(swalt),/null)].d2m
  stat[j].d2m[1].sep[0]=exp(mean(alog(d2msw[1,*].sep[0]),/nan))
  stat[j].d2m[1].sep[1]=exp(mean(alog(d2msw[1,*].sep[1]),/nan))
  stat[j].d2m[0].swi=exp(mean(alog(d2msw[0,*].swi),/nan))
  stat[j].d2m[1].swi=exp(mean(alog(d2msw[1,*].swi),/nan))
  stat[j].d2m[0].sta=exp(mean(alog(d2msw[0,*].sta),/nan))
  stat[j].d2m[1].sta=exp(mean(alog(d2msw[1,*].sta),/nan))
  
  datestr=strmid(time_string(pui0.trange[0]),0,10)
  stat[j].date=datestr

  mvn_pui_tplot_3d,/swia,/mo,/nowin

  g.save,datestr+'_3d_swia_model.png'
  g.erase

  mvn_pui_tplot_3d,/swia,/da,/nowin
  g.save,datestr+'_3d_swia_data.png'

  g.erase
  mvn_pui_tplot_3d,/swia,/d2,/nowin
  g.save,datestr+'_3d_swia_d2m.png'

  g.erase
  mvn_pui_tplot_3d,/stah,/mo,/nowin
  g.save,datestr+'_3d_stah_model.png'

  g.erase
  mvn_pui_tplot_3d,/stah,/da,/nowin
  g.save,datestr+'_3d_stah_data.png'

  g.erase
  mvn_pui_tplot_3d,/stah,/d2,/nowin
  g.save,datestr+'_3d_stah_d2m.png'

  g.erase
  mvn_pui_tplot_3d,/stao,/mo,/nowin
  g.save,datestr+'_3d_stao_model.png'

  g.erase
  mvn_pui_tplot_3d,/stao,/da,/nowin
  g.save,datestr+'_3d_stao_data.png'

  g.erase
  mvn_pui_tplot_3d,/stao,/d2,/nowin
  g.save,datestr+'_3d_stao_d2m.png'

endfor

stop
end