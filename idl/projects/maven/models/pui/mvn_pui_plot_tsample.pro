;20170216 Ali
;line plots of data at the times specified by cursor
;keywords:
;avrg: for averaged values over a time period
;tplot: for selecting the data from the current tplot window

pro mvn_pui_plot_tsample,tplot=tplot,avrg=avrg,overplot=overplot,xrange=xr,yrange=yr,zeros=zeros

@mvn_pui_commonblock.pro ;common mvn_pui_common

if n_elements(zeros) eq 0 then zeros=1e-7 ;to fix the stairs

if keyword_set(tplot) then begin
  var=tsample(val=en,aver=avrg,/silent)
  var[where(var eq 0,/null)]=zeros
  p=plot(en,var,/xlog,/ylog,/stairs,xrange=xr,yrange=yr,xtickunits='scientific',ytickunits='scientific',overplot=overplot)
  return
endif

if keyword_set(avrg) then np=2 else np=1

ctime,t,np=np,/silent
tstep=floor((t-pui[0].centertime)/pui0.tbin)
if n_elements(tstep) eq 1 then tstep=[tstep,tstep]

x1=pui1.sepet[0].sepbo ;sep1 energy table (keV)
x2=pui1.sepet[1].sepbo ;sep2 energy table (keV)
xi=.5+findgen(500) ;sep incident energy table (keV)
xtot=pui1.totet/1e3 ;tot energy table (keV)

y1d=average(pui[tstep[0]:tstep[1]].data.sep[0].rate_bo,2,/nan) ;data
y2d=average(pui[tstep[0]:tstep[1]].data.sep[1].rate_bo,2,/nan)
y1m=average(pui[tstep[0]:tstep[1]].model[1].fluxes.sep[0].model_rate,2,/nan) ;model
y2m=average(pui[tstep[0]:tstep[1]].model[1].fluxes.sep[1].model_rate,2,/nan)
y1i=average(pui[tstep[0]:tstep[1]].model[1].fluxes.sep[0].incident_rate,2,/nan) ;fov /[s keV]
y2i=average(pui[tstep[0]:tstep[1]].model[1].fluxes.sep[1].incident_rate,2,/nan)
ytot=average(pui[tstep[0]:tstep[1]].model[1].fluxes.toteflux,2,/nan)/xtot ;total flux /[s cm2 keV]

y1d[where(y1d eq 0,/null)]=zeros
y2d[where(y2d eq 0,/null)]=zeros
y1m[where(y1m eq 0,/null)]=zeros
y2m[where(y2m eq 0,/null)]=zeros
y1i[where(y1i eq 0,/null)]=zeros
y2i[where(y2i eq 0,/null)]=zeros
ytot[where(ytot eq 0,/null)]=zeros

xr=[0,1e4]
yr=[.01,1e4]
xt='Energy (keV)'
yt='Count Rate/Energy Bin (Hz)'
p=plot([0],/nodata,/xlog,/ylog,xrange=xr,yrange=yr,margin=.1,layout=[2,1,1],title='SEP1F',xtitle=xt,ytitle=yt,xtickunits='scientific',ytickunits='scientific')
p=plot(/o,x1,y1d,/stairs,'r')
p=plot(/o,x1,y1m,/stairs,'b')
p=plot(/o,xi,y1i,'m')
p=plot(/o,xtot,ytot,'g')
p=plot([0],/nodata,/xlog,/ylog,xrange=xr,yrange=yr,margin=.1,layout=[2,1,2],title='SEP2F',xtitle=xt,ytitle=yt,xtickunits='scientific',ytickunits='scientific',/current)
p=plot(/o,x2,y2d,/stairs,'r')
p=plot(/o,x2,y2m,/stairs,'b')
p=plot(/o,xi,y2i,'m')
p=plot(/o,xtot,ytot,'g')


xswepot=average(pui[tstep[0]:tstep[1]].data.swe.enpot,2,/nan) ;swea s/c potential corrected energy table (eV)
yswepot=average(pui[tstep[0]:tstep[1]].data.swe.efpot,2,/nan) ;swea flux

xswe=pui1.sweet ;swea energy table (eV)
yswe=average(pui[tstep[0]:tstep[1]].data.swe.eflux,2,/nan) ;swea flux

xswi=average(info_str[pui[tstep[0]:tstep[1]].data.swi.swis.info_index].energy_coarse,2,/nan) ;swia energy table (eV)
yswi=average(pui[tstep[0]:tstep[1]].data.swi.swis.data,2,/nan) ;swia energy flux

yswepot[where(yswepot eq 0,/null)]=zeros
yswe[where(yswe eq 0,/null)]=zeros
yswi[where(yswi eq 0,/null)]=zeros

xr=[1,30e3]
yr=[5e2,5e9]
xt='Energy (eV)'
yt='Eflux (eV/[cm2 s sr eV])'
p=plot([0],/nodata,/xlog,/ylog,xrange=xr,yrange=yr,title='SWEA/SWIA',xtitle=xt,ytitle=yt,xtickunits='scientific',ytickunits='scientific')
p=plot(/o,xswepot,yswepot,/stairs,'m')
p=plot(/o,xswe,yswe,/stairs,'b')
p=plot(/o,xswi,yswi,/stairs,'r')

;stop
end