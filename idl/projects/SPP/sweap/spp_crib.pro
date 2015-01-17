compile_opt idl2


pro print_rates,t
if ~keyword_set(t) then ctime,t,npoint=2,/silent
print,tsample('spp_spanai_rates_VALID_CNTS',t,/average)
print,tsample('spp_spanai_rates_MULTI_CNTS',t,/average)
print,tsample('spp_spanai_rates_START_CNTS',t,/average)
print,tsample('spp_spanai_rates_STOP_CNTS',t,/average)
end




pro spp_tof_histogram,trange=trange,xrange=xrange,ylog=ylog,binsize=binsize,noerase=noerase
if ~keyword_set(trange) then ctime,trange,npoints=2

csize = 2
spp_apid_data,'3B9'x,apdata=ap
;print_struct,ap
events = *ap.dataptr
if keyword_set(trange) then begin
  w = where(events.time ge trange[0] and events.time le trange[1],nw)
  if nw ne 0 then events = events[w] else dprint,'No points selected - using all'
endif

col = bytescale(indgen(16))
nc = n_elements(col)
;if ~keyword_set(xrange) then xrange=[450,600]
if ~keyword_set(binsize) then binsize = 1
h = histbins(events.tof,xb,binsize=binsize,shift=0)

if keyword_set(ylog) then begin
  mx = max(h)
  yrange = [mx/10^(ylog+3),mx]
  yrange  = [.5,mx*2]
endif

plot,/nodata,xb,h * 1.1,xrange=xrange,charsize=csize,yrange=yrange,ylog=ylog,ystyle=3,noerase=noerase
mxt = max(h)

for i=15,0,-1 do begin
  c=col[i mod nc]
  w = where(events.channel eq i, nw)
  if nw eq 0 then continue
  h = histbins(events[w].tof,xb,binsize=binsize,shift=0)
  oplot,xb,h,color=c,psym=10
  oplot,xb,h,color=c,psym=1
  mx = max(h,b)
  xyouts,xb[b],h[b]+mxt*.03,strtrim(i,2),color=c,align=.5,charsize=2
endfor

end





pro spp_init_realtime,filename=filename,base=base
common spp_crib_com2, recorder_base,exec_base
exec,exec_base,exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*300'

host = 'ABIAD-SW.ssl.berkelely.edu'
host = 'localhost'
recorder,recorder_base,port=2024,host=host,exec_proc='spp_ptp_stream_read',destination='spp_raw_YYYYMMDD_hhmmss.ptp',get_filename=filename
printdat,recorder_base,filename

spp_swp_apid_data_init,save=1

spp_apid_data,'3be'x,rt_tags='*'
spp_apid_data,'3bb'x,rt_tags='*'
spp_apid_data,'3b9'x,rt_tags='*'
spp_apid_data, rt_flag = 1

spp_apid_data,apdata=ap
print_struct,ap

if 0 then begin
  f1= file_search('spp*.ptp')
  spp_apid_data,rt_flag=0
  spp_ptp_file_read,f1[-1]
  spp_apid_data,rt_flag=1
endif
base = recorder_base

end




if 0 then begin
  

  src = file_retrieve(/str)
  src.remote_data_dir='http://sprg.ssl.berkeley.edu/data/

  if 0 then begin
    url_index = 'http://sprg.ssl.berkeley.edu/data/spp/sweap/prelaunch/gsedata/EM/spanai/'
    pathindex = strmid(url_index,strlen(src.remote_data_dir))
    indexfile = file_retrieve(_extra=src,pathindex)+'/.remote-index.html'
    links = file_extract_html_links(indexfile,count,verbose=verbose,no_parent=url_index)  ; Links with '*' or '?' or leading '/' are removed.
    fileformat = 'spp/sweap/prelaunch/gsedata/EM/spanai/'+links[-1]+'PTP_data.dat'
  endif

  fileformat = 'spp/sweap/prelaunch/gsedata/EM/spanai/2015*/PTP_data.dat'
  file = file_retrieve(_extra=src,fileformat,/last_version)
  spp_ptp_file_read,file
spp_apid_data,rt_flag=1
  
;  del_data,'*'
;  f= file_search('~/Downloads/PTP*.dat')
  f1= file_search('spp*.ptp')
;  f2=file_search('/disks/data/spp/sweap/','*PTP*')
  files = [F2[-1],f1[-1]]
  files = [file,f1[-1]]
  
  store_data,'*',/clear
  ;spp_apid_data,rt_flag=0
  spp_ptp_file_read,files

  spp_apid_data,rt_flag=1



ylim,'*rate*CNTS',.5,1000,1

rt_flag = 0


options,'*rates*CNTS',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.1,1000],/ylog,ystyle=3,psym=-1,symsize=.5
options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
options,'*events*',psym=3,ystyle=3

ctime,tr
reduce_timeres_data,'spp_spanai_rates_*CNTS',10.,trange=tr

tplot,' *CMD_REC *rate*CNTS *ACC *MCP *events*'
  
  spp_apid_data,apdata=ap
  print_struct,ap  
  
spp_tof_histogram,/ylog  ;,trange,xrange=xrange


gunvoltage =[0,10.3,50.3,100.4,500.3,1000.3,2000.1,3000.1,4000.1]
gunsupplycurrent = [.0013,.0015,.0024,.0033,.0115,.0216,.0418,.0619,.0820]
plot,gunvoltage,gunsupplycurrent

  
endif


end


