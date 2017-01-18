;+
;Procedure:
;  thm_sst_quality_flags
;  
;Description:
;  makes a bitpacked tplot variable containing quality flags for ground moments
;  
;  ESA:
;  bit0 = pre-efi boom deployment (using zeroed spacecraft potential)
;  bit1 = counter overflow flag
;  bit2 = solar wind mode flag(disabled)
;  bit3 = flow flag, flow less than threshold is flagged
;  bit4 = manuever flag
;  
;  SST:
;  Bit 8: saturated. (psef_count_rate > 10k)
;  Bit 9: attenuator error (stuck attenuator or incorrect indicator)
;  
;  Set timespan by calling timespan outside of this routine.(e.g. time/duration is not an argument)
;  
; $LastChangedBy: pcruce $
; $LastChangedDate: 2017-01-17 15:08:58 -0800 (Tue, 17 Jan 2017) $
; $LastChangedRevision: 22616 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_gmom_quality_flags.pro $
;-


pro thm_gmom_quality_flags,probe=probe,esa_flow_threshold=esa_flow_threshold,esa_datatype=esa_datatype,sst_datatype=sst_datatype

  compile_opt idl2
 
  thm_esa_quality_flags,probe=probe,datatype=esa_datatype,flow_threshold=esa_flow_threshold
  
  ;sst quality flags just produces all data types
  thm_sst_quality_flags,probe=probe,datatype=sst_datatype
  
  esa_name = 'th'+probe+'_'+esa_datatype+'_data_quality'
  sst_name = 'th'+probe+'_'+sst_datatype+'_data_quality'
  
  cmb_datatype = 'pt'+strmid(esa_datatype,2,2)+strmid(sst_datatype,3,1)

  cmb_name = 'th'+probe+'_'+cmb_datatype+'_data_quality'
  
  ;guarantee same time grid.
  ;since flag values are bit-coded, linear interpolation is inappropriate, nearest neighbor used instead 
  tinterpol_mxn,sst_name,esa_name,/overwrite,/nearest_neighbor
  
  get_data,'th'+probe+'_'+esa_datatype+'_data_quality',data=esa_data
  get_data,'th'+probe+'_'+sst_datatype+'_data_quality',data=sst_data
  
  cmb_data = ('ff'x and esa_data.y) or ishft('ff'x and sst_data.y,8)
  
  store_data,'th'+probe+'_'+cmb_datatype+'_data_quality',data={x:esa_data.x,y:cmb_data},dlimits={tplot_routine:'bitplot'}
 
end