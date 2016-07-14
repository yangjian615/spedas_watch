; this routine decoms a single ITF

pro spp_itf_decom,itf_buffer,itf_struct=itf_struct

   ;; Handle remainder of buffer from previous call
;  if n_elements( *info.exec_proc_ptr ) ne 0 then begin
;    remainder =  *info.exec_proc_ptr
;    dprint,dlevel=2,'Using remainder buffer from previous call'
;    dprint,dlevel=2,/phelp, remainder
;    undefine , *info.exec_proc_ptr
;    if bsize gt 0 then  spp_itf_stream_read, [remainder,buffer],info=info,/no_sum
;    return
;  endif

  p = 0L
  bsize = n_elements(itf_buffer) - p
  
  if bsize ne 8198 then begin
    dprint,'improper size: ',bsize
    return
  endif

  sync = swap_endian( ulong(itf_buffer,p) , /swap_if_little_endian)
  if sync ne 'FEFA30C8'x then begin
    dprint,dlevel=1,'bad sync at p=',p
    printdat,sync,/hex
    hexprint,itf_buffer[0:63]
    return
  endif


  itf_length =  swap_endian( uint(itf_buffer,p+6) , /swap_if_little_endian)
  itf_vc  = itf_buffer[p+4]
  itf_seq = itf_buffer[p+5]
  itf_offset = swap_endian( uint(itf_buffer,p+8) , /swap_if_little_endian)

  if size(/type, itf_struct) ne 8 then begin
    dprint,size(/type,itf)
    last_seq = 0
    pointer = ptr_new(!null) 
    dprint,'Created new itf_struct'
  endif else begin
    last_seq = itf_struct.seq
    pointer =  itf_struct.pointer
  endelse
  

  if size(/type,itf_struct) eq 8 then last_seq = itf_struct.seq else last_seq = 0
  dseq = byte(itf_seq - last_seq)
  
  gap = dseq ne 1b
  
  
  data_size = itf_length-4
  check_sum = swap_endian( uint(itf_buffer,p+itf_length+6) , /swap_if_little_endian)
  itf_struct = { $
     sync:sync, $
     itf_length : itf_length, $
     bsize: bsize, $
     data_size : data_size, $
     vc:itf_vc, $
     seq:itf_seq, $
     offset: itf_offset, $
     pointer: pointer,  $
     check_sum: check_sum, $
     dseq: dseq, $
     gap: gap}
  
  if itf_struct.offset ge 8183 then dprint,dlevel=1,'No packet header in ITF: ',itf_struct.offset

  
  if itf_struct.offset ne 0 then begin
    dprint,dlevel=3,'Warning: Offset: ',itf_struct.offset
  endif
  

  if debug(3) then begin
    dprint,dlevel=3,phelp=0,'New frame ',bsize,p,itf_vc,itf_seq,itf_length,itf_offset,check_sum, (dseq eq 1) ? "  " : ( ' skipped'+string(dseq+0l) )  
 ;   hexprint,itf_buffer[p:p+64-1]
  endif


  if dseq ne 1 then begin
    if debug(1) then dprint,dlevel=1,'Skipped ',dseq,' ITFs'
  endif

  if 0 then begin
    
    q=0
    
  endif else begin
    remainder = !null   
    q = itf_struct.offset      
  endelse
  dbuffer = [remainder,itf_buffer[p+10: p+10+data_size-1]]
  ds = n_elements(dbuffer)
  npackets = 0



;  return
  if n_elements(dbuffer) ne ds then dprint,'error', n_elements(dbuffer),data_size


  while q lt ds do begin
    ;; Buffer doesn't have complete pkt.
    if q gt ds then begin
      dprint,dlevel=1,'Buffer has incomplete packet. SHOULD Save ', n_elements(dbuffer)-p,' bytes for next call.'
      ;dprint,dlevel=1,p,ptp_size,buffer,/phelp
      ;        *info.exec_proc_ptr = buffer[q:*]    ;  NOTE: THIS ALGORITHM MUST BE CORRECTED TO WORK PROPERLY
      ;; Store remainder of buffer to be used on the next call to this procedure
      return
      break
    endif
    ccsds = spp_swp_ccsds_decom(dbuffer[q:*],error=error)
    if ~keyword_set(ccsds) then begin
      dprint,dlevel=2,'Buffer does not have enough bytes ',error
      hexprint,dbuffer[q:*]
      break
    endif
    npackets +=1
    if debug(3) then begin
      dprint,dlevel=2,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i0)',npackets,q,ccsds.apid,ccsds.seq_group,ccsds.seq_cntr,ccsds.pkt_size
      ;      hexprint,ccsds.data
    endif    
    q += ccsds.pkt_size
    if 1 then begin
      ptp_header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
      spp_ccsds_pkt_handler,ptp_header = ptp_header,ccsds = ccsds      
    endif

  endwhile
  if q ne ds then begin
    dprint,dlevel=4,'ITF remainder:',q-ds, q,ds
  endif
end




