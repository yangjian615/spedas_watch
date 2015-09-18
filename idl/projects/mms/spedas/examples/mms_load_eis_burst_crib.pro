;+
; MMS EIS burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-17 13:05:04 -0700 (Thu, 17 Sep 2015) $
; $LastChangedRevision: 18826 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_eis_burst_crib.pro $
;-
probe = '1'
trange = ['2015-08-23', '2015-08-24']
prefix = 'mms'+probe

tplot_options, 'xmargin', [20, 15]

; load ExTOF burst data:
mms_load_eis, probes=probe, trange=trange, $
    datatype='extof', data_rate='brst', level='l1b'

mms_eis_pad, probe=probe, trange=trange, datatype='extof', species='ion'

; plot the proton flux spectra
ylim, prefix+'_epd_eis_extof_proton_flux_omni_spin', 30, 500, 1
zlim, prefix+'_epd_eis_extof_proton_flux_omni_spin', 0, 0, 1

tplot, prefix+['_epd_eis_extof_proton_flux_omni_spin', $
               '_epd_eis_extof_*keV_proton_flux_pad_spin']
stop

; load phxtof burst data
mms_load_eis, probes=probe, trange=trange, $
    datatype='phxtof', data_rate='brst', level='l1b'

mms_eis_pad, probe=probe, trange=trange, datatype='phxtof', species='ion'

; plot the spectra
ylim, prefix+'_epd_eis_phxtof_proton_flux_omni_spin', 10, 50, 1
zlim, prefix+'_epd_eis_phxtof_proton_flux_omni_spin', 0, 0, 1 

tplot, prefix+['_epd_eis_phxtof_proton_flux_omni_spin', $
    '_epd_eis_phxtof_*keV_proton_flux_pad_spin']

; list tplot variables that were loaded
tplot_names
stop

end