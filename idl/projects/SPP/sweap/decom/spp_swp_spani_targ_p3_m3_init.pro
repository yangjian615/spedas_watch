;;; SPANI PRODUCT 1

function spp_swp_spani_targ_p3_m3_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  
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
       
    cnts_a0:  float(reform(total(cnts[*, 0,*],1))), $
    cnts_a1:  float(reform(total(cnts[*, 1,*],1))), $
    cnts_a2:  float(reform(total(cnts[*, 2,*],1))), $
    cnts_a3:  float(reform(total(cnts[*, 3,*],1))), $
    cnts_a4:  float(reform(total(cnts[*, 4,*],1))), $
    cnts_a5:  float(reform(total(cnts[*, 5,*],1))), $
    cnts_a6:  float(reform(total(cnts[*, 6,*],1))), $
    cnts_a7:  float(reform(total(cnts[*, 7,*],1))), $
    cnts_a8:  float(reform(total(cnts[*, 8,*],1))), $
    cnts_a9:  float(reform(total(cnts[*, 9,*],1))), $
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

pro spp_swp_spani_targ_p3_m3_init

  spp_apid_data,'396'x ,$
                routine='spp_swp_spani_targ_p3_m3_decom',$
                tname='spp_swp_spani_targ_p3_m3_',$
                tfields='*',$
                rt_tags='*', $
                save=save,$
                rt_flag=rt_flag

end
