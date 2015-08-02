;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-07-31 13:05:26 -0700 (Fri, 31 Jul 2015) $
; $LastChangedRevision: 18329 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_feeps_crib.pro $
;-

mms_load_feeps, probes='1', trange=['2015-07-22', '2015-07-23'], datatype='electron'

top_cpa = ['mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_3', $
  'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_4', $
  'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_5', $
  'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_11', $
  'mms1_epd_feeps_TOP_counts_per_accumulation_sensorID_12']

bottom_cpa = ['mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_3', $
  'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_4', $
  'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_5', $
  'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_11', $
  'mms1_epd_feeps_BOTTOM_counts_per_accumulation_sensorID_12']
  
options, top_cpa, spec=1, zlog=1, yrange=[1, 10]
options, bottom_cpa, spec=1, zlog=1, yrange=[1, 10]

tplot, top_cpa, title='Top sensors'

window, 1
tplot, bottom_cpa, window=1, title='Bottom sensors'
stop

; the pitch angles for each sensor; the following splits 
; into 12 different variables (one for each sensor)
split_vec, 'mms1_epd_feeps__pitchAngle'
options, 'mms1_epd_feeps__pitchAngle_?', spec=0
options, 'mms1_epd_feeps__pitchAngle_?', 'ysubtitle', '[deg]'

window, 2, ysize=650
; plot the pitch angles for each sensor
tplot, 'mms1_epd_feeps__pitchAngle_?', title='FEEPS pitch angles', window=2
stop

end