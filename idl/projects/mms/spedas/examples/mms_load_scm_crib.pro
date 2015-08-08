;+
; MMS SCM crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-07 13:22:37 -0700 (Fri, 07 Aug 2015) $
; $LastChangedRevision: 18435 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_scm_crib.pro $
;-

; download SCM data for 8/2/2015
mms_load_scm, trange=['2015-08-02', '2015-08-03'], probes='1', level='l1b', data_rate='fast', datatype='scf'

options, 'mms1_scm_scf_scm123', colors=[2, 4, 6]
options, 'mms1_scm_scf_scm123', labels=['X', 'Y', 'Z']
options, 'mms1_scm_scf_scm123', labflag=-1

window, 0, ysize=650
tplot_options, 'xmargin', [15, 15]

; plot the SCM data
tplot, 'mms1_scm_scf_scm123'

; zoom into a time in the afternoon
tlimit, ['2015-08-02/16:00', '2015-08-02/18:00']

; calculate the dynamic power spectra
tdpwrspc, 'mms1_scm_scf_scm123', nboxpoints=512

options, 'mms1_scm_scf_scm123_?_dpwrspc', 'ytitle', 'MMS1'
options, 'mms1_scm_scf_scm123_x_dpwrspc', 'ysubtitle', 'dynamic power!CX!C[Hz]'
options, 'mms1_scm_scf_scm123_y_dpwrspc', 'ysubtitle', 'dynamic power!CY!C[Hz]'
options, 'mms1_scm_scf_scm123_z_dpwrspc', 'ysubtitle', 'dynamic power!CZ!C[Hz]'

tplot, ['mms1_scm_scf_scm123', 'mms1_scm_scf_scm123_?_dpwrspc']
stop
end