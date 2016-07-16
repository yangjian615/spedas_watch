

pro spp_ccsds_pkt_handler,buffer,ptp_header=ptp_header,recurse_level=recurse_level,ccsds=ccsds,remainder=remainder

  if ~keyword_set(ccsds) then begin
    ccsds=spp_swp_ccsds_decom(buffer)
  endif

  if ~keyword_set(ccsds) then begin
     dprint,dlevel=1,'Invalid CCSDS packet'
     hexprint,buffer
 ;    dprint,dlevel=1,time_string(ptp_header.ptp_time)
     return
  endif


  if 1 then begin
     spp_apid_data,ccsds.apid,apdata=apdat,/increment
     if 1 then begin
       store_data,'APIDS_ALL',ccsds.time,ccsds.apid, /append,dlimit={psym:3,symsize:.2 ,ynozero:1}
     endif


     ;; Look for data gaps
     if keyword_set( *apdat.last_ccsds) then last_ccsds = *apdat.last_ccsds else last_ccsds = 0
     
     if (size(/type,last_ccsds) eq 8)  then begin 
        dseq = (( ccsds.seqn - last_ccsds.seqn ) and '3fff'xu) 
        ccsds.seqn_delta = dseq
        ccsds.time_delta = (ccsds.met - last_ccsds.met)
        ccsds.gap = (dseq ne 1)
     endif 
     if ccsds.gap ne 0  then begin
       dprint,dlevel=3,format='("Lost ",i5," 0x", Z03, " packets")',  ccsds.seqn_delta,apdat.apid
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
        if debug(2) then begin
          dprint,dlevel=1,'Unknown APID: ',ccsds.apid,format='(a,Z04)'
          printdat,ccsds
        endif
     endelse
     *apdat.last_ccsds = ccsds
  endif

end
