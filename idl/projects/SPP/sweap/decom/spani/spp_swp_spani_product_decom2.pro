; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-02-29 17:07:52 -0800 (Mon, 29 Feb 2016) $
; $LastChangedRevision: 20274 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SPP/sweap/decom/spane/spp_swp_spane_product_decom.pro $


function spp_swp_spani_16A, data, header_str=header_str, apdat=apdat

;printdat,data,header_str,apdat
pname = '16A_'
strct = {time:header_str.time, $
         SPEC:data,  $
         gap: 0}

;if  apdat.save && keyword_set(strct) then begin
;  ;if ccsds.gap eq 1 then append_array, *apdat.dataptr,
;  ;fill_nan(strct), index = *apdat.dataindex
;  append_array, *apdat.dataptr, strct, index = *apdat.dataindex
;endif
if apdat.rt_flag && apdat.rt_tags then begin
  ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
  store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
endif
return,0
end


;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A - 





function spp_swp_spani_32Ex16A, data, header_str=header_str, apdat=apdat
  pname = '32Ex16A_'
  strct = {time:header_str.time, $
    cnts_Anode:data,  $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif

  data = reform(data,32,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif

end




function spp_swp_spani_16Ax32E, data, header_str=header_str, apdat=apdat
message,'bad routine'
  pname = '16Ax32E_'
  strct = {time:header_str.time, $
    cnts_Anode:data,  $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif


end


function spp_swp_spani_8Dx32Ex16A, data, header_str=header_str, apdat=apdat   ; this function needs fixing

  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '8Dx32Ex16A_'
  spec1 = total(reform(data,16,8*32),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,16*8,32),1)
  spec23 = total(reform(data,16,8*32),1)
  
  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif

end



function spp_swp_spani_32Ex16Ax4M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 2048 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '32Ex16Ax4M_'
  data = reform(data,32,16,4,/overwrite)
  spec1 = total(reform(data,32,16*4),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,32*16,4),1)
  spec23 = total(reform(data,32,16*4),1)

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif
end



function spp_swp_spani_8Dx32EX16Ax2M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 8192 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '8Dx32Ex16Ax2M_'
  data = reform(data,8,32,16,2,/overwrite)
  spec1 = total(reform(data,8,32*16*2),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(total(reform(data,8*32,16,2),1) ,2)
  spec23 = total(total(reform(data,8,32*16,2),1), 2)
  
;  printdat,spec1,spec2,spec2,spec23

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif
end



function spp_swp_spani_8Dx32Ex16Ax1M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '8Dx32Ex16Ax1M_'
  data = reform(data,8,32,16,/overwrite)
  spec1 = total(reform(data,8,32*16),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,8*32,16),1)
  spec23 = total(reform(data,8,32*16),1)

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif
end


function spp_swp_spani_16Ax16M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 256 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '16Ax16M_'
  data = reform(data,16,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: 0}

  if apdat.rt_flag && apdat.rt_tags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif
end




function spp_swp_spani_product_decom2, ccsds, ptp_header=ptp_header, apdat=apdat

  ;;-------------------------------------------
  ;; Parse data
  
  pksize = ccsds.size+7
  if pksize le 20 then begin
    dprint,dlevel = 2, 'size error - no data'
    return, 0
  endif
  
  if pksize ne n_elements(ccsds.data) then begin
    dprint,dlevel=1,'Product size mismatch'
    return,0
  endif

  header    = ccsds.data[0:19]
  ns = pksize - 20   
  log_flag    = header[12]
  mode1 = header[13]
  mode2 = (swap_endian(uint(ccsds.data,14,1) ,/swap_if_little_endian ))[0]
  f0 = (swap_endian(ulong(header,16,1), /swap_if_little_endian))[0]
  status_flag = header[18]
  peak_bin = header[19]

  if ptr_valid(apdat.last_ccsds) && keyword_set(*apdat.last_ccsds) then  delta_t = ccsds.time - (*(apdat.last_ccsds)).time else delta_t = !values.f_nan

  compression = (header[12] and 'a0'x) ne 0
  bps =  ([4,1])[ compression ]
  
  ndat = ns / bps

  if ns gt 0 then begin
    data      = ccsds.data[20:*]
    ; data_size = n_elements(data)
    if compression then    cnts = spp_swp_log_decomp(data,0) $
    else    cnts = swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian )
    tcnts = total(cnts)
  endif else begin
    tcnts = -1.
    cnts = 0
  endelse

  str = { $
    time:        ccsds.time, $
    apid:        ccsds.apid, $
    delta_time:  float(delta_t), $
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
    cnts_total:  tcnts,  $
;    data:        ptr_new(), $
    gap:         0  }


if  ns gt 0 then begin

  res = 0
  case ndat  of
    16:   res = spp_swp_spani_16A(data, header_str=str, apdat=apdat)
    256:  res = spp_swp_spani_16Ax16M(data,header_str=str, apdat = apdat)
    512:  res = spp_swp_spani_32Ex16A(data, header_str=str, apdat=apdat)
    2048: res = spp_swp_spani_32Ex16Ax4M(data, header_str=str, apdat=apdat)
    4096: res = spp_swp_spani_8Dx32Ex16A(data, header_str=str, apdat=apdat)
    8192: res = spp_swp_spani_8Dx32EX16Ax2M(data, header_str=str, apdat=apdat)
    else:  dprint,dlevel=3,'Size not recognized: ',ndat
  endcase
  
  
  
endif

  return, str


end
