;+
; MMS spacecraft formation crib sheet
;
;  This script shows how to create 3D plots of the S/C formation
;    at a given time
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-23 20:01:21 -0800 (Tue, 23 Feb 2016) $
; $LastChangedRevision: 20129 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_formation_crib.pro $
;-

time = '2016-01-20/13:05'

timespan, time, 1, /min

; load the position data, only one data point
mms_load_mec, probes=[1, 2, 3, 4], varformat='*_r_gsm', cdf_records=1

tplot3d, 'mms1_mec_r_gsm', SYM_INDEX=3, SYM_THICK=10, SYM_COLOR=[255, 0, 0], sym_size=1
tplot3d, 'mms2_mec_r_gsm', SYM_INDEX=3, SYM_THICK=10, SYM_COLOR=[0, 255, 0], /over, sym_size=1
tplot3d, 'mms3_mec_r_gsm', SYM_INDEX=3, SYM_THICK=10, SYM_COLOR=[0, 0, 255], /over, sym_size=1
tplot3d, 'mms4_mec_r_gsm', SYM_INDEX=3, SYM_THICK=10, SYM_COLOR=[255, 255, 0], /over, sym_size=1
end