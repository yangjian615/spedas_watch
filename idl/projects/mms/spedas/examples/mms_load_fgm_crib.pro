;+
; PROCEDURE:
;         mms_load_fgm_crib
;         
; PURPOSE:
;         Crib sheet showing how to load and plot MMS AFG and DFG magnetometer data
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

;-----------------------------------------------------------------------------
; load MMS QL DFG data for MMS 1 and MMS 2
mms_load_fgm, probes=[1, 2], trange=['2015-06-22', '2015-06-24'], instrument='dfg', level='ql'

; set the left and right margins for the plots
tplot_options, 'xmargin', [15,10]

; plot the data in GSM-DMPA coordinates (GSE -> GSM transformation applied to DMPA coordinates)
tplot, ['mms1_dfg_srvy_gsm_dmpa', 'mms2_dfg_srvy_gsm_dmpa']
stop

window, 1
; plot the DFG data in GSE coordinates
tplot, ['mms1_dfg_srvy_gse_bvec', 'mms2_dfg_srvy_gse_bvec'], window=1
stop

; zoom into the main phase of the storm
tlimit, '2015-06-22/16:00', '2015-06-23/03:00', window=1
stop

;-----------------------------------------------------------------------------
; load MMS AFG data for MMS 1 and MMS 2
mms_load_fgm, probes=['1', '2'], trange=['2015-08-02', '2015-08-03'], instrument='afg', level='ql' 

window, 2
; plot the data in GSM-DMPA coordinates
tlimit, ['2015-08-02', '2015-08-03'], window=2
tplot, ['mms1_afg_srvy_gsm_dmpa', 'mms2_afg_srvy_gsm_dmpa'], window=2
stop

window, 3
; plot the data in GSE coordinates
tplot, ['mms1_afg_srvy_gse_bvec', 'mms2_afg_srvy_gse_bvec'], window=3
stop

; zoom in
tlimit, '2015-08-02/16:00', '2015-08-02/18:00', window=3
stop

;-----------------------------------------------------------------------------
; load MMS l1b DFG data for MMS 1
mms_load_fgm, probes=['1'], trange=['2015-06-22', '2015-06-24'], instrument='dfg', level='l1b'

window, 4
; plot the L1b data in BCS and OMB coordinates
tlimit, '2015-06-22', '2015-06-24', window=4
tplot, ['mms1_dfg_srvy_bcs', 'mms1_dfg_srvy_omb'], window=4
stop

; zoom in
tlimit, '2015-06-22/20:00', '2015-06-23/02:00', window=4
end