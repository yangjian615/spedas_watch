;+
; MMS EIS burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-01 12:06:38 -0700 (Fri, 01 Apr 2016) $
; $LastChangedRevision: 20701 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_eis_burst_crib.pro $
;-
probe = '1'
trange = ['2015-12-15', '2015-12-16']
prefix = 'mms'+probe
level = 'l2'

tplot_options, 'xmargin', [20, 15]

; load ExTOF burst data:
mms_load_eis, probes=probe, trange=trange, $
    datatype='extof', data_rate='brst', level=level

mms_eis_pad, probe=probe, trange=trange, datatype='extof', $
  species='ion', data_rate='brst', level=level

; plot the proton flux spectra
tdegap, prefix+'_epd_eis_brst_extof_*keV_proton_flux_omni_pad_spin', /overwrite

tplot, prefix+['_epd_eis_brst_extof_proton_flux_omni_spin', $
               '_epd_eis_brst_extof_*keV_proton_flux_omni_pad_spin']
               
; zoom in
tlimit, ['2015-12-15/10:55', '2015-12-15/11:30']
stop

; load phxtof burst data
mms_load_eis, probes=probe, trange=trange, $
    datatype='phxtof', data_rate='brst', level=level

mms_eis_pad, probe=probe, trange=trange, datatype='phxtof', $
  species='ion', data_rate='brst', level=level

; plot the spectra
tdegap, prefix+'_epd_eis_brst_phxtof_*keV_proton_flux_omni_pad_spin', /overwrite

tplot, prefix+['_epd_eis_brst_phxtof_proton_flux_omni_spin', $
    '_epd_eis_brst_phxtof_*keV_proton_flux_omni_pad_spin']

; list tplot variables that were loaded
tplot_names
stop

end