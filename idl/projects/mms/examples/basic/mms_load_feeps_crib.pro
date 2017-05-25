;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-05-05 11:17:26 -0700 (Fri, 05 May 2017) $
; $LastChangedRevision: 23270 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_feeps_crib.pro $
;-

xsize=600
ysize=850

mms_load_feeps, probes='1', trange=['2015-10-16', '2015-10-17'], datatype='electron', level='l2'
mms_feeps_pad,  probe='1', datatype='electron'

; plot the data with the integral channel and sun removed
; along with the PAD (non-spin averaged)
window, 0, xsize=xsize, ysize=ysize
tplot, [['mms1_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_3', $
  'mms1_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_4', $
  'mms1_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_5', $
  'mms1_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_12']+'_clean_sun_removed', $
  'mms1_epd_feeps_srvy_l2_electron_intensity_70-1000keV_pad'], window=0
stop

; add the spin averaged, omni-directional electron spectra 
; and PAD covering the full energy range
window, 1, xsize=xsize, ysize=ysize
tplot, ['mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', $
        'mms1_epd_feeps_srvy_l2_electron_intensity_70-1000keV_pad_spin'],window=1, /add

end