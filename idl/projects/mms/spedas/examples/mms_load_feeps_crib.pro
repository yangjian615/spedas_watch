;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-10-06 12:44:17 -0700 (Tue, 06 Oct 2015) $
; $LastChangedRevision: 19014 $
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

tplot, ['mms1_epd_feeps_top_intensity_sensorID_3', $
  'mms1_epd_feeps_top_intensity_sensorID_4', $
  'mms1_epd_feeps_top_intensity_sensorID_5', $
  'mms1_epd_feeps_top_intensity_sensorID_11', $
  'mms1_epd_feeps_top_intensity_sensorID_12', $
  'mms1_epd_feeps_electron_0-1000keV_pad'], window=0
stop

window, 1, xsize=xsize, ysize=ysize
tplot, ['mms1_epd_feeps_top_intensity_sensorID_3_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_4_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_5_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_11_spin', $
        'mms1_epd_feeps_top_intensity_sensorID_12_spin', $
        'mms1_epd_feeps_0-1000keV_pad_spin'],window=1
stop

end