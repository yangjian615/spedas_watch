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
; $LastChangedDate: 2016-04-01 12:00:15 -0700 (Fri, 01 Apr 2016) $
; $LastChangedRevision: 20700 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fgm_crib.pro $
;-

; load MMS FGM data for MMS 1 and MMS 2
mms_load_fgm, probes=[1, 2], trange=['2016-01-20', '2016-01-21']

; set the left and right margins for the plots
tplot_options, 'xmargin', [15,10]

; plot the data in GSM coordinates for MMS-2
tplot, 'mms2_fgm_b_gsm_srvy_l2_bvec'

; plot dashed line at zero
timebar, 0.0, /databar, varname='mms2_fgm_b_gsm_srvy_l2_bvec', linestyle=2
stop

; zoom in
tlimit, '2016-01-20/03:00', '2016-01-20/04:00'
stop

; list all the variables loaded into tplot variables
tplot_names

end