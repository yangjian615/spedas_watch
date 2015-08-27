;+
; MMS HPCA burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-26 09:27:54 -0700 (Wed, 26 Aug 2015) $
; $LastChangedRevision: 18625 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_hpca_brst_crib.pro $
;-

mms_load_hpca, probes='1', trange=['2015-08-20', '2015-08-21'], datatype='moments', data_rate='brst'

; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
  'mms1_hpca_oplus_number_density', $
  'mms1_hpca_heplus_number_density']
stop

; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
  'mms1_hpca_oplus_scalar_temperature', $
  'mms1_hpca_heplus_scalar_temperature']
stop

; set the colors
tplot_options, 'colors', [2, 4, 6]
; set some reasonable margins
tplot_options, 'xmargin', [20, 15]
; show H+, O+ and He+ flow velocity
tplot, 'mms1_hpca_*_ion_bulk_velocity'
tplot, ['mms1_hpca_hplus_ion_bulk_velocity', $
  'mms1_hpca_oplus_ion_bulk_velocity', $
  'mms1_hpca_heplus_ion_bulk_velocity']
stop

; use wild card for and plot all ion bulk velocities
tplot, 'mms1_hpca_*_ion_bulk_velocity'
stop

mms_load_hpca, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='rf_corr', data_rate='brst'

rf_corrected = ['mms1_hpca_hplus_RF_corrected', $
  'mms1_hpca_oplus_RF_corrected', $
  'mms1_hpca_heplus_RF_corrected', $
  'mms1_hpca_heplusplus_RF_corrected']

; show spectra for H+, O+ and He+, He++
tplot, rf_corrected

end