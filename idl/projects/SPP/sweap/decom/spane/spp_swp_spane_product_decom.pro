function spp_swp_spane_product_decom,ccsds, ptp_header=ptp_header, apdat=apdat


  ;;-------------------------------------------
  ;; Parse data
  data      = ccsds.data[20:*]
  data_size = n_elements(data)
  apid_name = string(format='(z02)',ccsds.data[1])

  ;;-------------------------------------------
  ;; Use APID to determine packet side
  ;; '60' -> '360'x ...
  pkt_size = [16, 512, 16, 512] 
  apid_loc = ['60','61','62','63']
  ns = pkt_size[where(apid_loc eq apid_name)]


  ;;-------------------------------------------
  ;; Check for compression
  compression = (ccsds.data[12] and '20'x) ne 0
  bps = (compression eq 0) * 4
  nbytes = ns * bps
  if n_elements(data) ne nbytes then begin
     dprint,dlevel=3, 'Size error ',$
            n_elements(data),ccsds.size,ccsds.apid
     return, 0
  endif


  ;;-------------------------------------------
  ;; Decompress if necessary
  if compression then $
     cnts = spp_swp_log_decomp(data[0:ns-1],0) $
  else $
     cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian ) 


  case 1 of

     ;;-----------------------------------------
     ;;Product Full Sweep - 16A - '360'x
     (apid_name eq '60') : begin
        str = { $
              time:ccsds.time, $
              seq_cntr:ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat: n_elements(cnts), $
              cnts: float(cnts)}
     end

     ;;-----------------------------------------
     ;;Product Full Sweep - 32Ex16A - '361'x
     (apid_name eq '61') : begin
        cnts = reform(cnts,16,32)
        str = { $
              time:      ccsds.time, $
              seq_cntr:  ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat:      n_elements(cnts), $
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*])), $
              cnts:      float(cnts)}
     end

     ;;-----------------------------------------
     ;;Product Targeted Sweep - 16A - '362'x
     (apid_name eq '62') : begin
        str = { $
              time:ccsds.time, $
              seq_cntr:ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat: n_elements(cnts), $
              cnts: float(cnts[*])}
     end

     ;;-----------------------------------------
     ;;Product Targeted Sweep - 32Ex16A - '363'x
     (apid_name eq '63') : begin
        str = { $
              time:ccsds.time, $
              seq_cntr:ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat: n_elements(cnts), $
              cnts: float(cnts[*]),$
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*]))}
     end
     else: print, data_size, ' ', apid_name
  endcase


  return, str


end