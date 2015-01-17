

pro spp_ptp_stream_read,buffer,time=time
  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  if debug() then dprint,/phelp,time_string(time),buffer,dlevel=3
  p=0L
  while p lt bsize do begin
    if p gt bsize-3 then dprint,dlevel=0,'PTP stream size error ',p,bsize
    ptp_size = swap_endian( uint(buffer,p) ,/swap_if_little_endian) 
    if p+ptp_size gt bsize then begin
      dprint,'Buffer size error'
      dprint,p,ptp_size,buffer,/phelp
      break
    endif
    spp_ptp_pkt_handler,buffer[p:p+ptp_size-1],time=time
    p += ptp_size
  endwhile
  return
end


