function mms_sitl_open_dsp_ace_cdf, filename

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)
    
  ; Get time data
  
  times_TT_nanosec = *cdf_str.vars[0].dataptr
  times_TT_days = times_tt_nanosec/(1e9*86400D)
  
  times_jul = times_TT_days + julday(1, 1, 2000, 12, 0, 0)
  
  times_unix =  86400D * (times_jul - julday(1, 1, 1970, 0, 0, 0 ))
    
  ; Says data is in orthogonalized boom coordinates.
  ex_spec = *cdf_str.vars[2].dataptr
  ey_spec = *cdf_str.vars[3].dataptr
  ez_spec = *cdf_str.vars[4].dataptr
  freq = *cdf_str.vars[7].dataptr
  
  varnames = cdf_str.vars(2:4).name
  
  outstruct = {x: times_unix, ex: ex_spec, ey: ey_spec, ez: ez_spec, freq: freq, varnames:varnames}
  
  return, outstruct
  
end