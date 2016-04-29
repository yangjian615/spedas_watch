;+
;
;     mms_wavpol_crib
;
;
;     This crib sheet demonstrates usage of the wave polarization routines
;     using MMS SCM data
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-28 09:40:43 -0700 (Thu, 28 Apr 2016) $
; $LastChangedRevision: 20958 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_wavpol_crib.pro $
;-

;; =============================
;; Select date and time interval
;; =============================

trange = ['2016-01-16/00:13', '2016-01-16/00:20']

;; =============================
;; Select probe and mode
;; =============================

sc = '4'
data_rate = 'brst'

;; Select mode ('scsrvy' for survey data rate (both slow and fast have 32 S/s), 
;                'scb' (8192 S/s) or 'schb' (16384 S/s) for burst data rate)
mode = 'scb'

;; ==============================================================
;; Get SCM data 
;; ==============================================================

mms_load_scm, probe=sc, datatype=mode, level='l2', trange=trange, data_rate=data_rate

mms_scm_name = 'mms'+sc+'_scm_acb_gse_'+mode+'_'+data_rate+'_l2

;; =======================
;; Calculate polarisation
;; =======================

twavpol,mms_scm_name

;; =====================
;; Plot calculated data
;; =====================

zlim,'*_powspec',0.0,0.0,1
tplot, mms_scm_name+['_powspec', '_degpol', '_waveangle', '_elliptict', '_helict']

end