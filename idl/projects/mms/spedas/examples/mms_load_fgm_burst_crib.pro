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
;$LastChangedDate: 2015-10-07 13:18:23 -0700 (Wed, 07 Oct 2015) $
;$LastChangedRevision: 19028 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_fgm_burst_crib.pro $
;-
;----------------------------------------------------------------------------

dprint, "--- Start of MMS FGM burst data crib sheet ---"

; set the time span
timespan, '2015-08-15', 1

; load MMS AFG burst data for MMS 1 
mms_load_fgm, probes=['1'], instrument='afg', data_rate='brst', level='ql'

tplot, ['mms1_afg_brst_gse_bvec', 'mms1_afg_brst_gse_btot']
stop

; zoom in to region of interest 
tlimit, '2015-08-15/12:45','2015-08-15/13:15', window=1
stop

;----------------------------------------------------------------------------
; do the same for DFG burst data for probes MMS 1 and 2 
; Note the time frame keyword is used
mms_load_fgm, probes=['1','2'], trange=['2015-08-15/00:00','2015-08-15/00:00'], instrument='dfg', data_rate='brst', level='ql'

; add a title
tplot, ['mms1_dfg_brst_gse_bvec','mms2_dfg_brst_gse_bvec']
stop

; zoom in and show both afg and dfg with attitude data and add a title
tlimit, '2015-08-15/12:45','2015-08-15/13:15'

; add a title
tplot_options, 'title', 'MMS1 FGM Bvec, Btotal, Position, and Attitude'
tplot, ['mms1_dfg_brst_gse_bvec','mms1_afg_brst_gse_bvec','mms1_ql_pos_gse','mms1_ql_RADec_gse']
stop

;----------------------------------------------------------------------------
; load DFG burst data for the other MMS probes
mms_load_fgm, probes=['3','4'], instrument='dfg', data_rate='brst', level='ql'

; new window specified so that previous plot window will be preserved.
window, 2
tlimit, '2015-08-15/12:45','2015-08-15/13:15', window=2
tplot_options, 'title', 'MMS FGM data for all Probes'
; tplot accepts wild cards
tplot, 'mms*_dfg_brst_gse_bvec'
stop

;-----------------------------------------------------------------------------
; combine the bvector and btotal tplot variables - this pseudo variable 
; is for plotting purposes
pr='mms1'
; tplot variables accept constructed strings
store_data, pr+'_combined_fgm', data=[pr+'_dfg_brst_gse_btot',pr+'_dfg_brst_gse_bvec']
tplot, pr+'_combined_fgm'
stop

; check out list of all the tplot variables that were loaded
tplot_names

dprint, "--- End of MMS FGM burst data crib sheet ---"

end