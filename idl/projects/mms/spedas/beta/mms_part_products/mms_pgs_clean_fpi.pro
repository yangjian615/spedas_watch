
;+
;Procedure:
;  mms_pgs_clean_fpi
;
;
;Purpose:
;  Sanitize mms FPI data structures for use with
;  mms_part_products.  Excess fields will be removed and 
;  field names conformed to standard.  
;
;  Reforms energy by theta by phi to energy by angle
;  Converts units
;
;Input:
;  data_in: Single combined particle data structure
;
;
;Output:
;  output: Sanitized output structure for use within thm_part_products.
;
;
;Notes:
;  -not much should be happening here since the combined structures 
;   are already fairly pruned   
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:45:26 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19673 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_pgs_clean_fpi.pro $
;
;-
pro mms_pgs_clean_fpi, data_in, output=output,units=units

  compile_opt idl2,hidden
  
  
  mms_convert_flux_units,data_in,units=units,output=data
  
  dims = dimen(data.data)
  
  output= {  $
    time: data.time, $
    end_time:data.end_time, $
    scaling:fltarr(dims[0],dims[1]*dims[2])+1,$
    units:units,$
    data: reform(data.data,dims[0],dims[1]*dims[2]), $
    bins: reform(data.bins,dims[0],dims[1]*dims[2]), $
    energy: reform(data.energy,dims[0],dims[1]*dims[2]), $
    denergy: reform(data.denergy,dims[0],dims[1]*dims[2]), $ ;placeholder
    phi:reform(data.phi,dims[0],dims[1]*dims[2]), $
    dphi:reform(data.dphi,dims[0],dims[1]*dims[2]), $
    theta:reform(data.theta,dims[0],dims[1]*dims[2]), $
    dtheta:reform(data.dtheta,dims[0],dims[1]*dims[2]) $
  }
 

end