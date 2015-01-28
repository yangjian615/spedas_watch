
function spp_spc_met_to_unixtime,met
  epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ; Normal use
  unixtime =  met +  epoch
  return,unixtime
end



function spp_swp_spanai_rates_decom,ccsds, ptp_header=ptp_header, apdat=apdat 
  b = ccsds.data
  psize = 84
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif
  
  sf0 = ccsds.data[11] and 3
;  print,sf0
;hexprint,ccsds.data[0:29]

  rates = float( reform( spp_sweap_log_decomp( ccsds.data[20:83] , 0 ) ,4,16))
;  rates = float( reform( float( ccsds.data[20:83] ) ,4,16))
  
  time = ccsds.time 
  if 0 then begin   ;     cluge to correct times
    if keyword_set(apdat) && size(/type,*apdat.last_ccsds) eq 8 then begin
      ltime =  (*apdat.last_ccsds).time
      dt = time - ltime
      if dt le 0 then begin
        time += .86/4 - dt
        ccsds.time = time
      endif else rates=rates/2 
    endif
  endif else if 1 then begin
    if sf0 eq 1 then  rates=rates/2
    
  endif
    
  rates_str = { $
    time: time, $
    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    valid_cnts: reform( rates[0,*]) , $
    multi_cnts: reform( rates[1,*]), $
    start_cnts: reform( rates[2,*] ), $
    stop_cnts:  reform( rates[3,*]) }

  return,rates_str
end



function spp_swp_spanai_event_decom,ccsds, ptp_header=ptp_header, apdat=apdat
  b = ccsds.data
  psize = 2048
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  time = ccsds.time
  
  wrds = swap_endian(ulong(ccsds.data,20,(2048-20)/4) ,/swap_if_little_endian )
  tf = (wrds and '80000000'x) ne 0
  w_tt = where(tf,n_tt)
  w_dt= where(~tf,n_dt)
  tt =  uint(wrds)   ; and 'ffff'x
  dt = ishft(wrds,-16) and '1fff'x
  tof = wrds and 'fff'x
;  tof = wrds and '7ff'x
;  nonve = (wrds and '800'x) ne 0
  ch  = ishft(wrds and 'ffff'x,-12 )
  
  ttw=tt[w_tt]
  dttw = ttw - shift(ttw,1)
  dttw[0] = ttw[0]
  ttw2= total(/cum,/preserve,ulong(dttw))
  
  tw = replicate(0ul, n_elements(wrds) )
  tw[w_tt] = dttw
  tw = total(/cumulative,/preserve,tw)
  
  tdt = tw[w_dt]

  events = replicate( {time:0d, seq_cntr15:ccsds.seq_cntr and 'f'x,  channel:0b,  TOF:0u, dt:0u } , n_dt )
  events.time = ccsds.time + (tdt-tdt[0])/ 2.^10 * (2d^17/150000d)
  events.channel = ch[w_dt]
  events.tof = tof[w_dt]
  events.dt = dt[w_dt]

  event_str = { $
    time: time, $
    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    n_tt: n_tt,$
    n_dt: n_dt,$
    tt0: uint(wrds[w_tt[0]] and 'ffff'x), $
    wrds: wrds }
    
;  event_times = replicate( { time: 0d,seq_cntr15:ccsds.seq_cntr and 'f'x, valmod: 0u }, n_tt )
;  event_times.time = ccsds.time + (ttw2 - ttw2[0]) / 2.^10
;  event_times.valmod= ttw
  
  return, events
end





function spp_swp_spanai_slow_hkp_decom,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

b = ccsds.data
psize = 68
if n_elements(b) ne psize then begin
  dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
  return,0
endif

sf0 = ccsds.data[11] and 3
if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)

ref = 5. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)

