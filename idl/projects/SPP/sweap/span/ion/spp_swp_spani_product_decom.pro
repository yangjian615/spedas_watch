

function spp_swp_spani_product_decom,ccsds, ptp_header=ptp_header, apdat=apdat
  b = ccsds.data
  psize = 269+7
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',string(ccsds.size,ccsds.apid,format='(5i," - ",5i)')
    return,0
  endif
  
  ;dprint,time_string(ccsds.time)

;  sf0 = ccsds.data[11] and 3

;  cnts = float( reform( spp_sweap_log_decomp( ccsds.data[20:83] , 0 ) ,4,16))
  time = ccsds.time

  spec =  float( spp_sweap_log_decomp( b[20:*], 0) )
;  printdat,spec

 ; return,0

  apid_name = 'tt';string(format='(z02)',b[1])
  prod_str = { $
    name:apid_name, $
    apid: b[1], $
    time: time, $
    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    mode:  b[13] , $
    counts: spec , $
    total:  total(spec), $
    gap: 0 }

;printdat,prod_str
  return,prod_str
end


