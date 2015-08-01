; example for fetching edp sitl data
; 
; Note - we haven't added checks for whether or not data is despun yet, so use at your own risk. These checks are coming soon.


mms_init

timespan, '2015-07-28/00:00:00', 24, /hour

;timespan, '2015-05-07/00:00:00', 12, /hour

probes = ['3']

mms_load_edp, probes = probes, level='l1b', data_rate='fast', datatype='dce';, /no_sweeps

;mms_data_fetch, flist, lflag, dlflag, sc_id='mms3', level='l1b', optional_descriptor='dcecomm', mode='comm', instrument_id='edp'

options, 'mms' + probes + '_edp_fast_dce_sensor', 'ytitle', 'E, mV/m'
options, 'mms' + probes + '_edp_fast_dce_sensor', labels=['X','Y','Z']
options, 'mms' + probes + '_edp_fast_dce_sensor', 'labflag', -1
ylim, 'mms' + probes + '_edp_fast_dce_sensor', -20, 20
tplot, 'mms' + probes + '_edp_fast_dce_sensor'

end