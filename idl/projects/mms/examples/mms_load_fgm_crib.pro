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
;$LastChangedBy: crussell $
;$LastChangedDate: 2016-01-08 12:45:25 -0800 (Fri, 08 Jan 2016) $
;$LastChangedRevision: 19703 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fgm_crib.pro $
;-

;-----------------------------------------------------------------------------
 
dprint, "--- Start of MMS FGM data crib sheet ---"

; load MMS QL DFG data for MMS 1 and MMS 2
tr=time_double(['2015-06-22', '2015-06-23'])
mms_load_dfg, probes=[1, 2], trange=tr, level='ql'

; set the left and right margins for the plots
tplot_options, 'xmargin', [15,10]

; add a dashed line at zero
store_data, 'dline0', data={x:tr, y:[0,0]}
options, 'dline0', linestyle=2

; plot the data in GSM-DMPA coordinates (GSE -> GSM transformation applied to DMPA coordinates)
tplot, ['mms1_dfg_srvy_gsm_dmpa', 'mms2_dfg_srvy_gsm_dmpa']
; plot dashed line at zero
tplot_panel, oplotvar='dline0', panel=0
tplot_panel, oplotvar='dline0', panel=1
stop

; plot the DFG data in GSE coordinates and dashed line at zero
tplot, ['mms1_dfg_srvy_gse_bvec', 'mms2_dfg_srvy_gse_bvec']
tplot_panel, oplotvar='dline0', panel=0
tplot_panel, oplotvar='dline0', panel=1
stop

; zoom into the main phase of the storm and dashed line at zero
tlimit, '2015-06-22/16:00', '2015-06-23/00:00'
tplot_panel, oplotvar='dline0', panel=0
tplot_panel, oplotvar='dline0', panel=1
stop

;-----------------------------------------------------------------------------
; set time frame; this will be used for all subsequent load data routines unless the
; user specifies the time range keyword or calls timespan again
timespan, '2015-08-02',1

; load MMS AFG data for MMS 1 and MMS 2
mms_load_afg, probes=['1', '2'],  level='ql' 

; new time frame so need to modify dashed line
tr=timerange()
store_data, 'dline0', data={x:tr, y:[0,0]}
options, 'dline0', linestyle=2

; plot the data in GSM-DMPA coordinates and dashed line at zero
tplot, ['mms1_afg_srvy_gsm_dmpa', 'mms2_afg_srvy_gsm_dmpa']
tplot_panel, oplotvar='dline0', panel=0
tplot_panel, oplotvar='dline0', panel=1
stop

; plot the data in GSE coordinates
; add a title
tplot_options, 'title', 'MMS Probes 1 and 2, AFG Survey Data'
; use wildcard '*'
tplot, 'mms*_afg_srvy_gse_bvec'      ;, 'mms2_afg_srvy_gse_bvec']
for i=0,1 do tplot_panel, oplotvar='dline0', panel=i[0]
stop

; zoom in
tlimit, '2015-08-02/16:00', '2015-08-02/18:00'
for i=0,1 do tplot_panel, oplotvar='dline0', panel=i[0]
stop

;-----------------------------------------------------------------------------
; load MMS l1b DFG data for MMS 1
timespan, '2015-08-02',1
mms_load_dfg, probes=['1'], level='l1b'

; create a new window for these plots, the previous plots will remain displayed
window, 1
; plot the L1b data in BCS and OMB coordinates
tplot_options, 'title', 'MMS Probe 1, DFG L1b Survey Data'
tplot, ['mms1_dfg_srvy_bcs', 'mms1_dfg_srvy_omb'], window=1
for i=0,1 do tplot_panel, oplotvar='dline0', panel=i[0]
stop

; zoom in
tlimit, '2015-08-02/16:00', '2015-08-02/18:00', window=1
for i=0,1 do tplot_panel, oplotvar='dline0', panel=i[0]
stop

; list all the variables loaded into tplot variables
tplot_names

; clear tplot title
tplot_options, 'title', ''

end