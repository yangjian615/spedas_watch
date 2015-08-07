;+
; MMS SCM crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-05 13:44:35 -0700 (Wed, 05 Aug 2015) $
; $LastChangedRevision: 18404 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_scm_crib.pro $
;-

; download the first 4 hours of SCM data on 6/15/15
mms_load_scm, trange=['2015-06-15', '2015-06-15/4:00'], probes='1', level='l2'

options, 'mms1_scm_sc128_gse', colors=[2, 4, 6]
options, 'mms1_scm_sc128_gse', labels=['X', 'Y', 'Z']
options, 'mms1_scm_sc128_gse', labflag=-1

; plot the SCM data for the first 4 hours
tplot, 'mms1_scm_sc128_gse'
stop

; zoom into a time of 3:36-3:42 UT
tlimit, ['2015-06-15/3:36', '2015-06-15/3:42']
stop

; calculate the dynamic power spectra
tdpwrspc, 'mms1_scm_sc128_gse', nboxpoints=512
window, 1
tplot, 'mms1_scm_sc128_gse_?_*', window=1
stop
end