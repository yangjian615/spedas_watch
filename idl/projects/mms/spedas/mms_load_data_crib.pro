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
;$LastChangedDate: 2015-06-24 14:56:28 -0700 (Wed, 24 Jun 2015) $
;$LastChangedRevision: 17962 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data_crib.pro $
;-

;-----------------------------------------------------------------------------
; load MMS QL DFG data for MMS 1 and MMS 2
mms_load_data, probes=['1', '2'], trange=['2015-06-22', '2015-06-24'], instrument='dfg', datatype='*', level='ql'

; plot the data in DMPA coordinates
tplot, ['mms1_dfg_srvy_dmpa_btot', 'mms1_dfg_srvy_dmpa_bvec']
stop

; plot the data in GSM-DMPA coordinates (GSE -> GSM transformation applied to DMPA coordinates)
tplot, ['mms1_dfg_srvy_gsm_dmpa', 'mms2_dfg_srvy_gsm_dmpa']
stop

; plot the DFG data for MMS 1 in GSE coordinates, along with the spacecraft position
tplot, ['mms1_dfg_srvy_gse', 'mms1_ql_pos_gsm']
stop

; zoom into the main phase of the storm
tplot, ['mms1_dfg_srvy_gse', 'mms2_dfg_srvy_gse'], trange=['2015-06-22/16:00', '2015-06-23/03:00']
stop

;-----------------------------------------------------------------------------
; load MMS AFG data for MMS 1 and MMS 2
mms_load_data, probes=['1', '2'], trange=['2015-06-22', '2015-06-24'], instrument='afg', level='ql' 

; plot the data in DMPA coordinates
tplot, ['mms1_afg_srvy_dmpa_bvec', 'mms2_afg_srvy_dmpa_bvec']
stop

; plot the data in GSE coordinates
tplot, ['mms1_afg_srvy_gse', 'mms2_afg_srvy_gse']
stop

; zoom into the main phase of the storm
tplot, ['mms1_afg_srvy_gse', 'mms2_afg_srvy_gse'], trange=['2015-06-22/16:00', '2015-06-23/03:00']
stop

; plot the spacecraft positions for all 4 MMS spacecraft
tplot, 'mms?_ql_pos_gsm'
stop

;-----------------------------------------------------------------------------
; load MMS l1b DFG data for MMS 1
mms_load_data, probes=['1'], trange=['2015-06-22', '2015-06-24'], instrument='dfg', datatype='*', level='l1b'

; plot the L1b data in BCS and OMB coordinates
tplot, ['mms1_dfg_srvy_bcs', 'mms1_dfg_srvy_omb']
end