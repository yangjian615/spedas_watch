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
;$LastChangedDate: 2015-09-09 08:35:37 -0700 (Wed, 09 Sep 2015) $
;$LastChangedRevision: 18738 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_fgm_crib.pro $
;-

;-----------------------------------------------------------------------------
 
dprint, "--- Start of MMS FGM data crib sheet ---"

; load MMS QL DFG data for MMS 1 and MMS 2
mms_load_dfg, probes=[1, 2], trange=['2015-06-22', '2015-06-23'], level='ql'

; set the left and right margins for the plots
tplot_options, 'xmargin', [15,10]

; plot the data in GSM-DMPA coordinates (GSE -> GSM transformation applied to DMPA coordinates)
tplot, ['mms1_dfg_srvy_gsm_dmpa', 'mms2_dfg_srvy_gsm_dmpa']
stop

; plot the DFG data in GSE coordinates
tplot, ['mms1_dfg_srvy_gse_bvec', 'mms2_dfg_srvy_gse_bvec']
stop

; zoom into the main phase of the storm
tlimit, '2015-06-22/16:00', '2015-06-23/00:00'
stop

;-----------------------------------------------------------------------------
; set time frame; this will be used for all subsequent load data routines unless the
; user specifies the time range keyword or calls timespan again
timespan, '2015-08-02',1

; load MMS AFG data for MMS 1 and MMS 2
mms_load_afg, probes=['1', '2'],  level='ql' 

; plot the data in GSM-DMPA coordinates
tplot, ['mms1_afg_srvy_gsm_dmpa', 'mms2_afg_srvy_gsm_dmpa']
stop

; plot the data in GSE coordinates
; add a title
tplot_options, 'title', 'MMS Probes 1 and 2, AFG Survey Data'
tplot, 'mms*_afg_srvy_gse_bvec'      ;, 'mms2_afg_srvy_gse_bvec']
stop

; zoom in
tlimit, '2015-08-02/16:00', '2015-08-02/18:00'
stop

;-----------------------------------------------------------------------------
; load MMS l1b DFG data for MMS 1
mms_load_dfg, probes=['1'], level='l1b'

; create a new window for these plots, the previous plots will remain displayed
window, 1
; plot the L1b data in BCS and OMB coordinates
tplot_options, 'title', 'MMS Probe 1, DFG L1b Survey Data'
tplot, ['mms1_dfg_srvy_bcs', 'mms1_dfg_srvy_omb'], window=1
stop

; zoom in
tlimit, '2015-08-02/16:00', '2015-08-02/18:00', window=1
stop

; list all the variables loaded into tplot variables
tplot_names

end