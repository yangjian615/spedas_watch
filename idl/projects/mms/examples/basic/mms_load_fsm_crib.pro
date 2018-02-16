;+
; PROCEDURE:
;         mms_load_fsm_crib
;
; PURPOSE:
;         Crib sheet showing how to load and plot L3 FSM data
;
;
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $
;-


timespan, '2017-07-11/22:33:30', 60, /seconds

mms_load_fsm, probe=4, /time_clip

tplot, ['mms4_fsm_b_gse_brst_l3', 'mms4_fsm_b_mag_brst_l3']

stop
end