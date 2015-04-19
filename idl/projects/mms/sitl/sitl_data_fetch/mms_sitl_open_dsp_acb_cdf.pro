function mms_sitl_open_dsp_acb_cdf, filename

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)
    
  ; Get time data
  
  times_TT_nanosec = *cdf_str.vars[0].dataptr
  cdf_leap_second_init
  times_unix = time_double(times_TT_nanosec, /tt2000)
  
  ; Says data is in orthogonalized boom coordinates.
  b1_spec = *cdf_str.vars[1].dataptr
  b2_spec = *cdf_str.vars[2].dataptr
  b3_spec = *cdf_str.vars[3].dataptr
  freq = *cdf_str.vars[7].dataptr
  
  varnames = cdf_str.vars(1:3).name
  
  outstruct = {x: times_unix, b1: b1_spec, b2: b2_spec, b3: b3_spec, freq: freq, varnames: varnames}
  
  return, outstruct
  
end