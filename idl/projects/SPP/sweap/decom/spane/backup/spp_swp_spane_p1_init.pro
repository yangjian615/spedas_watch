;;; SPANE PRODUCT 1

function spp_swp_spane_p1_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  data = ccsds.data[20:*]
  ;;lll = 512
  lll = 512*4
  if n_elements(data) ne lll then begin
     dprint,'Improper packet size',dlevel=2
     dprint,dlevel=1, 'Size error ',$
            n_elements(data),ccsds.size,ccsds.apid
     return,0
  endif
  ns = lll/4

  ;;--------------------------------
  ;; Convert 4 bytes to a ulong word
  cnts = swap_endian(ulong(data,0,ns) ,$
                     /swap_if_little_endian )   
  cnts = reform(temporary(cnts),16,ns/16)

  if 0 then begin
    hexprint,data
    savetomain,data
    savetomain,cnts
 endif

  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    ndat: n_elements(cnts), $
    cnts: float(cnts[*]), $
    gap: 0 }

    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str

end

pro spp_swp_spane_p1_init

  spp_apid_data,'360'x ,$
                routine='spp_swp_spane_p1_decom',$
                tname='spp_spane_p1_',$
                tfields='*',$
                rt_tags='*', $
                save=save,$
                rt_flag=rt_flag

end
