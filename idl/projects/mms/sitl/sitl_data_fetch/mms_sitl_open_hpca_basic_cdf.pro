; Read HPCA CDF
;

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-07-07 15:51:11 -0700 (Tue, 07 Jul 2015) $
;  $LastChangedRevision: 18033 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_open_hpca_basic_cdf.pro $


function mms_sitl_open_hpca_basic_cdf, filename

  var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
    /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)

  ; Find out what variables are in here

;  for i = 0, n_elements(cdf_str.vars.name)-1 do begin
;    print, i, '  ', cdf_str.vars(i).name
;;    print, i, '  ', cdf_str.vars(i).dataptr
;
;  endfor

  time_tt2000 = *cdf_str.vars(0).dataptr
  time_unix = time_double(time_tt2000, /tt2000)
  
ispec = *cdf_str.vars(32).dataptr 
aspec = *cdf_str.vars(42).dataptr  
hespec = *cdf_str.vars(37).dataptr  
ospec = *cdf_str.vars(47).dataptr  
 
  
;  hspecname = *cdf_str.vars(32).dataptr
  
;  specstrlen = strlen(cdf_str.vars(31).name)
    ispecname = cdf_str.vars(32).name
    aspecname = cdf_str.vars(42).name
    hespecname = cdf_str.vars(37).name
    ospecname = cdf_str.vars(47).name
  

  
  energies = *cdf_str.vars(12).dataptr

  data3d = *cdf_str.vars(32).dataptr
  data4d = *cdf_str.vars(42).dataptr
  data5d = *cdf_str.vars(37).dataptr
  data6d = *cdf_str.vars(47).dataptr
  
    
  
  outstruct = {times: time_unix, energies: energies, $
     ispecname:ispecname, aspecname:aspecname, $
     hespecname:hespecname, ospecname:ospecname, data:data3d, $
     data2:data4d, data3:data5d, data4:data6d}
  
  return, outstruct

end
