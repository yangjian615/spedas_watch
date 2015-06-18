

pro spp_msg_pkt_handler,buffer,time=time   
source = 0b
spare = 0b
ptp_scid = 0u
path =  0u
ptp_size = 0u
utime = time
  ptp_header ={ ptp_time:utime, ptp_scid: 0u, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  spp_ccsds_pkt_handler,buffer,ptp_header = ptp_header
  return
end





pro spp_msg_stream_read,buffer,time=time   ;,   fileunit=fileunit   ,ptr=ptr
  bsize= n_elements(buffer)
  if debug() then dprint,/phelp,time_string(time),buffer,dlevel=3
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
    if ptr+6+psize gt bsize then begin
      dprint,'Incomplete Buffer size error'
      dprint,ptr,psize,buffer,/phelp
      break
    endif

    if 0 then begin
      dprint,format='(i,i,z,z,i)',ptr,bsize,sync,code,psize,dlevel=2
      hexprint,buffer[ptr+6:ptr+6+psize-1] ;,nbytes=32
    endif
    
    
    
    case code of
      'c1'x : time_status = spp_swemulator_time_status(buffer[6:*])
      'c2'x : dprint,dlevel=2,"Can't deal with C2 messages now'
      'c3'x :begin
        spp_msg_pkt_handler,buffer[ptr+6:ptr+6+psize-1],time=time
        end
      else:  dprint,dlevel=1,'Unknown code'
    endcase
    
    ptr += ( psize+6)
  endwhile
  if ptr ne bsize then dprint,'MSG buffer size error?'
  return
end


