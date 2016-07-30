; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-07-29 07:51:41 -0700 (Fri, 29 Jul 2016) $
; $LastChangedRevision: 21568 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $

function spp_swp_swem_unwrapper,ccsds,ptp_header=ptp_header,apdat=apdat
  
;  str = create_struct(ptp_header,ccsds)
  str = {time:ccsds.time, $
         apid:ccsds.apid, $
         seqn:ccsds.seqn, $
         seq_group:ccsds.seq_group, $
         pkt_size:ccsds.pkt_size, $
         gap:0 }

  ccsds_data = spp_swp_ccsds_data(ccsds)

  if debug(5) then begin
    if ccsds_data[13] ne '00'x then   dprint,dlevel=1,'swem',ccsds.pkt_size, ccsds.apid
    hexprint,ccsds_data,nbytes=32
  endif
  

  if ccsds.seq_group eq 3 && keyword_set(ccsds_data) then begin   ; Loner packets
    spp_ccsds_pkt_handler,ccsds_data[12:*],remainder=remainder,ptp_header=ptp_header
    if keyword_set(remainder) then dprint,'error'
  endif
  
  if ccsds.seq_group eq 5 then begin
    hexprint,ccsds_data,nbytes=32
    printdat,apdat
  endif
  
  return,str
end
