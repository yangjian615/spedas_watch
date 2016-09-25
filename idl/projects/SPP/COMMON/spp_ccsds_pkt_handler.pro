

pro spp_ccsds_pkt_handler,dbuffer,offset,buffer_length,ptp_header=ptp_header,remainder=remainder   ;,recurse_level=recurse_level,ccsds=ccsds

  if not keyword_set(buffer_length) then buffer_length = n_elements(dbuffer)
  if not keyword_set(offset) then offset = 0
  npackets = 0
  remainder = !null
  
  while offset lt buffer_length do begin
    ccsds = spp_swp_ccsds_decom(dbuffer,offset,buffer_length,remainder=remainder,dlevel=3)
;    dprint,/phelp,dbuffer
    if ~keyword_set(ccsds) then begin
      if debug(2) then begin
        dprint,dlevel=3,'Incomplete CCSDS, saving ',n_elements(remainder),' bytes for later '    ;,pkt_size,pkt_size - n_elements(b)
      endif
      break
    endif
    npackets +=1
    if debug(5) then begin
      ccsds_data = spp_swp_ccsds_data(ccsds)  
      dprint,dlevel=2,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ",8(" ",Z02))',npackets,offset,ccsds.apid,ccsds.seq_group,ccsds.seqn,ccsds.pkt_size,ccsds_data[12:17]
    endif
    offset += ccsds.pkt_size
    
    
    if 1 then begin    ;  process the packet
      if keyword_set(ptp_header) then header=ptp_header else begin
        header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
      endelse
      ;      spp_ccsds_pkt_handler,ptp_header = ptp_header,ccsds = ccsds

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
      
;      if ptr_valid(apdat.ccsds_all) then begin
;        append_array,*apdat.ccsds_all,ccsds,index= *apdat.ccsds_index
;      endif
      if isa(apdat.ccsds_array,'dynamicarray') then apdat.ccsds_array.append,ccsds

      if keyword_set(apdat.routine) then begin
        strct =  call_function(apdat.routine,ccsds, ptp_header=header,apdat=apdat)
        if  apdat.save && keyword_set(strct) then begin
          if isa(apdat.data_array,'dynamicarray') then apdat.data_array.append, strct
        endif
        if apdat.rt_flag && apdat.rt_tags then begin
          if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
          store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags , append = 1 
        endif
      endif else begin
        if debug(3) then begin
          dprint,dlevel=2,'Unknown APID: ',ccsds.apid,format='(a,Z04)'
          if debug(3) then printdat,ccsds
        endif
      endelse
      *apdat.last_ccsds = ccsds
    endif

  endwhile

end
