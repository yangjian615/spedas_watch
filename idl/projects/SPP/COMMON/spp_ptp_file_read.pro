
pro spp_ptp_file_read,files,dwait=dwait
  
  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)
  spp_swp_startup,rt_flag=0,save=1,/clear
  info = {  time_received:0d, buffer_ptr:ptr_new(/allocate_heap),  file:'',  fileptr:0LL }
  on_ioerror, nextfile


  for i=0,n_elements(files)-1 do begin
    info.file = files[i] 
    tplot_options,title=info.file
    file_open,'r',info.file,unit=lun,dlevel=4,compress=-1
    sizebuf = bytarr(2)
    fi = file_info(info.file)
    dprint,dlevel=1,'Reading file: '+info.file+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
    while ~eof(lun) do begin
      info.time_received = systime(1)
      point_lun,-lun,fp
      if ~keyword_set( *info.buffer_ptr) then begin
        readu,lun,sizebuf
        sz = sizebuf[0]*256 + sizebuf[1]
        if sz gt 17 then  begin   
          remainder = sizebuf  
          sz -= 2
        endif else begin
          remainder = !null
          sz = 100L         
        endelse
      endif else begin
        remainder = !null
        szr =  swap_endian( uint(*info.buffer_ptr,0) ,  /swap_if_little_endian)
        sz = szr - n_elements(*info.buffer_ptr)
        dprint,'Resync:',dlevel=3,sz
      endelse
      buffer = bytarr(sz)
      readu,lun,buffer,transfer_count=nb
      if nb ne sz then begin
        dprint,'File read error. Aborting @ ',fp,' bytes'
        break
      endif
      spp_ptp_stream_read,[remainder,buffer],info=info  
      if debug(2) then begin
        dprint,dwait=dwait,dlevel=2,'File percentage: ' ,(fp*100.)/fi.size
      endif
    endwhile
    dprint,dlevel=2,'Compression: ',float(fp)/fi.size
    free_lun,lun
    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file'
    endif
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  spp_apid_data,/finish
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
  spp_apid_data,/rt_flag    ; re-enable realtime
end


