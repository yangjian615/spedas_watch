;+
; MMS FPI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-07-31 13:05:26 -0700 (Fri, 31 Jul 2015) $
; $LastChangedRevision: 18329 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_fpi_crib.pro $
;-

mms_load_fpi, probes='3', trange=['2015-06-22', '2015-06-23']

; NOTE: though we loaded the data file for MMS3, the CDFs seem
; to be mislabeled as MMS1 - leading to tplot variable names that
; start with "mms1"
electron_espec = ['mms1_fpi_eEnergySpectr_pX', $
                  'mms1_fpi_eEnergySpectr_pY', $
                  'mms1_fpi_eEnergySpectr_pZ']
                  
ion_espec = ['mms1_fpi_iEnergySpectr_pX', $
             'mms1_fpi_iEnergySpectr_pY', $
             'mms1_fpi_iEnergySpectr_pZ']

options, electron_espec, spec=1, zlog=1
options, ion_espec, spec=1, zlog=1

tplot, electron_espec

window, 1
tplot, ion_espec, window=1
stop

window, 2
; plot density, parallel and perpendicular temperature for DES
tplot, ['mms1_fpi_DESnumberDensity', 'mms1_fpi_DEStempPara', $
        'mms1_fpi_DEStempPerp'], window=2
stop

window, 3
; plot density, parallel and perpendicular temperature for DIS
tplot, ['mms1_fpi_DISnumberDensity', 'mms1_fpi_DIStempPara', $
        'mms1_fpi_DIStempPerp'], window=3
stop

window, 4
; combine the bulk ion velocity into a single tplot variable
join_vec, ['mms1_fpi_iBulkV_X_DSC', 'mms1_fpi_iBulkV_Y_DSC', $
           'mms1_fpi_iBulkV_Z_DSC'], 'mms1_fpi_iBulkV_DSC'

; set some options for pretty plots
options, 'mms1_fpi_iBulkV_DSC', 'title', 'Bulk Ion Velocity'
options, 'mms1_fpi_iBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz']
options, 'mms1_fpi_iBulkV_DSC', 'labflag', -1
options, 'mms1_fpi_iBulkV_DSC', 'colors', [2, 4, 6]

; plot the bulk ion velocity
tplot, 'mms1_fpi_iBulkV_DSC', window=4
stop

window, 5
; combine the bulk electron velocity into a single tplot variable
join_vec, ['mms1_fpi_eBulkV_X_DSC', 'mms1_fpi_eBulkV_Y_DSC', $
           'mms1_fpi_eBulkV_Z_DSC'], 'mms1_fpi_eBulkV_DSC'

; set some options for pretty plots
options, 'mms1_fpi_eBulkV_DSC', 'title', 'Bulk Electron Velocity'
options, 'mms1_fpi_eBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz']
options, 'mms1_fpi_eBulkV_DSC', 'labflag', -1
options, 'mms1_fpi_eBulkV_DSC', 'colors', [2, 4, 6]

; plot the bulk electron velocity
tplot, 'mms1_fpi_eBulkV_DSC', window=5
stop

window, 6
; plot the anisotropy for electrons and ions
tplot, ['mms1_fpi_DESanisotropy', 'mms1_fpi_DISanisotropy'], window=6

end