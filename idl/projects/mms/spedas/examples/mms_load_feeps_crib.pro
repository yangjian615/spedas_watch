;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-03 11:25:11 -0700 (Thu, 03 Sep 2015) $
; $LastChangedRevision: 18703 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_feeps_crib.pro $
;-

mms_load_feeps, probes='1', trange=['2015-08-15', '2015-08-16'], datatype='electron'

top_intensity = 'mms1_epd_feeps_top_intensity_sensorID_*'

bottom_intensity = 'mms1_epd_feeps_bottom_intensity_sensorID_*'
  
options, top_intensity, spec=1, zlog=1
options, bottom_intensity, spec=1, zlog=1
tplot_options, 'xmargin', [20, 15]

window, 0, ysize=650
tplot, top_intensity, window=0

window, 1, ysize=650
tplot, bottom_intensity, window=1
stop

; the pitch angles for each sensor; the following splits 
; into 12 different variables (one for each sensor)
split_vec, 'mms1_epd_feeps_pitch_angle'
options, 'mms1_epd_feeps_pitch_angle_*', spec=0
options, 'mms1_epd_feeps_pitch_angle_*', 'ysubtitle', '[deg]'

window, 2, ysize=650
; plot the pitch angles for each sensor
tplot, 'mms1_epd_feeps_pitch_angle_*', window=2
stop

end