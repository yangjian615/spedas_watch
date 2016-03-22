; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-03-20 20:58:48 -0700 (Sun, 20 Mar 2016) $
; $LastChangedRevision: 20520 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $

function spp_swp_swem_unwrapper,ccsds,ptp_header=ptp_header,apdat=apdat
  
;  str = create_struct(ptp_header,ccsds)
  str = {time:ccsds.time, $
         apid:ccsds.apid, $
         size:ccsds.size+7 -20, $
         gap:0 }

  n = n_elements(ccsds.data)
  if debug(3) then begin
    dprint,dlevel=4,'swem',ccsds.size+7, n_elements(ccsds.data), ccsds.apid
    hexprint,ccsds.data[0: (n-1) < 31]
  endif
  if 1 then begin
    sub = ccsds.data[12:*]
    spp_ccsds_pkt_handler,sub,ptp_header=ptp_header
    
  endif
  
  return,str
end
