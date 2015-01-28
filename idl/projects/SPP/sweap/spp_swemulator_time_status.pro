
function spp_swemulator_time_status,buffer   ;  decoms 12 Word time and status message from SWEMulator
  v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)
  f0 = v[0]
  time = V[1] * 2d^16 + V[2]  + V[3]/(2d^16)

  ts = { f0: f0,  MET:time, revnum:buffer[8],  power_flag: buffer[9], fifo_cntr:buffer[10], fifo_flag: buffer[11], $
    sync: v[6], counts:v[7]  , parity_frame: v[8],  command:v[9],  telem_fifo:v[10],  inst_power_flag:v[11]  }
  return,ts
end



