;+
; PROCEDURE:
;         mms_load_fgm_brst_crib
;
; PURPOSE:
;         Crib sheet showing how to load and plot MMS magnetometer data in burst mode 
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-03 14:16:35 -0800 (Thu, 03 Mar 2016) $
;$LastChangedRevision: 20319 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fgm_burst_crib.pro $
;-

; set the time span
timespan, '2015-10-15', 1

; load MMS FGM burst data for all spacecraft
; only grab the latest version of the CDF
mms_load_fgm, probes=[1, 2, 3, 4], data_rate='brst', level='l2', /latest_version, cdf_filenames = files

; plot the data in GSE coordinates for all spacecraft
tplot, 'mms?_fgm_b_gse_brst_l2_bvec'
stop

; zoom into the burst interval
tlimit, ['2015-10-15/6:45', '2015-10-15/7:20']
stop

; print the filenames of the files used to load the data
; note only the latest CDF version used for each spacecraft
print, files

end