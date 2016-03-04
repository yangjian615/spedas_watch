;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-03 13:47:50 -0800 (Thu, 03 Mar 2016) $
; $LastChangedRevision: 20316 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_feeps_crib.pro $
;-

xsize=600
ysize=850

mms_load_feeps, probes='1', trange=['2015-12-15', '2015-12-16'], datatype='electron', level='l2'
mms_feeps_pad,  probe='1', datatype='electron'

; log scaling on y axis and colorbar
ylim, 'mms1_epd_feeps_top_electron_intensity_sensorid_*_clean_sun_removed', 0, 0, 1
zlim, 'mms1_epd_feeps_top_electron_intensity_sensorid_*_clean_sun_removed', 0, 0, 1

; plot the data with the integral channel and sun removed
; along with the PAD (non-spin averaged)
window, 0, xsize=xsize, ysize=ysize
tplot, [['mms1_epd_feeps_top_electron_intensity_sensorid_3', $
  'mms1_epd_feeps_top_electron_intensity_sensorid_4', $
  'mms1_epd_feeps_top_electron_intensity_sensorid_5', $
  'mms1_epd_feeps_top_electron_intensity_sensorid_11', $
  'mms1_epd_feeps_top_electron_intensity_sensorid_12']+'_clean_sun_removed', $
  'mms1_epd_feeps_electron_0-1000keV_pad'], window=0
stop

; add the spin averaged, omni-directional electron spectra 
; and PAD covering the full energy range
window, 1, xsize=xsize, ysize=ysize
tplot, ['mms1_epd_feeps_electron_intensity_omni_spin', $
        'mms1_epd_feeps_0-1000keV_pad_spin'],window=1, /add

end