; example for fetching edp sitl data
; 
; Note - we haven't added checks for whether or not data is despun yet, so use at your own risk. These checks are coming soon.


mms_init

timespan, '2015-08-17/00:00:00', 24, /hour

;timespan, '2015-05-07/00:00:00', 12, /hour

probes = ['3']

mms_load_edp, probes = probes, level='ql', data_rate='fast', datatype='dce';, /no_sweeps

;mms_data_fetch, flist, lflag, dlflag, sc_id='mms3', level='l1b', optional_descriptor='dcecomm', mode='comm', instrument_id='edp'

options, 'mms' + probes + '_edp_fast_dce_dsl', 'ytitle', 'E, mV/m'
options, 'mms' + probes + '_edp_fast_dce_dsl', labels=['X','Y','Z']
options, 'mms' + probes + '_edp_fast_dce_dsl', 'labflag', -1
ylim, 'mms' + probes + '_edp_fast_dce_dsl', -20, 20
tplot, 'mms' + probes + '_edp_fast_dce_dsl'

end