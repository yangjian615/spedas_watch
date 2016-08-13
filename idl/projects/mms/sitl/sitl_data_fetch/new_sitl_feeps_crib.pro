; SITL FEEPS CRIB
; 

timespan, '2016-08-09/00:00:00', 24, /hour

probe = '1'
sc_id = 'mms'+probe

mms_sitl_get_feeps, probes=probe, datatype='electron', level='sitl'

feeps_name = sc_id + '_epd_feeps_srvy_sitl_electron_top_counts_sensorid_11'
new_name = sc_id + '_epd_feeps_electron_intensity_sensorid_11_clean_sun_removed'

stop
tplot_rename, feeps_name, new_name

store_data, ['*top*'], /delete

ylim, new_name, 30, 500

tplot, new_name

end