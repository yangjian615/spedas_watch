; This opens a CDF file containing AFG data
; 

function mms_sitl_open_afg_cdf, filename

var_type = ['data']
CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
  /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
  convert_int1_to_int2=convert_int1_to_int2)
    
; Get time data
  
times_TT_nanosec = *cdf_str.vars[0].dataptr
times_TT_days = times_tt_nanosec/(1e9*86400D)
  
times_jul = times_TT_days + julday(1, 1, 2000, 12, 0, 0)

times_unix =  86400D * (times_jul - julday(1, 1, 1970, 0, 0, 0 ))

  
vector_data = *cdf_str.vars[2].dataptr
varname = cdf_str.vars(2).name

; Says data is in orthogonalized boom coordinates.
bx = vector_data(*,0)
by = vector_data(*,1)
bz = vector_data(*,2)

bvector = [[bx], [by], [bz]]

outstruct = {x: times_unix, y: bvector, varname: varname}

return, outstruct

end