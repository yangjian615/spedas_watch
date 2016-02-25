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
; $LastChangedDate: 2016-02-24 09:12:06 -0800 (Wed, 24 Feb 2016) $
; $LastChangedRevision: 20149 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_feeps_sectspec_crib.pro $
;-

trange = ['2015-08-24/13:53', '2015-08-24/14:05']
data_rate = 'brst'
probe = '1'

; load the FEEPS data
mms_load_feeps, probe = probe, trange = trange, data_rate = data_rate, /time_clip

; generate the sector-time spectrograms, no sun contamination removed
mms_feeps_sector_spec, probe = probe, data_rate = data_rate

; no sun contamination removed
tplot, ['mms1_epd_feeps_bottom_count_rate_sensorID_3_sectspec', $
        'mms1_epd_feeps_bottom_count_rate_sensorID_4_sectspec', $
        'mms1_epd_feeps_bottom_count_rate_sensorID_5_sectspec', $
        'mms1_epd_feeps_bottom_count_rate_sensorID_10_sectspec', $
        'mms1_epd_feeps_bottom_count_rate_sensorID_11_sectspec']
        
; generate the sector-time spectrograms with sun contamination removed
mms_feeps_sector_spec, probe = probe, data_rate = data_rate, /remove_sun

window, 1
tplot, window=1, ['mms1_epd_feeps_bottom_count_rate_sensorID_3_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_count_rate_sensorID_4_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_count_rate_sensorID_5_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_count_rate_sensorID_10_sun_removed_sectspec', $
  'mms1_epd_feeps_bottom_count_rate_sensorID_11_sun_removed_sectspec']
stop
end