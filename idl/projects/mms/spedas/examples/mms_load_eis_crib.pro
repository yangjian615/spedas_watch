;+
; MMS EIS crib sheet
; 
;  prime EIS scientific products are: 
;    ExTOF proton spectra, 
;    ExTOF He spectra, 
;    ExTOF Oxygen spectra, 
;    PHxTOF proton spectra, 
;    PHxTOF Oxygen (assumed to be oxygen; not terrifically discriminated), 
;  and finally, electron spectra as a backup to FEEPS.
;  
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-07 15:20:36 -0700 (Fri, 07 Aug 2015) $
; $LastChangedRevision: 18439 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_eis_crib.pro $
;-

tplot_options, 'xmargin', [20, 15]

; load ExTOF data:
mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='extof'

; plot the H+ flux for all channels
ylim, '*_extof_proton_flux_t?', 30, 500, 1
zlim, '*_extof_proton_flux_t?', 0, 0, 1
tplot, '*_extof_proton_flux_t?'

stop

; plot the He++ flux for all channels
ylim, '*_extof_alpha_flux_t?', 30, 500, 1
zlim, '*_extof_alpha_flux_t?', 0, 0, 1
tplot, '*_extof_alpha_flux_t?'

stop

; plot the O+ flux for all channels
ylim, '*_extof_oxygen_flux_t?', 30, 500, 1
zlim, '*_extof_oxygen_flux_t?', 0, 0, 1
tplot, '*_extof_oxygen_flux_t?'

stop

; load PHxTOF data:
mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='phxtof'

; plot the PHxTOF proton spectra
ylim, '*_phxtof_proton_flux_t?', 0, 0, 1
zlim, '*_phxtof_proton_flux_t?', 0, 0, 1
tplot, '*_phxtof_proton_flux_t?'
stop

; plot the PHxTOF oxygen spectra (note from Barry Mauk: assumed to be oxygen; not terrifically discriminated)
ylim, '*_phxtof_oxygen_flux_t?', 0, 0, 1
zlim, '*_phxtof_oxygen_flux_t?', 0, 0, 1
tplot, '*_phxtof_oxygen_flux_t?'
stop

; load electron data for MMS 1 on 7/31
; NOTE: electron spectra from EIS is a secondary product - EIS electrons are a 
;   backup for FEEPS electrons - see mms_load_feeps_crib 
mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='electronenergy'

; calculate the electron pitch angle distribution
mms_eis_pad, probe='1', trange=['2015-07-31', '2015-08-01'], species = 'electron'

ylim, 'mms1_epd_eis_electronenergy_electron_flux_omni', 30, 3000.,1
zlim, 'mms1_epd_eis_electronenergy_electron_flux_omni', .1, 5000.,1

; plot omni-directional (all 6 telescopes) electron flux
; as well as the pitch angle distribution
tplot, ['mms1_epd_eis_electronenergy_electron_flux_omni', $
        'mms1_epd_eis_electron_pad']

stop

; set some options for the electron spectra
options, 'mms1_epd_eis_electronenergy_electron_flux_t?', spec=1, ylog=1, zlog=1

window, 2
; plot the electron spectra for the different telescopes
tplot, 'mms1_epd_eis_electronenergy_electron_flux_t?', window=2
stop

; load some ion data
mms_load_eis, probes='1', trange=['2015-07-08', '2015-07-09'], datatype='partenergy'

; calculate the ion pitch angle distribution
mms_eis_pad, probe='1', trange=['2015-07-31', '2015-08-01'], species = 'ion'

window, 3
tplot, ['mms1_epd_eis_partenergy_nonparticle_flux_omni', 'mms1_epd_eis_ion_pad'], window=3
stop

; set some options for the ion spectra
options, 'mms1_epd_eis_partenergy_nonparticle_flux_t?', spec=1, ylog=1, zlog=1

window, 4
tplot, 'mms1_epd_eis_partenergy_nonparticle_flux_t?', window=4
end