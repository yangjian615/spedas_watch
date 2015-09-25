;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-24 09:11:30 -0700 (Thu, 24 Sep 2015) $
; $LastChangedRevision: 18914 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_feeps_crib.pro $
;-

xsize=600
ysize=850

mms_load_feeps, probes='1', trange=['2015-08-15', '2015-08-16'], datatype='electron'
mms_feeps_pad,  probe='1', datatype='electron'

zlim, ['mms1_epd_feeps_top_intensity_sensorID_3', $
    'mms1_epd_feeps_top_intensity_sensorID_4', $
    'mms1_epd_feeps_top_intensity_sensorID_5', $
    'mms1_epd_feeps_top_intensity_sensorID_11', $
    'mms1_epd_feeps_top_intensity_sensorID_12'], 0, 0, 1
ylim, ['mms1_epd_feeps_top_intensity_sensorID_3', $
    'mms1_epd_feeps_top_intensity_sensorID_4', $
    'mms1_epd_feeps_top_intensity_sensorID_5', $
    'mms1_epd_feeps_top_intensity_sensorID_11', $
    'mms1_epd_feeps_top_intensity_sensorID_12'], 0, 0, 1

options, ['mms1_epd_feeps_top_intensity_sensorID_3', $
        'mms1_epd_feeps_top_intensity_sensorID_4', $
        'mms1_epd_feeps_top_intensity_sensorID_5', $
        'mms1_epd_feeps_top_intensity_sensorID_11', $
        'mms1_epd_feeps_top_intensity_sensorID_12'], ystyle=1
        
window, 0, xsize=xsize, ysize=ysize
tplot, ['mms1_epd_feeps_top_intensity_sensorID_3_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_4_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_5_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_11_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_12_spin', $
        'mms1_epd_feeps_0-1000keV_pad_spin'],window=0


window, 1, xsize=xsize, ysize=ysize
tplot, ['mms1_epd_feeps_top_intensity_sensorID_3', $
        'mms1_epd_feeps_top_intensity_sensorID_4', $
        'mms1_epd_feeps_top_intensity_sensorID_5', $
        'mms1_epd_feeps_top_intensity_sensorID_11', $
        'mms1_epd_feeps_top_intensity_sensorID_12', $
        'mms1_epd_feeps_electron_0-1000keV_pad'], window=1


stop

;top_intensity = 'mms1_epd_feeps_top_intensity_sensorID_*'
;
;bottom_intensity = 'mms1_epd_feeps_bottom_intensity_sensorID_*'
;  
;options, top_intensity, spec=1, zlog=1
;options, bottom_intensity, spec=1, zlog=1
;tplot_options, 'xmargin', [20, 15]
;
;window, 0, ysize=650
;tplot, top_intensity, window=0
;
;window, 1, ysize=650
;tplot, bottom_intensity, window=1
;stop
;
;; the pitch angles for each sensor; the following splits 
;; into 12 different variables (one for each sensor)
;split_vec, 'mms1_epd_feeps_pitch_angle'
;options, 'mms1_epd_feeps_pitch_angle_*', spec=0
;options, 'mms1_epd_feeps_pitch_angle_*', 'ysubtitle', '[deg]'
;
;window, 2, ysize=650
;; plot the pitch angles for each sensor
;tplot, 'mms1_epd_feeps_pitch_angle_*', window=2
;stop

end