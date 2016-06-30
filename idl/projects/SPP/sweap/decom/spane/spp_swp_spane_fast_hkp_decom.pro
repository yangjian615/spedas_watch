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

  header    = ccsds.data[0:19]
;  ns = pksize - 20
;  log_flag    = header[12]
  mode1 = header[13]
  mode2 = (swap_endian(uint(ccsds.data,14,1) ,/swap_if_little_endian ))[0]
  f0 = (swap_endian(ulong(header,16,1), /swap_if_little_endian))[0]
  status_flag = header[18]
  peak_bin = header[19]



  fhk = { $
        ;time:       ptp_header.ptp_time, $
        time:       time, $
        met:        ccsds.met,  $
        delay_time: ptp_header.ptp_time - ccsds.time, $
        seq_cntr:   ccsds.seq_cntr, $
        mode1:        mode1,  $
        mode2:        mode2,  $
    ;    f0:           f0,$
    ;    status_flag: status_flag,$
        peak_bin:    peak_bin, $

        ;; 16 bits x offset 20 bytes x 512 values
        ADC:        data $

        }

return,0   ; quick fix
  return,fhk

end


