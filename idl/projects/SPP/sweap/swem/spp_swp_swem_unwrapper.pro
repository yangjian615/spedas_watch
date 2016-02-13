; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-02-12 15:00:45 -0800 (Fri, 12 Feb 2016) $
; $LastChangedRevision: 19984 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/swem/spp_swp_swem_unwrapper.pro $



function spp_swp_swem_unwrapper,ccsds,ptp_header=ptp_header,apdat=apdat
  str = create_struct(ptp_header,ccsds)
  if debug(2) then begin
    dprint,dlevel=2,'swem',ccsds.size+7, n_elements(ccsds.data), ccsds.apid
    hexprint,ccsds.data[0:31]
 endif
  return,str
end


