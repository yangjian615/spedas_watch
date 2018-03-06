;+
; PROCEDURE:
;         mms_load_fsm_crib
;
; PURPOSE:
;         Crib sheet showing how to load and plot L3 FSM data
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-03-01 15:04:33 -0800 (Thu, 01 Mar 2018) $
; $LastChangedRevision: 24816 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fsm_crib.pro $
;-


timespan, '2017-07-11/22:33:30', 60, /seconds

mms_load_fsm, probe=4, /time_clip

tplot, ['mms4_fsm_b_gse_brst_l3', 'mms4_fsm_b_mag_brst_l3']

stop
end