spai = { $
  time: ccsds.time, $
  met: ccsds.met,  $
  delay_time: ptp_header.ptp_time - ccsds.time, $
  seq_cntr: ccsds.seq_cntr, $
  GND0: b[16],  $
  GND1: b[17],  $
  LVPS_TEMP: b[18] * 1.,  $
  Vmon_22VA: b[19] * 0.1118 ,  $
  vmon_1P5V: b[20] * .0068  ,  $
  Imon_3P3VA: b[21] * .0149 ,  $
  vmon_3P3VD: b[22] * .0149 ,  $
  Imon_N12VA: b[23] * .0456 ,  $
  Imon_N5VA: b[24]  * .0251 ,  $
  Imon_P12VA: b[25] * .0449 ,  $
  Imon_P5VA: b[26] * .0252 ,  $
  ANAL_TEMP: b[27] *1.,  $
  IMON_3P3I: b[28] * 1.15,  $
  IMON_1P5I: b[29] * .345,  $
  IMON_P5I: b[30] * 1.955,  $
  IMON_N5I: b[31] * 4.887,  $
  HVMON_ACC:  swap_endian(/swap_if_little_endian,  fix(b,32 ) ) * ref*3750./4095. , $
  HVMON_DEF1: swap_endian(/swap_if_little_endian,  fix(b,34 ) ) * ref*1000./4095., $
  HIMON_ACC: swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * ref/130.*1000./4095. , $
  HVMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * ref*1000./4095. , $
  HVMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * ref*938./4095 , $
  HVMON_SPOIL:swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * ref*80./4./4095. , $
  HIMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * ref*20.408/4095 , $
  TDC_TEMP:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * 1. , $
  HVMON_RAW: swap_endian(/swap_if_little_endian,  fix(b,48 ) ) *  ref*1250./4095 , $
  FPGA_TEMP: swap_endian(/swap_if_little_endian,  fix(b,50 ) )  , $
  HIMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref*25./ 4095. , $
;  spare0
;  spare1
  HVMON_HEM: swap_endian(/swap_if_little_endian,   fix(b,56 ) ) *ref *1000./4095  , $
;  spare2
;  spare3
;  SPAI_0X11
  CMD_ERRS: ishft(b[61],-4), $
  CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,61 ) ) and 'fff'x , $
;  SPAI_0X44
  MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
;  SPAI_00
  ACTSTAT_FLAG: b[67]  , $
  GAP: ccsds.gap }
  
  return,spai

end


function spp_log_message_decom,ccsds, ptp_header=ptp_header, apdat=apdat
;  printdat,ccsds
;  time=ccsds.time
;  printdat,ptp_header
;  hexprint,ccsds.data
  time = ptp_header.ptp_time
  msg = string(ccsds.data[10:*])
  dprint,dlevel=2,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seq_cntr,size:ccsds.size,msg:msg}
  return,str
end


function spp_spane_test1_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  cnts = ccsds.data[20:*]
  
  str = { $
    time:ptp_header.ptp_time, $
    seq_cntr:ccsds.seq_cntr,  $
    cnts: float(cnts) }
    
  return, str
end


function spp_generic_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  str = create_struct(ptp_header,ccsds)
;  dprint,format="('Generic routine for ',Z04)",ccsds.apid

  return,str

end



function spp_ccsds_decom,buffer             ; buffer should contain bytes for a single ccsds packet, header is contained in first 3 words (6 bytes)
  buffer_length = n_elements(buffer)
  if buffer_length lt 12 then begin
    dprint,'Invalid buffer length: ',buffer_length
    return, 0
  endif
  header = swap_endian(uint(buffer[0:11],0,6) ,/swap_if_little_endian )
  MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) + (header[5] and '3'x) * 2d^15/150000
  utime = spp_spc_met_to_unixtime(MET)
  ccsds = { $
    version_flag: byte(ishft(header[0],-8) ), $
    apid: header[0] and '7FF'x , $
    seq_group: ishft(header[1] ,-14) , $
    seq_cntr: header[1] and '3FFF'x , $
    size : header[2]   , $
    time: utime,  $
    MET:  MET,   $
    ;    time_diff: cmnblk.time - time, $   ; time to get transferred from PFDPU to GSEOS
    data:  buffer[0:*], $
    gap : 0b }

  if MET lt 1e5 then begin
    dprint,dlevel=3,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = !values.d_nan
  endif

;  if ccsds.size ne (n_elements(ccsds.data))-7 then begin
;    dprint,dlevel=3,format='(a," x",z04,i7,i7)','CCSDS size error',ccsds.apid,ccsds.size,n_elements(ccsds.data)
;  endif

  return,ccsds

end






