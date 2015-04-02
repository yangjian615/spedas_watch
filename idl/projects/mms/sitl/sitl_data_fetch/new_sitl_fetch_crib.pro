; load some MMS sitl data to stackplot magnetometers
; 


;cache_dir = '/Users/frederickwilder/'
cache_dir = '/Users/moka/'
start_date = '2015-03-17'
end_date = '2015-03-20'

mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status, dfg_status, sc_id='mms2'

mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status, dfg_status, sc_id='mms3'

mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status, dfg_status, sc_id='mms4'

device, decomp = 0
loadct, 39
timespan, '2015-03-17/16:00:00', 2, /hour

options, 'mms2_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']
options, 'mms2_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']

options, 'mms3_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']
options, 'mms3_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']

options, 'mms4_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']
options, 'mms4_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']

options, 'mms2_afg_srvy_gsm_dmpa', 'ytitle', 'AFG2 B, nT'
options, 'mms3_afg_srvy_gsm_dmpa', 'ytitle', 'AFG3 B, nT'
options, 'mms4_afg_srvy_gsm_dmpa', 'ytitle', 'AFG4 B, nT'

options, 'mms2_dfg_srvy_gsm_dmpa', 'ytitle', 'DFG2 B, nT'
options, 'mms3_dfg_srvy_gsm_dmpa', 'ytitle', 'DFG3 B, nT'
options, 'mms4_dfg_srvy_gsm_dmpa', 'ytitle', 'DFG4 B, nT'


tplot, ['mms2_afg_srvy_gsm_dmpa', 'mms3_afg_srvy_gsm_dmpa', 'mms4_afg_srvy_gsm_dmpa']


;window, /free
;tplot, ['mms2_dfg_srvy_gsm_dmpa', 'mms3_dfg_srvy_gsm_dmpa', 'mms4_dfg_srvy_gsm_dmpa']


end