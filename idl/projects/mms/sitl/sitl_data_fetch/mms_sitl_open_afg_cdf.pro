; This opens a CDF file containing AFG data
; It also returns the ephemeris. NOTE it returns PREDICTED ephemeris.

function mms_sitl_open_afg_cdf, filename

var_type = ['data']
CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
  /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
  convert_int1_to_int2=convert_int1_to_int2)
    
; Get time data

times_TT_nanosec = *cdf_str.vars[0].dataptr
times_unix = time_double(times_TT_nanosec, /tt2000)
  
vector_data = *cdf_str.vars[2].dataptr
varname = cdf_str.vars(2).name

ephem_data = *cdf_str.vars[10].dataptr
ephem_name = cdf_str.vars[10].name
ephem_times_TT_nanosec = *cdf_str.vars[5].dataptr
ephem_times_unix = time_double(ephem_times_TT_nanosec, /tt2000)

; Grab epehem data
posx = ephem_data(*,0)
posy = ephem_data(*,1)
posz = ephem_data(*,2)
posr = ephem_data(*,3)

posvector = [[posx],[posy],[posz],[posr]]

; Says data is in orthogonalized boom coordinates.
bx = vector_data(*,0)
by = vector_data(*,1)
bz = vector_data(*,2)

bvector = [[bx], [by], [bz]]

outstruct = {x: times_unix, y: bvector, varname: varname, ephemx:ephem_times_unix, ephemy: posvector, ephem_varname: ephem_name}

return, outstruct

end