;20170505 Ali
;statistical analysis on results of mvn_pui_stat

pro mvn_pui_stat2

if 0 then begin
  restore,'C:\Users\rahmati\idl\idlsave_all.dat'
  stat2=reform(stat,size(stat,/n_elements)) ;making stat 1d
  stat3=stat2[where(stat2.centertime gt 0.,/null)] ;where data is available
  mvn_pui_sw_orbit_coverage,times=stat3.centertime,alt_sw=alt_sw,conservative=0
  stat4=stat3[where(finite(alt_sw),/null,count2)] ;only solar wind, pretty conservative to keep bad stuff out
endif

restore,'C:\Users\rahmati\idl\idlsave_sw.dat' ;restores stat4

;stop
stat4[where(sqrt(total(stat4.vsw^2,1)) lt 500.,/null)].d2m.sep=!values.f_nan ;only high solar wind speed for SEP
stat4[where(1e9*sqrt(total(stat4.mag^2,1)) lt .1,/null)].mag=!values.f_nan ;when IMF is less than .1 nT
stat4[where(stat4.nsw lt .1,/null)].nsw=!values.f_nan ;when solar wind density is less than .1 cm-3
if 1 then begin ;orbit binning
  count2=n_elements(stat4)
  dt=stat4[1:-1].centertime-stat4[0:-2].centertime ;must be 32 sec, otherwise orbit jump
  index3=where(dt ne 32.,/null,norbits) ;orbit jumps (number of orbits minus 1)
  index4=lonarr(norbits+2) ;orbit edges
  index4[1:-2]=index3 ;last element of each orbit
  index4[0]=-1 ;first orbit starting edge
  index4[-1]=count2-1 ;last orbit ending edge
  stat5=replicate(stat4[0],norbits+1) ;orbit average statistics

  for j=0,norbits do begin ;loop over days
    stat6=stat4[index4[j]+1:index4[j+1]]

    stat5[j].centertime=average(stat6.centertime)
    stat5[j].mag[0]=exp(average(alog(sqrt(total(stat6.mag^2,1))),/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].mag[1]=stdev
    stat5[j].mag[2]=nsamples
    stat5[j].vsw[0]=average(sqrt(total(stat6.vsw^2,1)),/nan,stdev=stdev,nsamples=nsamples)
    stat5[j].vsw[1]=stdev
    stat5[j].vsw[2]=nsamples
    stat5[j].nsw=exp(average(alog(stat6.nsw),/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].ifreq.pi=average(stat6.ifreq.pi,2,/nan,stdev=stdev,nsamples=nsamples)
    stat5[j].ifreq.ei=exp(average(alog(stat6.ifreq.ei),2,/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].ifreq.cx=exp(average(alog(stat6.ifreq.cx),2,/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].d2m.sep=exp(average(alog(stat6.d2m.sep),3,/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].d2m.swi[0]=exp(average(alog(stat6.d2m.swi[0]),2,/nan,stdev=stdev,nsamples=nsamples,weight=stat6.d2m.swi[2]))
    stat5[j].d2m.swi[1]=exp(stdev)
    stat5[j].d2m.swi[2]=nsamples
    stat5[j].d2m.sta[0]=exp(average(alog(stat6.d2m.sta[0]),2,/nan,stdev=stdev,nsamples=nsamples,weight=stat6.d2m.sta[2]))
    stat5[j].d2m.sta[1]=exp(stdev)
    stat5[j].d2m.sta[2]=nsamples
  endfor
end

if 1 then begin ;arbitrary binning
  nbins=10000
  range=minmax(stat4.centertime)
  stat5=replicate(stat4[0],nbins)

  stat5.mag[0]=exp(average_hist(alog(sqrt(total(stat4.mag^2,1))),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.mag[0]=average_hist(sqrt(total(stat4.mag^2,1)),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.vsw[0]=average_hist(sqrt(total(stat4.vsw^2,1)),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.nsw=exp(average_hist(alog(stat4.nsw),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[0].pi=average_hist(stat4.ifreq[0].pi,stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.ifreq[1].pi=average_hist(stat4.ifreq[1].pi,stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.ifreq[0].ei=exp(average_hist(alog(stat4.ifreq[0].ei),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[1].ei=exp(average_hist(alog(stat4.ifreq[1].ei),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[0].cx=exp(average_hist(alog(stat4.ifreq[0].cx),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[1].cx=exp(average_hist(alog(stat4.ifreq[1].cx),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sep[0]=exp(average_hist(alog(stat4.d2m[1].sep[0]),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sep[1]=exp(average_hist(alog(stat4.d2m[1].sep[1]),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[0].swi[0]=exp(average_hist(alog(stat4.d2m[0].swi[0]),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].swi[0]=exp(average_hist(alog(stat4.d2m[1].swi[0]),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[0].sta[0]=exp(average_hist(alog(stat4.d2m[0].sta[0]),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sta[0]=exp(average_hist(alog(stat4.d2m[1].sta[0]),stat4.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.centertime=xbins
endif

if 1 then begin ;everything
  stat5=stat4
  stat5.mag[0]=sqrt(total(stat4.mag^2,1))
  stat5.vsw[0]=sqrt(total(stat4.vsw^2,1))
endif

ct=stat5.centertime

if 0 then begin ;tplot stuff
  store_data,'pui_stat_mag',ct,1e9*stat5.mag[0]
  ylim,'pui_stat_mag',.1,100,1
  store_data,'pui_stat_usw',ct,stat5.vsw[0]
  store_data,'pui_stat_nsw',ct,stat5.nsw
  ylim,'pui_stat_nsw',.1,100,1

  store_data,'pui_stat_ifreq_pi_H',ct,stat5.ifreq[0].pi
  store_data,'pui_stat_ifreq_pi_O',ct,stat5.ifreq[1].pi
  store_data,'pui_stat_ifreq_cx_H',data={x:ct,y:stat5.ifreq[0].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_cx_O',data={x:ct,y:stat5.ifreq[1].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_ei_H',data={x:ct,y:stat5.ifreq[0].ei},limits={ylog:1,yrange:[1e-9,1e-7]}
  store_data,'pui_stat_ifreq_ei_O',data={x:ct,y:stat5.ifreq[1].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_H',data={x:ct,y:stat5.ifreq[0].pi+stat5.ifreq[0].cx},limits={ylog:1,yrange:[1e-7,1e-5]}
  store_data,'pui_stat_ifreq_O',data={x:ct,y:stat5.ifreq[1].pi+stat5.ifreq[1].cx},limits={ylog:1,yrange:[1e-7,1e-5]}
  ;ylim,'pui_stat_ifreq_*',1e-8,1e-6,1

  store_data,'pui_stat_d2m_sep1',ct,stat5.d2m[1].sep[0]
  store_data,'pui_stat_d2m_sep2',ct,stat5.d2m[1].sep[1]
  store_data,'pui_stat_d2m_swi_H',ct,stat5.d2m[0].swi[0]
  store_data,'pui_stat_d2m_swi_O',ct,stat5.d2m[1].swi[0]
  store_data,'pui_stat_d2m_sta_H',ct,stat5.d2m[0].sta[0]
  store_data,'pui_stat_d2m_sta_O',ct,stat5.d2m[1].sta[0]
  ylim,'pui_stat_d2m*',.1,10,1

  options,'pui_stat_*','psym',3
  ;tplot
endif

;p=plot(stat5.mag[0],stat5.vsw[0],'.',/xlog) ;imf vs vsw (no correlation)
;p=plot(stat5.mag[0],stat5.nsw,'.',/xlog,/ylog) ;mag vs nsw (highly correlated)
;p=plot(stat5.vsw[0],stat5.nsw,'.',/ylog) ;vsw vs nsw (correlated)
;p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].ei,'.',/xlog,/ylog,xrange=[1e-9,1e-5],yrange=[1e-9,1e-6]) ;cx vs ei (correlated)
;p=plot(stat5.d2m[0].sta[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog)
;p=plot(stat5.mag[0],stat5.d2m[1].sep[1],'.',/xlog,/ylog)

end