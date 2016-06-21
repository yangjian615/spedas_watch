function spp_swp_swem_timing_decom,ccsds,ptp_header=ptp_header,apdat=apdat

common spp_swp_swem_timing_decom_com2,  last_str,  fields_dt
data = ccsds.data

if ccsds.pkt_size lt 72 then begin
  dprint,'error'
  return,0
endif

values = swap_endian(ulong(data,10,11) )
values2 = swap_endian(ulong(data,448/8,4) )
sc_time_subsecs =  (swap_endian(uint(data,432/8,1) ,/swap_if_little_endian ))[0]

sample_clk_per = double(values[0])
scpps_met_time = double(values[1])
sample_MET = values[3] + values[2]/ 2d^16
fields_f123 = values[5] + values[6] / 2d^16
fields_met = values[7] + values[8] / 2d^16
sc_time = values[10] + sc_time_subsecs / 2d^16
fields_f0 = values2[0]
scsubsecsatpps = values2[1]
fields_smpl_timerr = values2[2]
clks_per_pps = values2[3]

;
;printdat,ptp_header


;last_str = 0

nan= !values.d_nan
if ~keyword_set(last_str) then last_str = {sample_clk_per:nan, scpps_met_time:nan, sample_met: nan, sc_time:nan,  $
     fields_f123:nan, fields_met:nan, drift:nan, fields_clk_cycles:0ul,clks_per_pps:0ul}

;cludge to force the fields quantities to be nearly the same
;delvar,fields_dt
if n_elements(fields_dt) eq 0 then fields_dt = floor(fields_met - fields_f123)
fields_f123 += fields_dt 

ttt = sample_met
;ttt = fields_met
 
 
;printdat,ccsds
;dprint,ccsds.met - values[1],ccsds.dtime
 
 
sample_clk_per_delta =    double( uint( ( sample_clk_per - last_str.sample_clk_per) ) )
 
time_drift = (sample_MET - sample_clk_per * (2d^24 / 19.2d6) ) mod 1
 
fields_clk_cycles =  ishft(ulong(values[4]),-1)
fields_clk_cycles_delta = ( fields_clk_cycles - last_str.fields_clk_cycles )   and '1FFFFFF'xu

if fields_clk_cycles_delta ge 2e7 then fields_clk_cycles_delta /= 2


dseq = ccsds.dseq_cntr
k = 2ul^25

clks_per_pps_delta =     ( clks_per_pps - last_str.clks_per_pps  ) and (k-1)

clks_per_pps_delta = ( clks_per_pps_delta + k *floor(dseq * 19.2d6/k) ) / dseq


if debug(3) then begin
  
  hexprint,[clks_per_pps,clks_per_pps_delta]
  dprint,clks_per_pps,clks_per_pps_delta
endif


; hexprint,fields_clk_cycles
;dprint,dlevel=2,fields_clk_cycles ,fields_clk_cycles_delta
;hexprint,[fields_clk_cycles,fields_clk_cycles_delta]
;printdat,fields_clk_cycles,fields_clk_cycles_delta

 
str = {time:   ccsds.time  ,$
       dtime:  ccsds.dtime / ccsds.dseq_cntr   ,$
       ptp_delay_time:  ptp_header.ptp_time - ccsds.time, $
       seq_cntr : ccsds.seq_cntr, $
       dseq_cntr:  ccsds.dseq_cntr < 15u , $
       sample_clk_per: sample_clk_per  , $
     scpps_met_time:    scpps_met_time ,$
     scpps_met_time_delta:  scpps_met_time - last_str.scpps_met_time, $
     MET_TIME_DIFF:   scpps_met_time - ccsds.met, $
     sample_MET_subsec:   values[2] ,$
;     sample_MET_secs:   values[3] ,$
     fields_clk_cycles:  fields_clk_cycles,$
       fields_clk_cycles_delta:  long(fields_clk_cycles_delta) - 2L^24,$
     fields_clk_transition:  values[4] and 1 ,$
;     fields_F1F2:       values[5] ,$
     fields_subsec:          values[6] ,$
;     fields_MET_secs:    values[7] ,$
     fields_MET_subsec:  values[8] ,$
     MET_jitter:       values[9] ,$
;     sc_time_SECS:  values[10] ,$
     sc_time_subSEC: sc_time_subsecs , $
     sample_MET:        sample_MET ,$
     fields_F123:      fields_f123 ,$
     fields_MET:       fields_met ,$
     sc_time :         sc_time, $
     sample_clk_per_delta:      sample_clk_per_delta  , $
     fields_f123_delta:    (fields_F123 - last_str.fields_F123) / ccsds.dseq_cntr , $
     fields_met_delta:     (fields_met - last_str.fields_met) / ccsds.dseq_cntr , $
     sample_met_delta:     (sample_met - last_str.sample_met) / sample_clk_per_delta , $
     sc_time_delta:        (sc_time - last_str.sc_time) / ccsds.dseq_cntr , $
     sample_MET_diff:       sample_MET - ttt, $
     fields_F123_diff:      fields_f123 -ttt ,$
     fields_MET_diff:       fields_met  -ttt ,$
     sc_time_diff :         sc_time    - ttt, $
     drift:     time_drift, $
     drift_delta:  (time_drift -last_str.drift) / ccsds.dseq_cntr , $
     clks_per_pps:  clks_per_pps, $
     clks_per_pps_delta:  long(clks_per_pps_delta - 19200000L), $
     scsubsecsatpps:scsubsecsatpps,$
     fields_smpl_timerr :fields_smpl_timerr,$
     gap:  ccsds.gap }
       
;tploprintdat,str

  if debug(4,msg='SWEM Timing') then begin
     dprint,dlevel=2,'generic:',ccsds.apid,ccsds.size+7, n_elements(ccsds.data)
     hexprint,ccsds.data
  endif

if debug(3) then begin
  ;dprint,str.fields_clk_cycles_delta
  hexprint,[fields_clk_cycles,fields_clk_cycles_delta,ulong(sample_clk_per)]
  
endif
  last_str = str

  return,str

end

;; tplot,'spp_spani_hkp_DTIME APID spp_swem_timing_FIELDS_CLK_CYCLES_DELTA spp_swem_timing_CLKS_PER_PPS_DELTA spp_swem_timing_DRIFT spp_spani_hkp_ALL_TEM


