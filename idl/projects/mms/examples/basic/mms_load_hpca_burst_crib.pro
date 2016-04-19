;+
; MMS HPCA burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-18 16:04:20 -0700 (Mon, 18 Apr 2016) $
; $LastChangedRevision: 20853 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_hpca_burst_crib.pro $
;-

; zoom into the burst interval
timespan, '2015-12-15/11:20', 20, /min

mms_load_hpca, probes='1', datatype='moments', data_rate='brst', level='l2'

window, 1
; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
  'mms1_hpca_oplus_number_density', $
  'mms1_hpca_heplus_number_density'], window=1
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
stop

mms_load_hpca, probes='1', datatype='ion', data_rate='brst', level='l2'
; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid
mms_hpca_calc_anodes, anode=[13, 14], probe=pid
mms_hpca_calc_anodes, anode=[0, 15], probe=pid

flux_burst = ['mms1_hpca_hplus_flux_anodes_0_15', $
  'mms1_hpca_oplus_flux_anodes_0_15', $
  'mms1_hpca_heplus_flux_anodes_0_15', $
  'mms1_hpca_heplusplus_flux_anodes_0_15']

; don't interpolate through the gaps
tdegap, flux_burst, /overwrite

; show spectra for H+, O+ and He+, He++
tplot, flux_burst
stop

; sum over FOV's 
mms_hpca_calc_anodes, fov=[0, 360], probe='1'
mms_hpca_calc_anodes, fov=[0, 180], probe='1'
mms_hpca_calc_anodes, fov=[180, 360], probe='1'

; don't interpolate through the gaps
tdegap, 'mms1_hpca_*plus_flux_elev_*', /overwrite

; plot each view
tplot, ['mms1_hpca_hplus_flux_elev_*']  
stop

; plot each species
tplot, ['mms1_hpca_*plus_flux_elev_0-360']
stop
end