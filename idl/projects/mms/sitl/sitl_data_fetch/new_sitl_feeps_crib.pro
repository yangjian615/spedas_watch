; SITL FEEPS CRIB
; 

timespan, '2016-03-15/00:00:00', 24, /hour

probe = '1'
sc_id = 'mms'+probe

mms_sitl_get_feeps, probes=probe, datatype='electron', level='sitl'

feeps_name = sc_id + '_epd_feeps_top_electron_intensity_sensorid_11_clean_sun_removed'
new_name = sc_id + '_epd_feeps_electron_intensity_sensorid_11_clean_sun_removed'
tplot_rename, feeps_name, new_name

store_data, ['*top*'], /delete

ylim, new_name, 30, 500

tplot, new_name

end