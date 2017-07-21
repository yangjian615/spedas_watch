;20170505 Ali
;statistical analysis on results of mvn_pui_stat

pro mvn_pui_stat2

if 0 then begin ;load all data
  restore,'C:\Users\rahmati\idl\idlsave_all6.dat' ;restores stat,binsize,np
  stat2=reform(stat,size(stat,/n_elements)) ;making stat 1d
  stat3=stat2[where(stat2.centertime gt 0.,/null)] ;where data is available
  if 1 then begin ;choose solar wind
    mvn_pui_sw_orbit_coverage,times=stat3.centertime,alt_sw=alt_sw,conservative=1,spice=1
    stat4=stat3[where(finite(alt_sw),/null,count1)] ;only solar wind, pretty conservative to keep bad stuff out
    save,stat4,binsize,np,filename='C:\Users\rahmati\idl\idlsave_sw6.dat'
  endif else stat4=stat3
endif else restore,'C:\Users\rahmati\idl\idlsave_sw6.dat' ;restores stat4,binsize,np
;stop

if 1 then begin ;getting rid of unfavorable upstream parameters
  usw=sqrt(total(stat4.vsw^2,1)) ;solar wind speed (km/s)
  mag=sqrt(total(stat4.mag^2,1)) ;magnetic field (T)
  costub=total(stat4.vsw*stat4.mag,1)/(usw*mag) ;cos(thetaUB)
  tub=!radeg*acos(costub) ;thetaUB 0<tub<180
  lowusw=usw lt 500. ;low usw
  lowmag=mag lt 1e-9 ;low mag (high error in B)
  lowtub=abs(costub) gt .9 ;thetaUB < 26deg
  stat4[where(lowusw or lowmag or lowtub,/null)].d2m.sep=!values.f_nan ;more reliable SEP
  stat4[where(lowmag or lowtub,/null)].d2m.swi[0]=!values.f_nan
  stat4[where(lowmag or lowtub,/null)].d2m.sta[0]=!values.f_nan
  if 0 then begin ;plot upstream parameter histogram distributions
    nsw_hist=histogram(10.*stat4.nsw)
    usw_hist=histogram(usw)
    mag_hist=histogram(1e10*mag)
    tub_hist=histogram(tub)
    p=plot(nsw_hist,xtitle='10*Nsw (cm-3)',/xlog)
    p=plot(usw_hist,xtitle='Usw (km/s)')
    p=plot(mag_hist,xtitle='10*MAG (nT)',/xlog)
    p=plot(tub_hist,xtitle='thetaUB (degrees)')
  endif
endif

if 1 then begin ;orbit averaging
  count2=n_elements(stat4) ;should be equal to count1 above
  dt=stat4[1:-1].centertime-stat4[0:-2].centertime ;must be equal to binsize, otherwise orbit jump
  index2=where(dt gt 60.*60.*24*10,/null,swjumps) ;solar wind jumps (swjumps: number of time periods entirely inside the bowshock)
  index3=where(dt gt binsize,/null,norbits) ;orbit jumps (norbits: number of orbits minus 1)
;  index3=where((stat4.centertime mod 1001) eq 0,/null,norbits)
  index4=lonarr(norbits+2) ;orbit edges
  index4[1:-2]=index3 ;last element of each orbit (except the last orbit)
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