pro spp_apid_data,apid,name=name,clear=clear,reset=reset,save=save,finish=finish,apdata=apdat,tname=tname,tfields=tfields,rt_tags=rt_tags,routine=routine,increment=increment,rt_flag=rt_flag
  common spp_swp_raw_data_block_com, all_apdat
  if keyword_set(reset) then begin
    ptr_free,ptr_extract(all_apdat)
    all_apdat=0
    return
  endif
  
  if ~keyword_set(all_apdat) then begin
    apdat0 = {  apid:-1 ,name:'',counter:0uL,nbytes:0uL, maxsize: 0,  routine:   '',   tname: '',  tfields: '',  rt_flag:0b, rt_tags: '', save:0b, $
;       status_ptr: ptr_new(), $
       last_ccsds: ptr_new(),  dataptr:  ptr_new(),   dataindex: ptr_new() , dlimits:ptr_new() }
    all_apdat = replicate( apdat0,2^11 )
  endif
  if keyword_set(finish) then begin
    for i=0,n_elements(all_apdat)-1 do begin
      ap = all_apdat[i]
      if ptr_valid(ap.dataptr) then append_array,*ap.dataptr,index = *ap.dataindex
      if keyword_set(ap.tfields) then store_data,ap.tname,data= *ap.dataptr,tagnames=ap.tfields
    endfor
  endif

  if n_elements(apid) ne 0 then begin
    apdat = all_apdat[apid]
    if n_elements(name)     ne 0 then apdat.name = name
    if n_elements(routine)  ne 0 then apdat.routine=routine
    if n_elements(rt_flag)  ne 0 then apdat.rt_flag = rt_flag
    if n_elements(tname)    ne 0 then apdat.tname = tname
    if n_elements(tfields)  ne 0 then apdat.tfields = tfields  
    if n_elements(save)     ne 0 then apdat.save   = save  
    if n_elements(rt_tags)  ne 0 then apdat.rt_tags=rt_tags
    if keyword_set(increment) then apdat.counter += 1
    for i=0,n_elements(apdat)-1 do begin
      if apdat[i].apid lt 0 then begin
        if ~ptr_valid(apdat[i].last_ccsds) then apdat[i].last_ccsds = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dataptr)    then apdat[i].dataptr    = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dataindex)  then apdat[i].dataindex  = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dlimits)    then apdat[i].dlimits    = ptr_new(/allocate_heap)
      endif
    endfor
    apdat.apid = apid
    all_apdat[apid] = apdat    ; put it all back in
  endif  else begin
    if n_elements(rt_flag) ne 0 then all_apdat.rt_flag=rt_flag
    w= where(all_apdat.apid ge 0,nw)
    if nw ne 0 then apdat = all_apdat[w] else apdat=0
  endelse
  
  if keyword_set(clear) and keyword_set(apdat) then begin
    ptrs = ptr_extract(apdat,except=apdat.dlimits)
    for i=0,n_elements(ptrs)-1 do undefine,*ptrs[i]
    all_apdat.counter = 0   ; this is clearing all counters - not just the subset.
  endif
end



pro spp_swp_apid_data_init,save=save
  spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom',tname='spp_spanai_hkp_',tfields='*',save=save
  spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom',tname='spp_spanai_rates_',tfields='*',save=save
  spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',tname='spp_spanai_events_',tfields='*',save=save
  
;  spp_apid_data,'359'x ,routine='spp_generic_decom',tname='spp_spane_events_',tfields='*', save=save
  spp_apid_data,'360'x ,routine='spp_generic_decom',tname='spp_spane_events_',tfields='*', save=save
  
  spp_apid_data,'7c0'x,routine='spp_log_message_decom',tname='log_',tfields='MSG',save=1,rt_tags='MSG',rt_flag=1
  
end





pro spp_ccsds_pkt_handler,buffer,ptp_header=ptp_header

  ccsds=spp_ccsds_decom(buffer)
    
  if ~keyword_set(ccsds) then begin
    dprint,'Invalid CCSDS packet'
    dprint,time_string(ptp_header.ptp_time)
    hexprint,buffer
    return
  endif

  if 1 then begin
    spp_apid_data,ccsds.apid,apdata=apdat,/increment
    if (size(/type,*apdat.last_ccsds) eq 8)  then begin    ; look for data gaps
      dseq = (( ccsds.seq_cntr - (*apdat.last_ccsds).seq_cntr ) and '3fff'x) -1
      if dseq ne 0  then begin
        ccsds.gap = 1
        dprint,dlevel=3,format='("Lost ",i5," ", Z03, " packets")',dseq,apdat.apid
      endif
    endif
    if keyword_set(apdat.routine) then begin
      strct = call_function(apdat.routine,ccsds,ptp_header=ptp_header,apdat=apdat)
      if  apdat.save && keyword_set(strct) then begin
        if ccsds.gap eq 1 then append_array, *apdat.dataptr, fill_nan(strct), index = *apdat.dataindex
        append_array, *apdat.dataptr, strct, index = *apdat.dataindex
      endif
      if apdat.rt_flag && apdat.rt_tags then begin
        if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
        store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags, /append
      endif
    endif
    *apdat.last_ccsds = ccsds 
  endif

