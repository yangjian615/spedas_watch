

;pro ksem_ccsds_pkt_handler,buffer,ptp_header=ptp_header
;
;
;  if debug(3) then begin
;    dprint,dlevel=3,time_string(ptp_header.ptp_time)
;    hexprint,buffer[0:31]
;  endif
;
;  ccsds=ksem_ccsds_decom(buffer)
;
;  if ~keyword_set(ccsds) then begin
;    dprint,dlevel=2,'Invalid CCSDS packet'
;    dprint,dlevel=2,time_string(ptp_header.ptp_time)
;    ;    hexprint,buffer
;    return
;  endif
;
;  if debug(4) then begin
;    dprint,dlevel=3,time_string(ccsds.time)
;    hexprint,ccsds.data[0:31]
;  endif
;
;  if 1 then begin
;    ksem_apid_data,ccsds.apid,apdata=apdat,/increment
;    if (size(/type,*apdat.last_ccsds) eq 8)  then begin    ; look for data gaps
;      dseq = (( ccsds.seq_cntr - (*apdat.last_ccsds).seq_cntr ) and '3fff'x) -1
;      if dseq ne 0  then begin
;        ccsds.gap = 1
;        dprint,dlevel=3,format='("Lost ",i5," ", Z03, " packets")',dseq,apdat.apid
;      endif
;    endif
;    if keyword_set(apdat.routine) then begin
;      strct = call_function(apdat.routine,ccsds,ptp_header=ptp_header,apdat=apdat)
;      if  apdat.save && keyword_set(strct) then begin
;        ;        if ccsds.gap eq 1 then append_array, *apdat.dataptr, fill_nan(strct), index = *apdat.dataindex
;        append_array, *apdat.dataptr, strct, index = *apdat.dataindex
;      endif
;      if apdat.rt_flag && apdat.rt_tags then begin
;        ;        if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
;        store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags, /append
;      endif
;    endif
;    *apdat.last_ccsds = ccsds
;  endif
;
;end




pro ksem_msg_pkt_handler,buffer,time=time
  source = 0b
  spare = 0b
  ptp_scid = 0u
  path =  0u
  ptp_size = 0u
  utime = time
  ptp_header ={ ptp_time:utime, ptp_scid: 0u, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  ksem_ccsds_pkt_handler,buffer,ptp_header = ptp_header
  return
end


function ksem_swemulator_time_status,buffer   ;  decoms 12 Word time and status message from SWEMulator
  v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)
  f0 = v[0]
  time = V[1] * 2d^16 + V[2]  + V[3]/(2d^16)

  ts = { f0: f0,  MET:time, revnum:buffer[8],  power_flag: buffer[9], fifo_cntr:buffer[10], fifo_flag: buffer[11], $
    sync: v[6], counts:v[7]  , parity_frame: v[8],  command:v[9],  telem_fifo:v[10],  inst_power_flag:v[11]  }
  return,ts
end







pro ksem_recorders
  common ksem_crib_com, recorder_base1, recorder_base2,exec_base
  exec,exec_base,exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*300'

  ;host = 'ABIAD-SW'
  ;host = 'localhost'
  host = '128.32.98.101'  ;  room 160 Silver
  ;host = '128.32.13.37'   ;  room 133 addition
  ;  recorder,recorder_base1,title='GSEOS PTP room 320',port=2024,host='ABIAD-SW',exec_proc='spp_ptp_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
  ;  recorder,recorder_base2,title='GSEOS PTP 133 addition',port=2024,host='128.32.13.37',exec_proc='spp_ptp_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
  recorder,recorder_base2,title='KSEM room 160',port=4040,host='128.32.98.101' ,exec_proc='ksem_msg_stream_read',destination='ksem_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
  printdat,recorder_base,filename,exec_base,/value
end


pro ksem_tplot
tplot,'ksem_hkp_MON ksem_hkp_ERR1 ksem_hkp_ERR2 ksem_hkp_RATES ksem_hkp_MADDR ksem_hkp_FTUO_FLAGS ksem_science_DATA ksem_noise_DDATA'

end




pro ksem_msg_stream_read,buffer, info=info  ;,time=time   ;,   fileunit=fileunit   ,ptr=ptr
common ksem_msg_stream_read_com2, time_status,utc,c,dd

  bsize= n_elements(buffer)
  time = info.time_received
;  dprint,time_string(time)
  
if n_elements( *info.exec_proc_ptr ) ne 0 then begin   ; Handle remainder of buffer from previous call
  remainder =  *info.exec_proc_ptr
  dprint,dlevel=2,'Using remainder buffer from previous call'
  dprint,dlevel=2,/phelp, remainder
  undefine , *info.exec_proc_ptr
  if bsize gt 0 then  ksem_msg_stream_read, [remainder,buffer],info=info
  return
endif
  
  
  if 0 && debug(3) then dprint,/phelp,time_string(time),buffer,dlevel=3
  ptr=0L
  while ptr lt bsize do begin
    if ptr gt bsize-6 then begin
      dprint,dlevel=0,'SWEMulator MSG stream size error ',ptr,bsize
      return
    endif
    msg_header = swap_endian( uint(buffer,ptr,3) ,/swap_if_little_endian)
    sync  = msg_header[0]
    code  = msg_header[1]
    psize = msg_header[2]*2
    if 0 then begin
      dprint,ptr,psize,bsize
      hexprint,msg_header
      ;    hexprint,buffer,nbytes=32
    endif

    if sync ne 'a829'x then begin
      ;     printdat,ptr,sync,code,psize
      ;      dprint,ptr,sync,code,psize,dlevel=0,    ' Sync not recognized'
      dprint,format='(i,z,z,i,a)',ptr,sync,code,psize,dlevel=0,    ' Sync not recognized'
      ;      hexprint,buffer
      return
    endif

    if psize lt 12 then begin
      dprint,format="('Bad MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,'???',0
      break
    endif
    
    if ptr+6+psize gt bsize then begin   ; Buffer doesn't have complete pkt.
      dprint,dlevel=2,'Buffer has incomplete packet. Saving ',n_elements(buffer)-ptr,' bytes for next call.'
      *info.exec_proc_ptr = buffer[ptr:*]                   ; store remainder of buffer to be used on the next call to this procedure
      return
      break
    endif
    

    if 0 && debug(3) then begin
      dprint,format='(i,i,z,z,i)',ptr,bsize,sync,code,psize,dlevel=2
      hexprint,buffer[ptr+6:ptr+6+psize-1] ;,nbytes=32
    endif

    if keyword_set(utc) then  time = utc

    case code of
      'c1'x :begin
         time_status = ksem_swemulator_time_status(buffer[ptr+6:ptr+6+psize-1])
         if keyword_set(time_status) then  utc = ksem_spc_met_to_unixtime(time_status.MET)
;         if debug(2) then hexprint,buffer[ptr+6:ptr+6+psize-1]
          if debug(4) then begin
            dprint,time_string(time),' ',time_string(utc), '  ', time-utc
            dprint,phelp=2,time_status,dlevel=3
          endif
         end
      'c2'x : dprint,dlevel=2,"Can't deal with C2 messages now'
      'c3'x :begin
        ksem_msg_pkt_handler,buffer[ptr+6:ptr+6+psize-1],time=time
      end
      else:  dprint,dlevel=1,'Unknown code'
    endcase
    ptr += ( psize+6)
  endwhile
  if ptr ne bsize then dprint,'MSG buffer size error?'
  return
end




