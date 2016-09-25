; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)


;
;function spp_swp_ccsds_data,ccsds
;  if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
;return,data
;end





function spp_swp_ccsds_decom,buffer,offset,buffer_length,remainder=remainder , error=error,verbose=verbose,dlevel=dlevel


if 0 then begin
message,'old version',/cont
  error = 0b
  if not keyword_set(offset) then offset = 0
  if not keyword_set(buffer_length) then buffer_length = n_elements(buffer)
  ;;--------------------------------
  ;; Error Checking
  if buffer_length-offset lt 12 then begin
     if debug(dlevel,verbose) then begin
       dprint,'Invalid buffer length: ',buffer_length,dlevel=1,verbose=verbose
       hexprint,buffer      
     endif
     error = 1b
     return, 0
  endif

  header = swap_endian(uint(buffer[0:11],0,6) ,/swap_if_little_endian )
  
  apid = header[0] and '7FF'x 
  if n_elements(subsec) eq 0 then subsec= apid ge '350'x

  if apid ge '360'x then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000
  endif else if apid ge '350'x then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'ffff'x)  / 2d^16) 
  endif else begin
    MET = double( header[3]*2UL^16 + header[4] ) 
  endelse
  
;  dprint,apid,met,format='(z,"x ",f12.2)'

  
  utime = spp_spc_met_to_unixtime(MET)
  pkt_size = ulong(header[2] + 7)
  if buffer_length lt pkt_size then begin
    error=2b
    pktbuffer = [buffer,bytarr(pkt_size-buffer_length)]
    if debug(1) then begin
      dprint,'Not enough bytes: pkt_size, buffer_length= ',dlevel=0,pkt_size,buffer_length
 ;     hexprint,buffer
    endif
  endif else pktbuffer = buffer[0:pkt_size-1]
  
  ccsds = { $
          apid:         apid , $
          version_flag: byte(ishft(header[0],-8) ), $
          seq_group:    byte(ishft(header[1] ,-14) ) , $
;          seq_cntr:     header[1] and '3FFF'x , $
          seqn:         header[1] and '3FFF'x , $
;          size:         header[2]   , $
          pkt_size:     pkt_size,  $
          time:         utime,  $
          MET:          MET,   $
          data:         pktbuffer, $
;          dtime :      !values.d_nan, $
          time_delta : !values.d_nan, $
;          dseq_cntr:   0u , $
          seqn_delta : 0u, $
          error : error, $
          gap : 1b  } 

  if MET lt -1e5 then begin
     dprint,dlevel=1,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
     ccsds.time = !values.d_nan
  endif
  return,ccsds

endif else begin
  

  ;;--------------------------------
  ;; Error Checking
  error = 0b
  error = 0b
  if not keyword_set(offset) then offset = 0
  if not keyword_set(buffer_length) then buffer_length = n_elements(buffer)
;  buffer_length = n_elements(buffer)-offset
  remainder = !null


  d_nan = !values.d_nan

  ccsds = { ccsds_format, $
    apid:         0u , $
    version_flag: 0b , $
    seq_group:    0b , $
    ;    seq_cntr:     0u , $
    seqn:         0u , $
    ;    size:         0u , $
    pkt_size:     0ul,  $
    time:         d_nan,  $
    MET:          d_nan,  $
    ;    data:         pktbuffer, $
    pdata:        ptr_new(),  $
    ;    dtime :       d_nan, $
    time_delta :  d_nan, $
    ;    dseq_cntr:   0u , $
    seqn_delta :  0u, $
    error :       0b, $
    gap :         1b  }




  if buffer_length-offset lt 12 then begin
    if debug(dlevel,verbose) then begin
      dprint,'CCSDS Buffer length too short to include header: ',buffer_length,dlevel=dlevel
      hexprint,buffer
    endif
    error = 1b
    return, 0
  endif

  header = swap_endian(uint(buffer[offset+0:offset+11],0,6) ,/swap_if_little_endian )


  ccsds.version_flag = byte(ishft(header[0],-8) )    ; THIS DOES NOT LOOK CORRECT

  ccsds.apid = header[0] and '7FF'x

  if n_elements(subsec) eq 0 then subsec= ccsds.apid ge '350'x

  apid = ccsds.apid
  if apid ge '360'x then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000              ; SPANS
  endif else if apid ge '350'x then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'ffff'x)  / 2d^16)             ; SPC
  endif else begin
    MET = double( header[3]*2UL^16 + header[4] )
  endelse

  ccsds.met = met
  ; dprint,ccsds.apid,ccsds.met,format='(z,"x ",f12.2)'

  ccsds.time = spp_spc_met_to_unixtime(ccsds.MET)
  ccsds.pkt_size = header[2] + 7

  if buffer_length-offset lt ccsds.pkt_size then begin
    error=2b
    remainder = buffer[offset:*]
    if debug(dlevel,verbose) then begin
      dprint,'Not enough bytes: pkt_size, buffer_length= ',ccsds.pkt_size,buffer_length-offset,dlevel=dlevel,verbose=verbose
      ;     hexprint,buffer
;      pktbuffer = 0
    endif
    return ,0
  endif else begin
    if ccsds.pkt_size lt 10 then begin
      dprint,'Invalid Packet size:' , ccsds.pkt_size
      return,0
    endif
    if ccsds.pkt_size ne buffer_length-offset then begin
      dprint,'PTP size and CCSDS size mismatch',dlevel=1
    endif
    pktbuffer = buffer[offset+0:offset+ccsds.pkt_size-1]
    ccsds.pdata = ptr_new(pktbuffer,/no_copy)
  endelse

  ;  printdat,ccsds.pdata

  ccsds.seq_group =  ishft(header[1] ,-14)
  ; ccsds.seq_cntr =     header[1] and '3FFF'x
  ccsds.seqn  =    header[1] and '3FFF'x
  ;  ccsds.size  =        header[2]

  if ccsds.MET lt -1e5 then begin
    dprint,dlevel=dlevel,verbose=verbose,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = d_nan
  endif
  
  return,ccsds
  
endelse
  
  
  
  
end


