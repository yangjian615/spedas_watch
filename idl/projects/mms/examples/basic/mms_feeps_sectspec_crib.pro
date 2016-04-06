;+
;
;     mms_feeps_sectspec_crib
;     
;     
;     This crib sheet shows how to create sector spectrograms of FEEPS data
;     for checking effectiveness of sunlight masking/removal
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-01 12:06:38 -0700 (Fri, 01 Apr 2016) $
; $LastChangedRevision: 20701 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_feeps_sectspec_crib.pro $
;-

trange = ['2016-1-20/19:50', '2016-1-20/19:55']
data_rate = 'brst'
probe = '1'
level = 'l2'

; load the FEEPS data
mms_load_feeps, probe = probe, trange = trange, data_rate = data_rate, level='l2', /time_clip

; generate the sector-time spectrograms, no sun contamination removed
mms_feeps_sector_spec, probe = probe, data_rate = data_rate

stop

; electrons, no sun contamination removed
tplot, ['mms1_epd_feeps_bottom_electron_count_rate_sensorid_3_sectspec', $
        'mms1_epd_feeps_bottom_electron_count_rate_sensorid_4_sectspec', $
        'mms1_epd_feeps_bottom_electron_count_rate_sensorid_5_sectspec', $
        'mms1_epd_feeps_bottom_electron_count_rate_sensorid_10_sectspec', $
        'mms1_epd_feeps_bottom_electron_count_rate_sensorid_11_sectspec']

stop

; generate the sector-time spectrograms with sun contamination removed
mms_feeps_sector_spec, probe = probe, data_rate = data_rate, /remove_sun

window, 1
tplot, window=1, ['mms1_epd_feeps_bottom_electron_count_rate_sensorid_3_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_electron_count_rate_sensorid_4_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_electron_count_rate_sensorid_5_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_electron_count_rate_sensorid_10_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_electron_count_rate_sensorid_11_sun_removed_sectspec']
stop
end