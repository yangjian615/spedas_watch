; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-02-29 17:07:52 -0800 (Mon, 29 Feb 2016) $
; $LastChangedRevision: 20274 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SPP/sweap/decom/spane/spp_swp_spane_product_decom.pro $


function spp_swp_spane_16A, ccsds, header_str=header_str, apdat=apdat
str = { $
  time:        ccsds.time, $
  seq_cntr:    ccsds.seq_cntr,  $
  seq_group:   ccsds.seq_group,  $
  ndat:        n_elements(cnts), $
  peak_bin:    peak_bin, $
  log_flag:    log_flag, $
  status_flag: status_flag,$
  f_counter:   f_counter,$
  cnts:        float(cnts[remap])}
return,str
end


;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A - '361'x

function spp_swp_spane_16Ax32E, ccsds, header_str=header_str, apdat=apdat
  str = { $
    time:      ccsds.time, $
    seq_cntr:  ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    ndat:      n_elements(cnts), $
    peak_bin:  peak_bin, $
    log_flag:  log_flag, $
    status_flag: status_flag,$
    f_counter: f_counter,$
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
    cnts:      float(reform(cnts,16*32))}
end


function spp_swp_spane_16Ax8Dx32E, ccsds, header_str=header_str, apdat=apdat   ; this function needs fixing
  str = { $
    time:      ccsds.time, $
    seq_cntr:  ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    ndat:      n_elements(cnts), $
    peak_bin:  peak_bin, $
    log_flag:  log_flag, $
    status_flag: status_flag,$
    f_counter: f_counter,$
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
    cnts:      float(reform(cnts,16*32))}
end





function spp_swp_spane_product_decom2, ccsds, ptp_header=ptp_header, apdat=apdat

  ;;-------------------------------------------
  ;; Parse data
  
  pksize = ccsds.size+7
  if pksize le 20 then begin
    dprint,dlevel = 2, 'size error - no data'
    return, 0
  endif

  header    = ccsds.data[0:19]
  ns = pksize - 20   
  log_flag    = header[12]
  mode1 = header[13]
  mode2 = swap_endian(uint(ccsds.data,14,1) ,/swap_if_little_endian )
  f0 = swap_endian(ulong(header,16,1), /swap_if_little_endian)
  status_flag = header[18]
  peak_bin = header[19]

  if ptr_valid(apdat.last_ccsds) && keyword_set(*apdat.last_ccsds) then  delta_t = ccsds.time - (*(apdat.last_ccsds)).time else delta_t = !values.f_nan

  compression = (header[12] and 'a0'x) ne 0
  bps =  ([4,1])[ compression ]
  
  ndat = ns / bps



  str = { $
    time:        ccsds.time, $
    delta_time: float(delta_t), $
    seq_cntr:    ccsds.seq_cntr,  $
    seq_group:   ccsds.seq_group,  $
    ndat:        ndat, $
    datasize:    ns, $
    log_flag:    log_flag, $
    mode1:        mode1,  $
    mode2:        mode2,  $
    f0:           f0,$
    status_flag: status_flag,$
    peak_bin:    peak_bin, $
;    data:        ptr_new(), $
    gap:         0  }


if  ns gt 0 then begin
  data      = ccsds.data[20:*]
 ; data_size = n_elements(data)


  if compression then $
    cnts = spp_swp_log_decomp(data,0) $
  else $
    cnts = swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian )

  res = 0
  case ndat+1  of
    16:   res = spp_swp_spane_16A(data, header_str=str, apdat=apdat)
    512:  res = spp_swp_spane_16Ax32E(data, header_str=str, apdat=apdat)
;    4096: res = spp_swp_spane_16Ax8Dx32E(data, header_str=str, apdat=apdat)
    else:  dprint,dlevel=3,'Size not recognized: ',ndat
  endcase
  
  
  
endif

  return, str


end
