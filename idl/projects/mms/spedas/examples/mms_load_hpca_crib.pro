;+
; MMS HPCA crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-07-31 16:30:05 -0700 (Fri, 31 Jul 2015) $
; $LastChangedRevision: 18345 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_hpca_crib.pro $
;-

mms_load_hpca, probes='1', trange=['2015-07-22', '2015-07-23'], datatype='moments'

; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
        'mms1_hpca_oplus_number_density', $
        'mms1_hpca_heplus_number_density']

window, 1
; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
        'mms1_hpca_oplus_scalar_temperature', $
        'mms1_hpca_heplus_scalar_temperature'], window=1
stop

window, 2
tplot_options, 'colors', [2, 4, 6]
; show H+, O+ and He+ flow velocity
tplot, ['mms1_hpca_hplus_ion_bulk_velocity', $
        'mms1_hpca_oplus_ion_bulk_velocity', $
        'mms1_hpca_heplus_ion_bulk_velocity'], window=2
       
stop

mms_load_hpca, probes='1', trange=['2015-06-22', '2015-06-23'], datatype='ion', varformat='*_RF_corrected'

rf_corrected = ['mms1_hpca_hplus_RF_corrected', $
        'mms1_hpca_oplus_RF_corrected', $
        'mms1_hpca_heplus_RF_corrected']
        
options, rf_corrected, 'spec', 1
options, rf_corrected, 'no_interp', 1
ylim, rf_corrected, 1, 40.,1
zlim, rf_corrected, .1, 10000.,1
        
; show spectra for H+, O+ and He+
window, 3
tplot, rf_corrected, window=3

end