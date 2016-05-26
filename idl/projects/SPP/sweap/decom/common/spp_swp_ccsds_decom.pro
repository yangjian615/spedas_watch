; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)

function spp_swp_ccsds_decom,buffer          ,subsec=subsec   , error=error

  ;;--------------------------------
  ;; Error Checking
  error = 0b
  buffer_length = n_elements(buffer)
  if buffer_length lt 12 then begin
     dprint,'Invalid buffer length: ',buffer_length,dlevel=1
     hexprint,buffer
     error = 1b
     return, 0
  endif

  header = swap_endian(uint(buffer[0:11],0,6) ,/swap_if_little_endian )
  
  apid = header[0] and '7FF'x 
  subsec= apid ge '350'x
  if keyword_set(subsec) then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000
  endif else begin
    MET = double( header[3]*2UL^16 + header[4] ) 
  endelse
  utime = spp_spc_met_to_unixtime(MET)
  pkt_size = header[2] + 7
  if buffer_length lt pkt_size then begin
    error=2b
    pktbuffer = [buffer,bytarr(pkt_size-buffer_length)]
    if debug(3,msg='Not enough bytes in ccsds buffer') then begin
      dprint,'pkt_size, buffer_length= ',dlevel=2,pkt_size,buffer_length
      hexprint,buffer
    endif
  endif else pktbuffer = buffer[0:pkt_size-1]
  
  ccsds = { $
          version_flag: byte(ishft(header[0],-8) ), $
          apid:         apid , $
          seq_group:    ishft(header[1] ,-14) , $
          seq_cntr:     header[1] and '3FFF'x , $
          size:         header[2]   , $
          pkt_size:     pkt_size,  $
          time:         utime,  $
          MET:          MET,   $
          data:         pktbuffer, $
;          smples_sumd:  2^(buffer[12] and 'F'x),  $   ;  this doesn't belong here....
          dtime :  !values.d_nan, $
          dseq_cntr:   0u , $
          error : error, $
          gap : 1b  } 



  if MET lt -1e5 then begin
     dprint,dlevel=1,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
     ccsds.time = !values.d_nan
  endif
  

  return,ccsds
  
end


