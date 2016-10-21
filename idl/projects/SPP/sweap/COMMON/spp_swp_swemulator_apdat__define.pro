function spp_swp_swemulator_apdat::decom , ccsds, ptp_header
  buffer = spp_swp_ccsds_data(ccsds)
  
  if ccsds.time gt 1.76e9 then  ccsds.time -= 315576000   ; fix error in timing

   v = swap_endian( uint(buffer[10:*],0,12) ,/swap_if_little_endian)
   f0 = v[0]
   met = V[1] * 2d^16 + V[2]  + V[3]/(2d^16)
   time=spp_spc_met_to_unixtime(met)

   tns = { time:time, f0:f0,  MET:met, revnum:buffer[8+6],  power_flag: buffer[9], fifo_cntr:buffer[10], fifo_flag: buffer[11], $
     sync: v[6], counts:v[7]  , parity_frame: v[8],  command:v[9],  telem_fifo_flag:v[10],  inst_power_flag:v[11]  }
  
  return, tns 
end 
 
 

 
 
PRO spp_swp_swemulator_apdat__define
void = {spp_swp_swemulator_apdat, $
  inherits spp_gen_apdat $    ; superclass
  }
END



