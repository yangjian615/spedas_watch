; Crib sheet showing how to fetch mag data

;cache_dir = '/Users/frederickwilder/'
cache_dir = 'abs_tmp/'

;start_date = '2009-02-01'
;end_date = '2009-02-07'
start_date = '2015-04-10'
end_date = '2015-04-11'

thm_init
dt = (str2time(end_date)-str2time(start_date))/86400.d
timespan,start_date,dt

; Get mms2 data
mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status, dfg_status, sc_id='mms2'

;; Forget to include sc_id - will default to 'mms1,' but there is no data.

mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status2, dfg_status2

; Lets try e spectrum

mms_sitl_get_espec, start_date, end_date, cache_dir, data_status, sc_id='mms2'

mms_sitl_get_dce,  start_date, end_date, cache_dir, sdp_status, sc_id='mms2';, coord=coord, no_update = no_update

end