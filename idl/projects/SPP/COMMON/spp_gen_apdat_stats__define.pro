 
 
pro spp_gen_apdat_stats::handler,ccsds,ptp_header
self.increment_counters, ccsds
self.data.append, {time: ccsds.time,  apid: ccsds.apid , gap:ccsds.gap }
if self.rt_flag then begin
  store_data,'APIDS_ALL',ccsds.time,ccsds.apid, /append,dlimit={psym:3,symsize:.2 ,ynozero:1}
  if ccsds.gap ne 0 then  store_data,'APIDS_GAP',ccsds.time,ccsds.apid,  /append,  dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}
endif
end
 
 
 
pro spp_gen_apdat_stats::finish,append=append
   dprint,'hello'
   store_data,'APID',data='APIDS_ALL APIDS_GAP',  dlimit={ynozero:1}
   d = self.data.array
   
   store_data,'APIDS_ALL', d.time, d.apid, append=append ,dlimit={psym:3,symsize:.2 ,ynozero:1}
   w = where(d.gap ne 0)
   store_data,'APIDS_GAP', d[w].time, d[w].apid, append=append , dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}
   printdat,w
end
 

 
 
PRO spp_gen_apdat_stats__define
void = {spp_gen_apdat_stats, $
  inherits spp_gen_apdat, $    ; superclass
  sample1: obj_new() , $
  sample2: obj_new()  $
  }
END



