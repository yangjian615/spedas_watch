;+
;Procedure:
;  thm_sst_quality_flags
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
; $LastChangedDate: 2017-01-17 15:08:22 -0800 (Tue, 17 Jan 2017) $
; $LastChangedRevision: 22615 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_quality_flags.pro $
;-


  pro thm_sst_quality_flags,probe=probe,datatype=datatype
  
    compile_opt idl2
    
    thm_load_state,probe=probe,/get_support
    thm_load_sst,probe=probe
         
    get_data,'th'+probe+'_'+datatype+'_tot',data=d
      
    if is_struct(d) then begin
      bit0 = d.y gt 1e4
    endif else begin
      bit0 = 0
    endelse
    
    get_data,'th'+probe+'_'+datatype+'_atten',data=d
    
    if is_struct(d) then begin
      bit1 = (d.y ne 5) and (d.y ne 10)
    endif else begin
      bit1 = 0
    endelse
    
    
    ;state time abcissas won't match sst time abcissas by default 
    tinterpol_mxn,'th'+probe+'_state_spinper','th'+probe+'_'+datatype+'_tot',/overwrite
    get_data,'th'+probe+'_state_spinper',data=d
    
    if is_struct(d) then begin
      bit2 = (d.y lt 2.5) or (d.y gt 5)
    endif else begin
      bit2 = 0
    endelse
    
    flags = bit0 or ishft(bit1,1) or ishft(bit2,2)
    
    store_data,'th'+probe+'_'+datatype+'_data_quality',data={x:d.x,y:flags},dlimits={tplot_routine:'bitplot'}
    store_data,'th'+probe+'_'+datatype+'_data_quality',data={x:d.x,y:flags},dlimits={tplot_routine:'bitplot'}
       
    
    
   
  end