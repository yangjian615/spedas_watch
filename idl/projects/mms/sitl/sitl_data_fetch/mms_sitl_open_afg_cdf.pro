; This opens a CDF file containing AFG data
; It also returns the ephemeris. NOTE it returns PREDICTED ephemeris.

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

ephem_data = *cdf_str.vars[10].dataptr
ephem_name = cdf_str.vars[10].name
ephem_times_TT_nanosec = *cdf_str.vars[5].dataptr
ephem_times_TT_days = ephem_times_tt_nanosec/(1e9*86400D)
ephem_times_jul = ephem_times_TT_days + julday(1, 1, 2000, 12, 0, 0)
ephem_times_unix =  86400D * (ephem_times_jul - julday(1, 1, 1970, 0, 0, 0 ))

; Grab epehem data
posx = ephem_data(*,0)
posy = ephem_data(*,1)
posz = ephem_data(*,2)

posvector = [[posx],[posy],[posz]]

; Says data is in orthogonalized boom coordinates.
bx = vector_data(*,0)
by = vector_data(*,1)
bz = vector_data(*,2)

bvector = [[bx], [by], [bz]]

outstruct = {x: times_unix, y: bvector, varname: varname, ephemx:ephem_times_unix, ephemy: posvector, ephem_varname: ephem_name}

return, outstruct

end