if 0 then begin ;arbitrary averaging of orbit averages
  nbins=100
  range=minmax(stat4.centertime)
  stat6=stat5
  stat5=replicate(stat4[0],nbins)

  stat5.mag[0]=exp(average_hist(alog(stat6.mag[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.vsw[0]=average_hist(stat6.vsw[0],stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.nsw=exp(average_hist(alog(stat6.nsw),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[0].pi=average_hist(stat6.ifreq[0].pi,stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.ifreq[1].pi=average_hist(stat6.ifreq[1].pi,stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.ifreq[0].ei=exp(average_hist(alog(stat6.ifreq[0].ei),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[1].ei=exp(average_hist(alog(stat6.ifreq[1].ei),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[0].cx=exp(average_hist(alog(stat6.ifreq[0].cx),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[1].cx=exp(average_hist(alog(stat6.ifreq[1].cx),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sep[0]=exp(average_hist(alog(stat6.d2m[1].sep[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sep[1]=exp(average_hist(alog(stat6.d2m[1].sep[1]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[0].swi[0]=exp(average_hist(alog(stat6.d2m[0].swi[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].swi[0]=exp(average_hist(alog(stat6.d2m[1].swi[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[0].sta[0]=exp(average_hist(alog(stat6.d2m[0].sta[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sta[0]=exp(average_hist(alog(stat6.d2m[1].sta[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.centertime=xbins
endif

if 0 then begin ;everything
  stat5=stat4
  stat5.mag[0]=sqrt(total(stat4.mag^2,1))
  stat5.vsw[0]=sqrt(total(stat4.vsw^2,1))
endif

ct=stat5.centertime

if 1 then begin ;tplot stuff
  store_data,'pui_stat_mag',ct,1e9*stat5.mag[0]
  ylim,'pui_stat_mag',.1,100,1
  store_data,'pui_stat_usw',ct,stat5.vsw[0]
  ylim,'pui_stat_usw',100,1000,1
  store_data,'pui_stat_nsw',ct,stat5.nsw
  ylim,'pui_stat_nsw',.1,100,1

  store_data,'pui_stat_ifreq_pi_H',ct,stat5.ifreq[0].pi,limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_pi_O',ct,stat5.ifreq[1].pi,limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_cx_H',data={x:ct,y:stat5.ifreq[0].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_cx_O',data={x:ct,y:stat5.ifreq[1].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_ei_H',data={x:ct,y:stat5.ifreq[0].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_ei_O',data={x:ct,y:stat5.ifreq[1].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_H',data={x:ct,y:stat5.ifreq[0].pi+stat5.ifreq[0].cx},limits={ylog:1,yrange:[1e-7,1e-6]}
  store_data,'pui_stat_ifreq_O',data={x:ct,y:stat5.ifreq[1].pi+stat5.ifreq[1].cx},limits={ylog:1,yrange:[1e-7,1e-6]}
;  ylim,'pui_stat_ifreq_*',1e-8,1e-7,0
  options,'pui_stat_ifreq_pi_?','ystyle',1

  store_data,'pui_stat_d2m_sep1',ct,stat5.d2m[1].sep[0]
  store_data,'pui_stat_d2m_sep2',ct,stat5.d2m[1].sep[1]
  store_data,'pui_stat_d2m_swi_H',ct,stat5.d2m[0].swi[0]
  store_data,'pui_stat_d2m_swi_O',ct,stat5.d2m[1].swi[0]
  store_data,'pui_stat_d2m_sta_H',ct,stat5.d2m[0].sta[0]
  store_data,'pui_stat_d2m_sta_O',ct,stat5.d2m[1].sta[0]
  ylim,'pui_stat_d2m*',.1,10,1

  options,'pui_stat_*','psym',0
  tplot,'pui_stat_*
endif

;p=plot(stat5.mag[0],stat5.vsw[0],'.',/xlog) ;imf vs vsw (no correlation)
;p=plot(stat5.mag[0],stat5.nsw,'.',/xlog,/ylog) ;mag vs nsw (highly correlated)
;p=plot(stat5.vsw[0],stat5.nsw,'.',/ylog) ;vsw vs nsw (correlated)
;p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].ei,'.b',/xlog,/ylog,xrange=[1e-8,1e-5],yrange=[1e-9,1e-6]) ;cx vs ei (correlated)
;p=plot(stat5.ifreq[1].cx,stat5.ifreq[1].ei,'.r',/o)
;p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].pi,'.',/xlog,xrange=[1e-8,1e-5]) ;cx vs pi (not correlated)
;p=plot(stat5.ifreq[0].pi,stat5.ifreq[1].pi,'.') ;pi H vs O (correlated)
;p=plot(stat5.d2m[0].sta[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog)
;p=plot(stat5.vsw[0],stat5.d2m[1].sep[1],'.',/xlog,/ylog)
;p=plot(stat5.ifreq[1].pi,stat5.d2m[1].swi[0],'.b',xtitle=['PI freq (s-1)'],ytitle=['O d2m ratio'])
;p=plot(stat5.ifreq[1].pi,stat5.d2m[1].sta[0],'.r',/o,title='SWIA: blue, STATIC: red')
;p=plot(1e9*stat5.mag[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['MAG (nT)'],ytitle=['STATIC O d2m ratio'])
;p=plot(stat5.vsw[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['Usw (km/s)'],ytitle=['STATIC O d2m ratio'])
;p=plot(stat5.nsw,stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['Nsw (cm-3)'],ytitle=['STATIC O d2m ratio'])

;p=plot(/o,6e25*stat5.d2m[0].swi[0],'b')
;p=plot(/o,6e25*stat5.d2m[0].sta[0],'r')
;p=plot(/o,6e32*stat5.ifreq[0].cx,'g')

;mvn_pui_au_ls,times=ct,mars_au=mars_au,mars_ls=mars_ls,spice=0
;p=plot([0],/nodata,yrange=[1e25,1e27],/ylog,xtitle='$L_s$',ytitle='H escape rate ($s^{-1}$)')
;p=plot(/o,mars_ls,6e25*(stat5.d2m[0].sta[0]+stat5.d2m[0].swi[0])/2.,'g.')
;p=scatterplot(/o,mars_ls,6e25*(stat5.d2m[0].sta[0]+stat5.d2m[0].swi[0])/2.,magnitude=ct,rgb=33)

;p=plot(ct,stat5.d2m[0].sta[0]/stat5.d2m[0].swi[0],'b',/ylog,yrange=[.1,10],/stairs)
;p=plot(ct,stat5.d2m[1].sta[0]/stat5.d2m[1].swi[0],'r',/o,/stairs)

alswi=exp(average(alog(stat5.d2m.swi[0]),2,/nan))
alsta=exp(average(alog(stat5.d2m.sta[0]),2,/nan))
avswi=average(stat5.d2m.swi[0],2,/nan)
avsta=average(stat5.d2m.sta[0],2,/nan)
;stop
end