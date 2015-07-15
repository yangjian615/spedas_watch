; Read HPCA CDF
;

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-07-13 16:05:06 -0700 (Mon, 13 Jul 2015) $
;  $LastChangedRevision: 18114 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_open_hpca_moments_cdf.pro $


function mms_sitl_open_hpca_moments_cdf, filename

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)

  ; Find out what variables are in here

  for i = 0, n_elements(cdf_str.vars.name)-1 do begin
    print, i, '  ', cdf_str.vars(i).name
    print, i, '  ', cdf_str.vars(i).dataptr
  endfor

  time_tt2000 = *cdf_str.vars(0).dataptr
  time_unix = time_double(time_tt2000, /tt2000)
  
hdens = *cdf_str.vars(2).dataptr 
;adens = *cdf_str.vars(4).dataptr  
;hedens = *cdf_str.vars(3).dataptr  
odens = *cdf_str.vars(5).dataptr
hvel = *cdf_str.vars(7).dataptr 
;avel = *cdf_str.vars(9).dataptr  
;hevel = *cdf_str.vars(8).dataptr  
ovel = *cdf_str.vars(10).dataptr 
htemp = *cdf_str.vars(12).dataptr 
otemp = *cdf_str.vars(15).dataptr 

  
 
  
;  hspecname = *cdf_str.vars(32).dataptr
  
;  specstrlen = strlen(cdf_str.vars(31).name)
    hdensname = cdf_str.vars(2).name
;    adensname = cdf_str.vars(4).name
;    hedensname = cdf_str.vars(3).name
    odensname = cdf_str.vars(5).name
    hvelname = cdf_str.vars(7).name
;    avelname = cdf_str.vars(9).name
;    hevelname = cdf_str.vars(8).name
    ovelname = cdf_str.vars(10).name
    htempname = cdf_str.vars(12).name
    otempname = cdf_str.vars(15).name


  

  data5d = *cdf_str.vars(2).dataptr
;  data6d = *cdf_str.vars(4).dataptr
;  data7d = *cdf_str.vars(3).dataptr
  data8d = *cdf_str.vars(5).dataptr
  data20d = *cdf_str.vars(7).dataptr
;  data21d = *cdf_str.vars(9).dataptr
;  data22d = *cdf_str.vars(8).dataptr
  data23d = *cdf_str.vars(10).dataptr
  data24d = *cdf_str.vars(12).dataptr
  data25d = *cdf_str.vars(15).dataptr


  
    
  
  outstruct = {times: time_unix,  $
     hdenscname:hdensname, $
     odensname:odensname, $
     hvelcname:hvelname, $
     ovelname:ovelname, $
     htempname:htempname, $
     otempname:otempname, $    
     data5:data5d, $
     data8:data8d, data20:data20d, $
     data23:data23d, data24:data24d, data25:data25d}
  
  return, outstruct

end
