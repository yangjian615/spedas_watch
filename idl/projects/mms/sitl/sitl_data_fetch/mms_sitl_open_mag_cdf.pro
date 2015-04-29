function mms_sitl_open_mag_cdf, filename

; Currently defaults to near-gse (DMPA) coordinates

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)
    
  ; Get time data
  
  times_TT_nanosec = *cdf_str.vars[0].dataptr
  cdf_leap_second_init
  times_unix = time_double(times_TT_nanosec, /tt2000)
  
  
  vector_data = *cdf_str.vars[2].dataptr
  
  ; Says data is in orthogonalized boom coordinates.
  bx = vector_data(*,0)
  by = vector_data(*,1)
  bz = vector_data(*,2)
  
  bvector = [[bx], [by], [bz]]
  
  outstruct = {x: times_unix, y: bvector}
  
  return, outstruct
  
end