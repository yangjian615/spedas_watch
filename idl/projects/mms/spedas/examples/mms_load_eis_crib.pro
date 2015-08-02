;+
; MMS EIS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-07-31 15:57:48 -0700 (Fri, 31 Jul 2015) $
; $LastChangedRevision: 18341 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_eis_crib.pro $
;-

; load electron data for MMS 1 on 6/22
mms_load_eis, probes='1', trange=['2015-06-22', '2015-06-23'], datatype='electronenergy'

; plot omni-directional (all 6 telescopes) electron counts per sec 
; as well as the pitch angle distribution
tplot, ['mms1_epd_eis_electronenergy_electron_omni', $
        'mms1_epd_eis_electron_pad']
stop

window, 1
; plot the data for the solid state detectors
tplot, 'mms1_epd_eis_electronenergy_ssd?', window=1
stop

; set some options for the electron spectra
options, 'mms1_epd_eis_electronenergy_electron_cps_t?', spec=1, ylog=1, zlog=1

window, 2
; plot the electron spectra for the different telescopes
tplot, 'mms1_epd_eis_electronenergy_electron_cps_t?', window=2
stop

; load some ion data
mms_load_eis, probes='1', trange=['2015-07-08', '2015-07-09'], datatype='partenergy'

window, 3
tplot, ['mms1_epd_eis_partenergy_nonparticle_omni', 'mms1_epd_eis_ion_pad'], window=3
stop

; set some options for the ion spectra
options, 'mms1_epd_eis_partenergy_nonparticle_cps_t?', spec=1, ylog=1, zlog=1

window, 4
tplot, 'mms1_epd_eis_partenergy_nonparticle_cps_t?', window=4
end