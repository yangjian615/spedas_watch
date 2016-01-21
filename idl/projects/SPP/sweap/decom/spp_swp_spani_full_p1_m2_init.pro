;;; SPANI PRODUCT 1

function spp_swp_spani_full_p1_m2_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  
  data = ccsds.data[20:*]
  ;print,data
  lll = 1024*4
  if n_elements(data) ne lll then begin
     dprint,'Improper packet size',dlevel=2
     dprint,dlevel=1, 'Size error ',$
           n_elements(data),ccsds.size,ccsds.apid
     return,0
  endif
  ns = lll/4

  
  stop
  ;;--------------------------------
  ;; Convert 4 bytes to a ulong word
  cnts = swap_endian(ulong(data,0,ns) ,$
                     /swap_if_little_endian )   
  cnts = reform(temporary(cnts),8,32,4)

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

    cnts_a0:  float(reform(cnts[ 0,*])), $
    cnts_a1:  float(reform(cnts[ 1,*])), $
    cnts_a2:  float(reform(cnts[ 2,*])), $
    cnts_a3:  float(reform(cnts[ 3,*])), $
    cnts_a4:  float(reform(cnts[ 4,*])), $
    cnts_a5:  float(reform(cnts[ 5,*])), $
    cnts_a6:  float(reform(cnts[ 6,*])), $
    cnts_a7:  float(reform(cnts[ 7,*])), $
    cnts_a8:  float(reform(cnts[ 8,*])), $
    cnts_a9:  float(reform(cnts[ 9,*])), $
    cnts_a10: float(reform(cnts[10,*])), $
    cnts_a11: float(reform(cnts[11,*])), $
    cnts_a12: float(reform(cnts[12,*])), $
    cnts_a13: float(reform(cnts[13,*])), $
    cnts_a14: float(reform(cnts[14,*])), $
    cnts_a15: float(reform(cnts[15,*])), $

    gap: 0 }

    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str

end

pro spp_swp_spani_full_p1_m2_init

  spp_apid_data,'381'x ,$
                routine='spp_swp_spani_full_p1_m2_decom',$
                tname='spp_swp_spani_full_p1_m2_',$
                tfields='*',$
                rt_tags='*', $
                save=save,$
                rt_flag=rt_flag

end
