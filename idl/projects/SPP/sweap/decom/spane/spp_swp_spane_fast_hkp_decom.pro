;;; Fast Housekeeping Data as of SPAN-E FPGA rev #22, 3/10/2015

function spp_swp_spane_fast_hkp_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  ;;----------------------
  ;; 1. 20 CCSDS header bytes (should be 10?)
  ;; 2. 512 ADC values, each 2 bytes

  b = ccsds.data
  data = swap_endian(/swap_if_little_endian,  uint(b,20,512))
  ;; New York Second
  time = ccsds.time + (0.87*findgen(512)/512.)

  plot, data

  fhk = { $
        ;time:       ptp_header.ptp_time, $
        time:       time, $
        met:        ccsds.met,  $
        delay_time: ptp_header.ptp_time - ccsds.time, $
        seq_cntr:   ccsds.seq_cntr, $

        ;; 16 bits x offset 20 bytes x 512 values
        ADC:        data $

        }

  return,fhk

end


;pro spp_swp_spane_fhk_init;
;
;  spp_apid_data,'36F'x,$
;                routine='spp_swp_spane_fhk_decom',$
;                tname='spp_swp_spane_fhk_',$
;                tfields='*',$
;                name='SPP SWEAP SPANE FHK',$
;                rt_tags='*',$
;                save=1
;
;end


