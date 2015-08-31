;+
; MMS EIS burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-19 10:16:17 -0700 (Wed, 19 Aug 2015) $
; $LastChangedRevision: 18525 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_eis_crib.pro $
;-

tplot_options, 'xmargin', [20, 15]

; load ExTOF burst data:
mms_load_eis, probes='1', trange=['2015-08-23', '2015-08-24'], datatype='extof', data_rate='brst', level='l1b'

; plot the proton flux spectra
ylim, 'mms1_epd_eis_extof_proton_flux_t?', 30, 500, 1
zlim, 'mms1_epd_eis_extof_proton_flux_t?', 0, 0, 1
tplot, 'mms1_epd_eis_extof_proton_flux_t?'
stop

; load phxtof burst data
mms_load_eis, probes='1', trange=['2015-08-23', '2015-08-24'], datatype='phxtof', data_rate='brst', level='l1a'

; plot the spectra
ylim, 'mms1_epd_eis_phxtof_t?', 10, 50, 1
zlim, 'mms1_epd_eis_phxtof_t?', 0, 0, 1 
tplot, 'mms1_epd_eis_phxtof_t?'
stop

; list tplot variables that were loaded
tplot_names

end