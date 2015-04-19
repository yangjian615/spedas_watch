; File to open the DCE CDF
; 


function mms_sitl_open_sdp_dce_sitl_cdf, filename, coord

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)
    
  ; Get time data
  
  times_TT_nanosec = *cdf_str.vars[0].dataptr
  cdf_leap_second_init
  times_unix = time_double(times_TT_nanosec, /tt2000)
  
  if coord eq 'pgse' then begin
    vector_data = *cdf_str.vars[2].dataptr
    varname = cdf_str.vars(2).name
  endif
  
  if coord eq 'dsl' then begin 
    vector_data = *cdf_str.vars[3].dataptr
    varname = cdf_str.vars(3).name

  endif  
  
  ex = vector_data(*, 0)
  ey = vector_data(*, 1)
  ez = vector_data(*, 2)
  
  evector = [[ex],[ey],[ez]]
  
  outstruct = {x: times_unix, y:evector, varname:varname}
  
  return, outstruct

end