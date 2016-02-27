;+
; PROCEDURE:
;         mms_load_fgm_crib
;         
; PURPOSE:
;         Crib sheet showing how to load and plot MMS FGM data
; 
;   
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-26 13:54:39 -0800 (Fri, 26 Feb 2016) $
; $LastChangedRevision: 20222 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fgm_crib.pro $
;-

dprint, "--- Start of MMS FGM data crib sheet ---"

; load MMS FGM data for MMS 1 and MMS 2
mms_load_fgm, probes=[1, 2], trange=['2015-10-02', '2015-10-03']

; set the left and right margins for the plots
tplot_options, 'xmargin', [15,10]

; plot the data in DMPA and GSM coordinates for MMS-2
tplot, ['mms2_fgm_b_dmpa_srvy_l2', 'mms2_fgm_b_gsm_srvy_l2']

; plot dashed line at zero
timebar, 0.0, /databar, varname=['mms2_fgm_b_dmpa_srvy_l2'], linestyle=2
timebar, 0.0, /databar, varname=['mms2_fgm_b_gsm_srvy_l2'], linestyle=2
stop

; plot the FGM data in GSE coordinates and add dashed lines at zero
tplot, ['mms1_fgm_b_gse_srvy_l2', 'mms2_fgm_b_gse_srvy_l2']
timebar, 0.0, /databar, varname='mms1_fgm_b_gse_srvy_l2', linestyle=2
timebar, 0.0, /databar, varname='mms2_fgm_b_gse_srvy_l2', linestyle=2
stop

; zoom into the main phase of the storm and add dashed lines at zero
tlimit, '2015-10-02/00:00', '2015-10-02/04:00'
timebar, 0.0, /databar, varname='mms1_fgm_b_gse_srvy_l2', linestyle=2
timebar, 0.0, /databar, varname='mms2_fgm_b_gse_srvy_l2', linestyle=2
stop

; list all the variables loaded into tplot variables
tplot_names

end