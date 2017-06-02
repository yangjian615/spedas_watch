;20170424 Ali
;pickup ion statistical analysis of several days of data

pro mvn_pui_stat,nospice=nospice,noimg=noimg,trange=trange,nodataload=nodataload

@mvn_pui_commonblock.pro ;common mvn_pui_common

  if ~keyword_set(noimg) then begin
    xsize=3000
    ysize=1500
    wi,0,wsize=[xsize,ysize]
    wi,10,wsize=[xsize,ysize]
    wi,20,wsize=[xsize,ysize]
    wi,30,wsize=[xsize,ysize]
    wi,31,wsize=[xsize,ysize]
    g=window(background_color='k',dim=[400,200])
  endif

secinday=86400L ;number of seconds in a day
if ~keyword_set(trange) then trange=[time_double('14-11-27'),systime(1)]
;trange=['14-12-1','14-12-3']
trange=time_double(trange)
ndays=round((trange[1]-trange[0])/secinday) ;number of days
binsize=32.
nt=1+floor((secinday-binsize/2.)/binsize) ;number of time steps

if ~keyword_set(nospice) then begin
  timespan,trange
  kernels=mvn_spice_kernels(/all,/clear)
  spice_kernel_load,kernels,verbose=3
;  maven_orbit_tplot,colors=[4,6,2],/loadonly ;loads the color-coded orbit info
endif

fnan=!values.f_nan
xyz=replicate(fnan,3) ;xyz or [mean,stdev,nsample]
ifreq=replicate({pi:fnan,cx:fnan,ei:fnan},2)
d2m=replicate({sep:replicate(fnan,2),swi:xyz,sta:xyz},2)
stat=replicate({centertime:0d,mag:xyz,vsw:xyz,nsw:fnan,ifreq:ifreq,d2m:d2m},[nt,ndays])

for j=0,ndays-1 do begin ;loop over days
  tr=trange[0]+[j,j+1]*secinday
  mvn_pui_sw_orbit_coverage,trange=tr,res=binsize,alt_sw=alt_sw
  if where(finite(alt_sw),/null) eq !null then continue ;if no solar wind coverage, go to next day
  np=2017
  mvn_pui_model,binsize=binsize,np=np,/do3d,savetplot=~keyword_set(noimg),/nospice,trange=tr,nodataload=nodataload

  stat[*,j].centertime=pui.centertime
  stat[*,j].mag=pui.data.mag.mso
  stat[*,j].vsw=pui.data.swi.swim.velocity_mso
  stat[*,j].nsw=pui.data.swi.swim.density
  stat[*,j].ifreq.pi=pui.model.ifreq.pi.tot
  stat[*,j].ifreq.ei=pui.model.ifreq.ei.tot
  stat[*,j].ifreq.cx=pui.model.ifreq.cx
  stat[*,j].d2m.sep=pui.d2m.sep
  stat[*,j].d2m.swi=pui.d2m.swi
  stat[*,j].d2m.sta=pui.d2m.sta

  datestr=strmid(time_string(tr[0]),0,10)
  if ~keyword_set(noimg) then mvn_pui_tplot_3d_save,graphics=g,datestr=datestr

endfor
save,stat,binsize,np

stop
end