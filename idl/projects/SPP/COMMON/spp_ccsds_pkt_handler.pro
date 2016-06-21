

pro spp_ccsds_pkt_handler,buffer,ptp_header=ptp_header,recurse_level=recurse_level,ccsds=ccsds

  if ~keyword_set(ccsds) then ccsds=spp_swp_ccsds_decom(buffer)

  if ~keyword_set(ccsds) then begin
     dprint,dlevel=1,'Invalid CCSDS packet'
     hexprint,buffer
 ;    dprint,dlevel=1,time_string(ptp_header.ptp_time)
     return
  endif

  ;if n_elements(buffer) ne ccsds.length+7  $
  ;then dprint,'size error',ccsds.apid,n_elements(buffer),ccsds.length+7

;  common spp_ccsds_pkt_handler_com,last_time,total_bytes,rate_sm  ;,LAST_CCSDS
;;  time = ptp_header.ptp_time
;  time = systime(1)
;  if keyword_set(last_time) then begin
;     dt = time - last_time
;     len = n_elements(buffer)
;     total_bytes += len
;     if dt gt .1 then begin
;        rate = total_bytes/dt
;        store_data,'AVG_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
;        total_bytes =0
;        last_time = time
;     endif
;  endif else begin
;     last_time = time
;     total_bytes = 0
;  endelse
;  last_ccsds = ccsds

  if 1 then begin
     spp_apid_data,ccsds.apid,apdata=apdat,/increment
     if 1 then begin
       store_data,'APIDS_ALL',ccsds.time,ccsds.apid, /append,dlimit={psym:3,symsize:.2 ,ynozero:1}
     endif


     ;; Look for data gaps
     if keyword_set( *apdat.last_ccsds) then last_ccsds = *apdat.last_ccsds else last_ccsds = 0
     
     if (size(/type,last_ccsds) eq 8)  then begin 
        dseq = (( ccsds.seq_cntr - last_ccsds.seq_cntr ) and '3fff'xu) 
        ccsds.dseq_cntr = dseq
        ccsds.dtime = (ccsds.met - last_ccsds.met)
        ccsds.gap = (dseq ne 1)
     endif 
     if ccsds.gap ne 0  then begin
       dprint,dlevel=3,format='("Lost ",i5," 0x", Z03, " packets")',  ccsds.dseq_cntr,apdat.apid
       store_data,'APIDS_GAP',ccsds.time,ccsds.apid,  /append,dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}
     endif
     
     if keyword_set(apdat.routine) then begin
        strct = call_function(apdat.routine,ccsds, ptp_header=ptp_header,apdat=apdat)
        if  apdat.save && keyword_set(strct) then begin
        ;if ccsds.gap eq 1 then append_array, *apdat.dataptr,
        ;fill_nan(strct), index = *apdat.dataindex
           append_array, *apdat.dataptr, strct, index = *apdat.dataindex
        endif
        if apdat.rt_flag && apdat.rt_tags then begin
        if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
           store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags , append = 1 ;+ strct[0].gap
        endif
     endif else begin
        if debug(4) then begin
          dprint,dlevel=2,'Unknown APID: ',ccsds.apid,format='(a,Z04)'
          printdat,ccsds
        endif
     endelse
     *apdat.last_ccsds = ccsds
  endif

end
