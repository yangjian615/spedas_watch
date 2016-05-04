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
;$LastChangedDate: 2016-05-03 08:52:33 -0700 (Tue, 03 May 2016) $
;$LastChangedRevision: 21000 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fgm_burst_crib.pro $
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
stop

; load the FGM data, along with the ephemeris data stored in the FGM files
mms_load_fgm, probes=3, trange=['2015-10-15/6:45', '2015-10-15/7:20'], data_rate='brst', /get_fgm_ephemeris

; plot the FGM data, along with position in GSM coordinates
tplot, ['mms3_fgm_b_gsm_brst_l2_bvec', 'mms3_fgm_r_gsm_brst_l2_vec']
stop

; delete the data from previous loads
del_data, '*'

; load the FGM data without splitting the variables
mms_load_fgm, probe=1, trange=['2015-10-15/6:45', '2015-10-15/7:20'], data_rate='brst', /get_fgm_ephemeris, /no_split_vars

; since the variables aren't split, they can't be used by routines
; in SPEDAS that expect vectors to be stored as vectors
tplot, ['mms1_fgm_b_gsm_brst_l2', 'mms1_fgm_r_gsm_brst_l2']

end