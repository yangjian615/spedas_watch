;+
; PROCEDURE:
;         mms_load_ql_data_crib
;         
; PURPOSE:
;         Crib sheet showing how to load and plot MMS AFG and DFG magnetometer data
; 
; NOTES:
;         Updated to use the MMS web services API, 6/12/2015
;   
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-06-15 09:56:30 -0700 (Mon, 15 Jun 2015) $
;$LastChangedRevision: 17876 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data_crib.pro $
;-

;-----------------------------------------------------------------------------
; load MMS QL DFG data for MMS 1 and MMS 2
mms_load_data, probes=['1', '2'], trange=['2015-03-18', '2015-03-19'], instrument='dfg', datatype='*', level='ql'

; plot the data in DMPA coordinates
tplot, ['mms1_dfg_srvy_dmpa_btot', 'mms1_dfg_srvy_dmpa_bvec']
stop

; plot the data in GSM-DMPA coordinates (GSE -> GSM transformation applied to DMPA coordinates)
tplot, ['mms1_dfg_srvy_gsm_dmpa', 'mms2_dfg_srvy_gsm_dmpa']
stop

; plot the DFG data for MMS 1 along with the spacecraft position
tplot, ['mms1_dfg_srvy_gsm_dmpa', 'mms1_ql_pos_gsm']
stop

;-----------------------------------------------------------------------------
; load MMS AFG data for MMS 3 and MMS 4
mms_load_data, probes=['3', '4'], trange=['2015-03-18', '2015-03-19'], instrument='afg', level='ql' 

; plot the data in DMPA coordinates
tplot, ['mms3_afg_srvy_dmpa_bvec', 'mms4_afg_srvy_dmpa_bvec']
stop

; plot the data in GSM-DMPA coordinates
tplot, ['mms3_afg_srvy_gsm_dmpa', 'mms4_afg_srvy_gsm_dmpa']
stop

; plot the spacecraft positions for all 4 MMS spacecraft
tplot, 'mms?_ql_pos_gsm'
stop

;-----------------------------------------------------------------------------
; load MMS l1b DFG data for MMS 1
mms_load_data, probes=['1'], trange=['2015-03-18', '2015-03-19'], instrument='dfg', datatype='*', level='l1b'

; plot the L1b data in BCS and OMB coordinates
tplot, ['mms1_dfg_srvy_bcs', 'mms1_dfg_srvy_omb']
end