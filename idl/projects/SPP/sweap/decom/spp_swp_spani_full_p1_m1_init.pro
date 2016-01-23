;;; SPANI PRODUCT 1

function spp_swp_spani_full_p1_m1_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  
  data = ccsds.data[20:*]

  lll = 1024*4
  if n_elements(data) ne lll then begin
     dprint,'Improper packet size',dlevel=2
     dprint,dlevel=1, 'Size error ',$
           n_elements(data),ccsds.size,ccsds.apid
     return,0
  endif
  ns = lll/4

  cnts = reform(temporary(data),32,16,8)

  
  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    ndat: n_elements(cnts), $
    cnts: float(cnts[*]), $
    enr_cnts: float(total(reform(total(cnts,3)),2)), $
       
    cnts_a00: float(reform(total(cnts[*, 0,*],1))), $
    cnts_a01: float(reform(total(cnts[*, 1,*],1))), $
    cnts_a02: float(reform(total(cnts[*, 2,*],1))), $
    cnts_a03: float(reform(total(cnts[*, 3,*],1))), $
    cnts_a04: float(reform(total(cnts[*, 4,*],1))), $
    cnts_a05: float(reform(total(cnts[*, 5,*],1))), $
    cnts_a06: float(reform(total(cnts[*, 6,*],1))), $
    cnts_a07: float(reform(total(cnts[*, 7,*],1))), $
    cnts_a08: float(reform(total(cnts[*, 8,*],1))), $
    cnts_a09: float(reform(total(cnts[*, 9,*],1))), $
    cnts_a10: float(reform(total(cnts[*,10,*],1))), $
    cnts_a11: float(reform(total(cnts[*,11,*],1))), $
    cnts_a12: float(reform(total(cnts[*,12,*],1))), $
    cnts_a13: float(reform(total(cnts[*,13,*],1))), $
    cnts_a14: float(reform(total(cnts[*,14,*],1))), $
    cnts_a15: float(reform(total(cnts[*,15,*],1))), $

    gap: 0 }

    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str

end

pro spp_swp_spani_full_p1_m1_init

  spp_apid_data,'380'x ,$
                routine='spp_swp_spani_full_p1_m1_decom',$
                tname='spp_swp_spani_full_p1_m1_',$
                tfields='*',$
                rt_tags='*', $
                save=save,$
                rt_flag=rt_flag

end
