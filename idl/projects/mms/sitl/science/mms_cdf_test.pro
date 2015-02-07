; just a way to check CDFs
; 

filename = '/Users/frederickwilder/IDLWorkspace82/FIELDS_SITL/mms2_sdp_fast_l1b_dcv_20150410_v0.1.1.cdf'

fleE = filename
var_type = ['data']
CDF_str = cdf_load_vars(fleE,varformat=varformat,var_type=var_type,/spdf_depend, $
  varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2)
;new_cdfi = cdfiE ; cdf structure, lots of stuff going on in this so really investigate it
;flename= cdfiE.filename
;inq = cdfiE.inq
;gatt = cdfiE.g_attributes

times_TT_nanosec = *cdf_str.vars[0].dataptr
times_TT_days = times_tt_nanosec/(1e9*86400.)

times_jul = times_TT_days + julday(1, 1, 2000, 12, 0, 0)

times_unix =  86400D * (times_jul - julday(1, 1, 1970, 0, 0, 0 ))


vector_data = *cdf_str.vars[2].dataptr


end