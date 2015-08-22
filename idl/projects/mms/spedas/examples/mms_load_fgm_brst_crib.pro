;+
; PROCEDURE:
;         mms_load_fgm_brst_crib
;
; PURPOSE:
;         Crib sheet showing how to load and plot MMS magnetometer data in burst mode (for afg and dfg) 
;
; NOTES:
;         1) Updated to use the MMS web services API, 6/12/2015
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-04 15:49:48 -0700 (Tue, 04 Aug 2015) $
;$LastChangedRevision: 18396 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_fgm_crib.pro $
;-
;----------------------------------------------------------------------------
; load MMS AFG burst data for MMS 1 
mms_load_fgm, probes=['1'], trange=['2015-07-28','2015-07-29'], instrument='afg', data_rate='brst', level='l1b'
tplot_names

window, 1
tlimit, '2015-07-28','2015-07-29', window=1
tplot, ['mms1_afg_brst_bcs','mms1_afg_brst_omb']
stop

; zoom in 
tlimit, '2015-07-28/14:00','2015-07-28/16:00', window=1
stop 

; zoom in some more 
tlimit, '2015-07-28/15:40','2015-07-28/16:00', window=1
stop

;----------------------------------------------------------------------------
; do the same for DFG burst data for MMS 1
mms_load_fgm, probes=['1'], trange=['2015-07-28','2015-07-29'], instrument='dfg', data_rate='brst', level='l1b'

window, 2
tlimit, '2015-07-28','2015-07-29', window=2
tplot, ['mms1_dfg_brst_bcs','mms1_dfg_brst_omb']
stop

; show both afg and dfg with attitude data
tplot, ['mms1_afg_brst_bcs','mms1_afg_brst_omg','mms1_dfg_brst_bcs','mms1_dfg_brst_omb','mms1_defatt_spinras','mms1_defatt_spindec']
stop

;----------------------------------------------------------------------------
; load DFG burst data for all MMS probse
mms_load_fgm, probes=['1','2','3','4'], trange=['2015-07-28','2015-07-29'], instrument='dfg', data_rate='brst', level='l1b'

window, 3
tlimit, '2015-07-28','2015-07-29', window=3
tplot, ['mms1_dfg_brst_bcs','mms2_dfg_brst_bcs','mms3_dfg_brst_bcs','mms4_dfg_brst_bcs']
stop

end