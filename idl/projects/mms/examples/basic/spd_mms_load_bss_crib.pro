;+
; spd_mms_load_bss_crib  
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; See also "spd_mms_load_bss", "mms_load_bss", and "mms_load_bss_crib".
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-13 08:23:26 -0700 (Wed, 13 Apr 2016) $
; $LastChangedRevision: 20794 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/spd_mms_load_bss_crib.pro $
;-


; set time range 
timespan, '2015-10-01', 1, /day

; get data availability for burst and survey data (note that the labels flag
; is set so that the display bars will be labeled)
spd_mms_load_bss, datatype=['fast', 'burst'], /include_labels

; now plot bars with some data 
mms_load_fgm, probe=3, data_rate=['srvy', 'brst'], level='l2'

; degap the mag data to avoid tplot connecting the lines between
; burst segments
tdegap, 'mms3_fgm_b_gse_brst_l2_bvec', /overwrite


tplot,['mms_bss_fast','mms_bss_burst', 'mms3_fgm_b_gse_srvy_l2_bvec', 'mms3_fgm_b_gse_brst_l2_bvec']
stop

; Get all BSS data types (Fast, Burst, Status, and FOM)
spd_mms_load_bss, /include_labels, datatype=['fast', 'burst', 'fom', 'status']

; plot bss bars and fom at top of plot
tplot,['mms_bss_fast','mms_bss_burst','mms_bss_status', 'mms_bss_fom', $
       'mms3_fgm_b_gse_srvy_l2_bvec', 'mms3_fgm_b_gse_brst_l2_bvec']
stop

end
