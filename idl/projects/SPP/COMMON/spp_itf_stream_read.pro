





pro spp_itf_stream_read,buffer,info=info,no_sum=no_sum  
  
  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  time = info.time_received
  dprint,dlevel=4,'Enter routine, bsize:',bsize
 ; printdat,info
 
 
 common spp_itf_stream_read_com,last_time,total_bytes,rate_sm
 if ~keyword_set(no_sum) then begin
   if keyword_set(last_time) then begin
     dt = time - last_time
     len = n_elements(buffer)
     total_bytes += len
     if dt gt .1 then begin
       rate = total_bytes/dt
       store_data,'ITF_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
       total_bytes =0
       last_time = time
     endif
   endif else begin
     last_time = time
     total_bytes = 0
   endelse
 endif
 
  
  ;; Handle remainder of buffer from previous call
  if n_elements( *info.exec_proc_ptr ) ne 0 then begin
     remainder =  *info.exec_proc_ptr
     dprint,dlevel=2,'Using remainder buffer from previous call'
     dprint,dlevel=2,/phelp, remainder
     undefine , *info.exec_proc_ptr
     if bsize gt 0 then  spp_itf_stream_read, [remainder,buffer],info=info,/no_sum
     return
  endif

  p=0L
  while p lt bsize do begin
    sync = swap_endian( ulong(buffer,p) , /swap_if_little_endian)
;    hexprint,buffer[0:31]
    if sync ne 'FEFA30C8'x then begin
      dprint,dlevel=1,'bad sync at p=',p
      printdat,sync,/hex
      hexprint,buffer[0:63]
      return
    endif
    if p gt bsize-10 then begin
      dprint,dlevel=1,'Warning ITF stream size can not be read ',p,bsize
      itf_size = 10
      ;; (minimum value possible)
      ;; Dummy value that will trigger end of buffer
    endif else  itf_size = swap_endian( uint(buffer,p+6) , /swap_if_little_endian)
    if p+itf_size+10 gt bsize then begin
      dprint,dlevel=1,'Warning ITF packet size is too small!'
      dprint,dlevel=1,p,itf_size,buffer,/phelp
      break
    endif
    itf_vc  = buffer[p+4]
    itf_seq = buffer[p+5]
    itf_offset = swap_endian( uint(buffer,p+8) , /swap_if_little_endian)
    if itf_offset ne 0 then begin
      dprint,dlevel=1,'Warning: Offset: ',itf_offset
    endif
    
    if debug(3) then begin
      dprint,dlevel=2,phelp=0,bsize,p,itf_size,itf_vc,itf_seq,itf_offset
 ;     hexprint,buffer[p:p+10-1]
    endif
        
    q = p+10
    while q lt p+itf_size-4 do begin
      ;; Buffer doesn't have complete pkt.
      if q gt bsize then begin
        dprint,dlevel=1,'Buffer has incomplete packet. SHOULD Save ', n_elements(buffer)-p,' bytes for next call.'
        ;dprint,dlevel=1,p,ptp_size,buffer,/phelp
;        *info.exec_proc_ptr = buffer[q:*]    ;  NOTE: THIS ALGORITHM MUST BE CORRECTED TO WORK PROPERLY
        ;; Store remainder of buffer to be used on the next call to this procedure
        return
        break
      endif
      ccsds = spp_swp_ccsds_decom(buffer[q:*])
      if ~keyword_set(ccsds) then begin
        dprint,dlevel=1,'Bad CCSDS packet'
        break
      endif else begin
        q += ccsds.pkt_size
      endelse
      if debug(3) then begin
        dprint,'CCSDS Size:',ccsds.pkt_size,ccsds.apid,q
;        hexprint,ccsds.data        
      endif
      ptp_header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
      spp_ccsds_pkt_handler,ptp_header = ptp_header,ccsds = ccsds

    endwhile
;    p += itf_size
    if q ne p+10+itf_size-4 then dprint,dlevel=2,'ITF error', p,itf_size,q
    p += 8198
    
  endwhile
  if p ne bsize then dprint,dlevel=2,'Buffer incomplete',p,itf_size,bsize
  
  return
end
