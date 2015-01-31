
function spp_swp_spane_x360_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  
  data = ccsds.data[20:*]
  cnts = swap_endian(ulong(data,0,512) ,/swap_if_little_endian )
  

  tot = total(cnts)    ; Must decompress!
  if 0 then begin
    
    hexprint,data
    savetomain,data
    savetomain,cnts
    

  endif

  str = { $
    time:ptp_header.ptp_time, $
    seq_cntr:ccsds.seq_cntr,  $
    total :tot, $
    ndat  : n_elements(cnts), $
    cnts: float(cnts), $ 
    gap: 0 }

  return, str
end



pro spp_swp_spane_init,save=save

  spp_apid_data,'360'x ,routine='spp_swp_spane_x360_decom',tname='spp_spane_spec_',tfields='*',rt_tags='*', save=save
  spp_apid_data,'36d'x ,routine='spp_generic_decom',tname='spp_spane_dump_',tfields='*',rt_tags='*', save=save

end