;
;
;
;pro spp_itf_stream_read_old,buffer,info=info,no_sum=no_sum  
;  
;  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
;  time = info.time_received
;  dprint,dlevel=4,'Enter routine, bsize:',bsize
;;  printdat,info
; 
; 
; common spp_itf_stream_read_com2,last_time,total_bytes,rate_sm,last_seq
; if ~keyword_set(no_sum) then begin
;   if keyword_set(last_time) then begin
;     dt = time - last_time
;     len = n_elements(buffer)
;     total_bytes += len
;     if dt gt .1 then begin
;       rate = total_bytes*1.d;/dt
;       store_data,'ITF_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
;       total_bytes =0
;       last_time = time
;     endif
;   endif else begin
;     last_time = time
;     total_bytes = 0
;     last_seq=0b
;   endelse
; endif
;  
;  ;; Handle remainder of buffer from previous call
;  if n_elements( *info.exec_proc_ptr ) ne 0 then begin
;     remainder =  *info.exec_proc_ptr
;     dprint,dlevel=2,'Using remainder buffer from previous call'
;     dprint,dlevel=2,/phelp, remainder
;     undefine , *info.exec_proc_ptr
;     if bsize gt 0 then  spp_itf_stream_read, [remainder,buffer],info=info,/no_sum
;     return
;  endif
;
;  p=0L
;;  dprint,bsize,dlevel=2
;  while p lt bsize do begin
;    
;    sync = swap_endian( ulong(buffer,p) , /swap_if_little_endian)
;    if debug(3) then  hexprint,buffer[p:p+63]
;    if sync ne 'FEFA30C8'x then begin
;      dprint,dlevel=1,'bad sync at p=',p
;      printdat,sync,/hex
;;      hexprint,buffer[0:63]
;      return
;    endif
;    if p gt bsize-10 then begin
;      dprint,dlevel=1,'Warning ITF stream size can not be read ',p,bsize
;      itf_size = 10
;      ;; (minimum value possible)
;      ;; Dummy value that will trigger end of buffer
;    endif else  itf_size = swap_endian( uint(buffer,p+6) , /swap_if_little_endian)
;    if p+itf_size+10 gt bsize then begin
;      dprint,dlevel=1,'Warning ITF packet size is too small!'
;      dprint,dlevel=1,p,itf_size,buffer,/phelp
;      break
;    endif
;    itf_vc  = buffer[p+4]
;    itf_seq = buffer[p+5]
;    itf_offset = swap_endian( uint(buffer,p+8) , /swap_if_little_endian)
;    dseq = byte(itf_seq - last_seq)
;    last_seq = itf_seq
;    if itf_offset ne 0 then begin
;      dprint,dlevel=3,'Warning: Offset: ',itf_offset
;    endif
;    
;    if debug(2) then begin
;      dprint,dlevel=3,phelp=0,'new frame ',bsize,p,itf_size,itf_vc,itf_seq,itf_offset, (dseq eq 1) ? "  " : ( ' skipped'+string(dseq+0l) )
; ;     hexprint,buffer[p:p+10-1]
;    endif
;        
;    q = p+10
;    npackets = 0
;    while q lt p+itf_size-4 do begin
;      ;; Buffer doesn't have complete pkt.
;      if q gt bsize then begin
;        dprint,dlevel=1,'Buffer has incomplete packet. SHOULD Save ', n_elements(buffer)-p,' bytes for next call.'
;        ;dprint,dlevel=1,p,ptp_size,buffer,/phelp
;;        *info.exec_proc_ptr = buffer[q:*]    ;  NOTE: THIS ALGORITHM MUST BE CORRECTED TO WORK PROPERLY
;        ;; Store remainder of buffer to be used on the next call to this procedure
;        return
;        break
;      endif
;      ccsds = spp_swp_ccsds_decom(buffer[q:*])
;      if ~keyword_set(ccsds) then begin
;        dprint,dlevel=1,'Bad CCSDS packet'
;        break
;      endif else begin
;        q += ccsds.pkt_size
;      endelse
;      npackets +=1
;      if debug(3) then begin
;        dprint,dlevel=2,'CCSDS Size:',ccsds.pkt_size,ccsds.apid,q
;  ;      hexprint,ccsds.data        
;      endif
;      ptp_header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
;      spp_ccsds_pkt_handler,ptp_header = ptp_header,ccsds = ccsds
;
;    endwhile
;;    p += itf_size
;    if q ne p+10+itf_size-4 then begin
;       dprint,dlevel=3,'ITF error', p,itf_size,q
;    endif
;    p += 8198
;    
;  endwhile
;  if p ne bsize then dprint,dlevel=2,'Buffer incomplete',p,itf_size,bsize
;  
;  return
;end
;
;
;



pro spp_itf_stream_read,buffer,info=info

  common spp_itf_stream_read_com,last_time,total_bytes,rate_sm,last_seq

  bsize = n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  if bsize eq 0 then begin
    dprint,dlevel=2,'Empty buffer'
    return
  endif
  
;  *info.buffer_ptr = !null

  ;printdat,info
  if keyword_set(*info.buffer_ptr) then begin
    dprint,dlevel=2,'Using previously store bytes'
    concat_buffer = [*info.buffer_ptr,buffer]
    *info.buffer_ptr = !null
    spp_itf_stream_read,concat_buffer,info=info
    return
  endif

  time = info.time_received
  nitf = bsize / 8198
  remainder = bsize mod 8198

  dsize = 0L
  for i = 0l,nitf -1 do begin
    spp_itf_decom,buffer[i*8198:i*8198+8197],itf_struct= *info.exec_proc_ptr
    dsize += (*info.exec_proc_ptr).data_size
    ;   printdat,info.exec_proc_ptr
  endfor
  dprint,dlevel=3,dsize

  if keyword_set(last_time) then begin
    dt = time - last_time
    total_bytes += dsize
    if dt gt .1 then begin
      rate = total_bytes*1.d/dt
      store_data,'ITF_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
      total_bytes =0
      last_time = time
    endif
  endif else begin
    last_time = time
    total_bytes = 0
  endelse


;  dprint,dlevel=2,bsize,nitf,remainder
  if remainder ne 0 then begin
    dprint,dlevel=2,'incomplete ITF ',remainder
    *info.buffer_ptr = buffer[i*8198:*]
    printdat,*info.buffer_ptr
  endif



end


