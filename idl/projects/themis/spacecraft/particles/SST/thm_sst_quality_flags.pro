;+
;Procedure:
;  sst_quality_flags
;  
;Description:
;  makes a bitpacked tplot variable containing quality flags for SST
;  
;  Bit 0: saturated. (psef_count_rate > 10k)
;  Bit 1: attenuator error (stuck attenuator or incorrect indicator)
;  
;  Set timespan by calling timespan outside of this routine.(e.g. time/duration is not an argument)
;  
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-08-18 13:09:40 -0700 (Thu, 18 Aug 2016) $
; $LastChangedRevision: 21675 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_quality_flags.pro $
;-


  pro thm_sst_quality_flags,probe=probe
  
    compile_opt idl2
    
    thm_load_sst,probe=probe
    
    get_data,'th'+probe+'_psef_tot',data=d
    
    bit0 = d.y gt 1e4
    
    get_data,'th'+probe+'_psef_atten',data=d
    
    bit1 = (d.y ne 5) and (d.y ne 10)
    
    flags = bit0 or ishft(bit1,1)
    
    store_data,'th'+probe+'_quality_flags',data={x:d.x,y:flags}
    
  end