end



function ptp_pkt_add_header,buffer,time=time,spc_id=spc_id,path=path,source=source

if ~keyword_set(time) then time=systime(1)
if ~keyword_set(spc_id) then spc_id = 187
if ~keyword_set(path) then path = 'a200'x
if ~keyword_set(source) then source = 'a0'x
size = n_elements(buffer)

st = time_struct(time)
day1958 = uint(st.daynum -714779)
msec =  ulong(st.sod * 1000)
usec = 0U

b_size    = byte( swap_endian(/swap_if_little_endian, uint(size+17)), 0 ,2)
b_sc_id   = byte( swap_endian(/swap_if_little_endian, uint(spc_id)), 0 ,2)
b_day1958 = byte( swap_endian(/swap_if_little_endian, uint(day1958)), 0 ,2)
b_msec    = byte( swap_endian(/swap_if_little_endian, ulong(msec)), 0 ,4)
b_usec    = byte( swap_endian(/swap_if_little_endian, uint(usec)), 0 ,2)
b_source  = byte(source)
b_spare   = byte(0)
b_path    = byte( swap_endian(/swap_if_little_endian, uint(path)), 0 ,2)

hdr = [b_size, 3b, b_sc_id, b_day1958, b_msec, b_usec, b_source, b_spare, b_path]
return, size ne 0 ? [hdr,buffer] : hdr
end



  ;+
  ;spp_ptp_pkt_handler
  ; :Description:
  ;    Processes a single PTP packet
  ;
  ; :Params:
  ;    buffer - Array of bytes
  ;
  ; :Keywords:
  ;    time
  ;    size
  ;
  ; :Author: davin  Jan 1, 2015
  ;
  ; $LastChangedBy: $
  ; $LastChangedDate: $
  ; $LastChangedRevision: $
  ; $URL: $
  ;
  ;-
pro spp_ptp_pkt_handler,buffer,time=time,size=ptp_size
  ptp_size = swap_endian( uint(buffer,0) ,/swap_if_little_endian)   ; first two bytes provide the size
  if ptp_size ne n_elements(buffer) then begin
    dprint,time_string(time,/local_time),'PTP size error- size is ',ptp_size
    hexprint,buffer
    savetomain,buffer,time
    return
  endif
  ptp_code = buffer[2]
  if ptp_code eq 0 then begin
    dprint,'End of Transmission Code'
    printdat,buffer
    return
  endif
  if ptp_code eq 'ff'x then begin
    dprint,'PTP Message ',ptp_size
    dprint,string(buffer[3:*])
    return
  endif
  if ptp_code ne 3 then begin
    dprint,'Unknown PTP code: ',ptp_code
    return
  endif
  ga   = buffer[3:16]
  sc_id = swap_endian(/swap_if_little_endian, uint(ga,0))   
  days  = swap_endian(/swap_if_little_endian, uint(ga,2))
  ms    = swap_endian(/swap_if_little_endian, ulong(ga,4))
  us    = swap_endian(/swap_if_little_endian, uint(ga,8))
  source   =    ga[10]
  spare    =    ga[11]
  path  = swap_endian(/swap_if_little_endian, uint(ga,12))
  utime = (days-4383L) * 86400L + ms/1000d 
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  if keyword_set(time) then dt = utime-time  else dt = 0
;  dprint,dlevel=4,time_string(utime,prec=3),ptp_size,sc_id,days,ms,us,source,path,dt,format='(a,i6," x",Z04,i6,i9,i6," x",Z02," x",Z04,f10.2)'
  if ptp_size le 17 then begin
    dprint,'PTP size error - not enough bytes: '+strtrim(ptp_size,2)+ ' '+time_string(utime)
    return
  endif
  ptp_header ={ ptp_time:utime, ptp_scid: sc_id, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  spp_ccsds_pkt_handler, buffer[17:*],ptp_header = ptp_header
  return
end



