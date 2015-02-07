


function spp_swp_spane_slow_hkp_decom,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 69
  if n_elements(b) ne psize+7 then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint,dlevel=4, 'Odd time at: ',time_string(ccsds.time)

  ref = 5.29 ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    HDR_16: b[16]  * 1.,  $
    HDR_17: b[17]  * 1.,  $
    HDR_18: b[18]  * 1.,  $
    HDR_19: b[19]  * 1.,  $
    
    RIO_20: b[20]  * 1.,  $
    RIO_21: b[21]  * 1.,  $
    RIO_22: b[22]  * 1.,  $
    RIO_23: b[23]  * 1.,  $
    RIO_24: b[24]  * 1.,  $
    RIO_25: b[25]  * 1.,  $
    RIO_26: b[26]  * 1.,  $
    RIO_27: b[27]  * 1.,  $
    RIO_28: b[28]  * 1.,  $
    RIO_29: b[29]  * 1.,  $
    RIO_30: b[30]  * 1.,  $
    RIO_31: b[31]  * 1.,  $
    RIO_32: b[32]  * 1.,  $
    RIO_33: b[33]  * 1.,  $
    RIO_34: b[34]  * 1.,  $
    RIO_35: b[35]  * 1.,  $
    adc_ch00:  swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * ref*3750./4095. , $
    adc_VMON_DEF1:  swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * ref*1000./4095. , $
    adc_ch02:  swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * ref*3750./4095. , $
    adc_VMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * ref*1000./4095. , $
    adc_VMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * ref*750./4095. , $
    adc_VMON_SPL:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * ref*20./4095. , $
    adc_IMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,48 ) ) * ref*3750./4095. , $
    adc_ch07:  swap_endian(/swap_if_little_endian,  fix(b,50 ) ) * ref*3750./4095. , $
    adc_VMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref*1250./4095. , $
    adc_ch09:  swap_endian(/swap_if_little_endian,  fix(b,54 ) ) * ref*3750./4095. , $
    adc_IMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,56 ) ) * ref*3750./4095. , $
    adc_ch11:  swap_endian(/swap_if_little_endian,  fix(b,58 ) ) * ref*3750./4095. , $
    adc_VMON_HEM:  swap_endian(/swap_if_little_endian,  fix(b,60 ) ) * ref*1000./4095. , $
    adc_ch13:  swap_endian(/swap_if_little_endian,  fix(b,62 ) ) * ref*3750./4095. , $
    adc_ch14:  swap_endian(/swap_if_little_endian,  fix(b,64 ) ) * ref*3750./4095. , $
    adc_ch15:  swap_endian(/swap_if_little_endian,  fix(b,66 ) ) * ref*3750./4095. , $
    CMD_ERRS: ishft(b[68],-4), $
    CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,68 ) ) and 'fff'x , $
    BRD_ID: b[70]  ,  $
    REVNUM: b[71]  * 1.,  $
    MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
    ;  SPAI_00
    ACTSTAT_FLAG: b[67]  , $
    GAP: ccsds.gap }

  return,spai

end







function spp_swp_spane_prod1_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  data = ccsds.data[20:*]
  cnts = swap_endian(ulong(data,0,512) ,/swap_if_little_endian )   ; convert 4 bytes to a ulong word
  tot = total(cnts)   
  if 0 then begin    
    hexprint,data
    savetomain,data
    savetomain,cnts
  endif

  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    total :tot, $
    ndat  : n_elements(cnts), $
    cnts: float(cnts), $ 
    gap: 0 }
    
    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str
end



pro spp_swp_spane_init,save=save

  spp_apid_data,'360'x ,routine='spp_swp_spane_prod1_decom',tname='spp_spane_spec_',tfields='*',rt_tags='*', save=save
  spp_apid_data,'36d'x ,routine='spp_generic_decom',tname='spp_spane_dump_',tfields='*',rt_tags='*', save=save
  spp_apid_data,'36e'x ,routine='spp_swp_spane_slow_hkp_decom',tname='spp_spane_hkp_',tfields='*',rt_tags='*', save=save

end



