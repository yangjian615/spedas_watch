;+
; MMS EIS crib sheet
; 
;  prime EIS scientific products are: 
;    ExTOF proton spectra
;    ExTOF He spectra
;    ExTOF Oxygen spectra
;    PHxTOF proton spectra
;    PHxTOF Oxygen (assumed to be oxygen; not terrifically discriminated)
;    
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

; load ExTOF data:
mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='extof'

; plot the H+ flux for all channels
ylim, '*_extof_proton_flux_t?', 50, 300, 1
zlim, '*_extof_proton_flux_t?', 0, 0, 1

; setting ystyle = 1 forces the max/min of the Y axis to be set
; to the y limits set above
options, '*_extof_proton_flux_t?', ystyle=1

; replace gaps in the data with NaNs
tdegap, '*_extof_proton_flux_t?', /overwrite

tplot, '*_extof_proton_flux_t?'
stop

; smooth these data in energy and time
options, '*_extof_proton_flux_t?', x_no_interp=0, y_no_interp=0, no_interp=0
tsmooth_in_time, '*_extof_proton_flux_t?', 60
tplot, '*_extof_proton_flux_t?'
stop


; if we degap the flux data, we should also degap the pitch angle data
tdegap, '*_extof_pitch_angle_*', /overwrite

; calculate the PAD for 48-106keV protons
mms_eis_pad, probe='1', species='ion', data_name='extof', ion_type='proton', data_units='flux', energy=[48, 106]

; calculate the PAD for 105-250 keV protons
mms_eis_pad, probe='1', species='ion', data_name='extof', ion_type='proton', data_units='flux', energy=[105, 250]
tplot, 'mms1_epd_eis_ion_extof_*keV_proton_flux_pad'
stop

; plot the He++ flux for all channels
ylim, '*_extof_alpha_flux_t?', 30, 500, 1
zlim, '*_extof_alpha_flux_t?', 0, 0, 1
tplot, '*_extof_alpha_flux_t?'

stop

; plot the O+ flux for all channels
ylim, '*_extof_oxygen_flux_t?', 30, 500, 1
zlim, '*_extof_oxygen_flux_t?', 0, 0, 1

; replace gaps in the data with NaNs
tdegap, '*_extof_oxygen_flux_t?', /overwrite
tplot, '*_extof_oxygen_flux_t?'

stop

; load PHxTOF data:
mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='phxtof'

; plot the PHxTOF proton spectra
ylim, '*_phxtof_proton_flux_t?', 10, 50, 1
zlim, '*_phxtof_proton_flux_t?', 0, 0, 1
options, '*_phxtof_proton_flux_t?', ystyle=1
tdegap, '*_phxtof_proton_flux_t?', /overwrite
tplot, '*_phxtof_proton_flux_t?'
stop

; if we degap the flux data, we should also degap the pitch angle data
tdegap, '*phxtof_pitch_angle_*', /overwrite

; calculate the PHxTOF PAD for protons
mms_eis_pad, probe='1', species='ion', data_name='phxtof', ion_type='proton', data_units='flux', energy=[0, 30]

tplot, 'mms1_epd_eis_ion_phxtof_0-30keV_proton_flux_pad'
stop

; plot the PHxTOF oxygen spectra (note from Barry Mauk: assumed to be oxygen; not terrifically discriminated)
ylim, '*_phxtof_oxygen_flux_t?', 0, 0, 1
zlim, '*_phxtof_oxygen_flux_t?', 0, 0, 1
options, '*_phxtof_oxygen_flux_t?', ystyle=1
tdegap, '*_phxtof_oxygen_flux_t?', /overwrite
tplot, '*_phxtof_oxygen_flux_t?'
stop

; calculate the PHxTOF PAD for oxygen
mms_eis_pad, probe='1', species='ion', data_name='phxtof', ion_type='oxygen', data_units='flux', energy=[0, 175]

tplot, 'mms1_epd_eis_ion_phxtof_0-175keV_oxygen_flux_pad'
end