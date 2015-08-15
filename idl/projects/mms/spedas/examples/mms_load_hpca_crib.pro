;+
; MMS HPCA crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-12 14:36:27 -0700 (Wed, 12 Aug 2015) $
; $LastChangedRevision: 18464 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_hpca_crib.pro $
;-

; set some reasonable margins
tplot_options, 'xmargin', [20, 15]

mms_load_hpca, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='moments'

; there's a gap in the data in the morning of 7/31 ~(0530UT-1330UT)
tdegap, tnames(), /overwrite

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

mms_load_hpca, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='ion', level='l1b'

rf_corrected = ['mms1_hpca_h+_rf_corr_counts_elev_0-180', $
                'mms1_hpca_o+_rf_corr_counts_elev_0-180', $ 
                'mms1_hpca_he++_rf_corr_counts_elev_0-180']
        
; show spectra for H+, O+ and He+
window, 3, ysize=600
tplot, rf_corrected, window=3

end