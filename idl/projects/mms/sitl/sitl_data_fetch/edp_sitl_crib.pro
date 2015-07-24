; example for fetching edp sitl data
; 
; Note - we haven't added checks for whether or not data is despun yet, so use at your own risk. These checks are coming soon.


mms_init, local_data_dir='/Volumes/MMS/data/mms/'

timespan, '2015-06-22/05:00:00', 12, /hour

;timespan, '2015-05-07/00:00:00', 12, /hour

mms_load_edp, sc = 'mms3', level='l1b', mode='comm', data_type='dcecomm';, /no_sweeps

;mms_data_fetch, flist, lflag, dlflag, sc_id='mms3', level='l1b', optional_descriptor='dcecomm', mode='comm', instrument_id='edp'

options, 'mms3_edp_comm_dce_sensor', 'ytitle', 'E, mV/m'
options, 'mms3_edp_comm_dce_sensor', labels=['X','Y','Z']
options, 'mms3_edp_comm_dce_sensor', 'labflag', -1

tplot, 'mms3_edp_comm_dce_sensor'

end