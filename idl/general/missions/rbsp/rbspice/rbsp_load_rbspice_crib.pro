;+
; RBSP RBSPICE crib sheet
; 
;  prime RBSPICE scientific products are: 
;    TOFxEH proton spectra
;    TOFxEnonH helium spectra
;    TOFxEnonH oxygen spectra
;    TOFxPHHHELT proton spectra
;    TOFxPHHHELT oxygen spectra
;  
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
;-
probe = 'a'
prefix = 'rbsp'+probe
trange = ['2015-10-16', '2015-10-17']
level = 'l3'
tplot_options, 'xmargin', [20, 15]


; load TOFxEH (proton) data:
rbsp_load_rbspice, probes=probe, trange=trange, datatype='TOFxEH', level = level 

; plot the H+ flux for all channels
tplot, '*TOFxEH_proton_omni_spin'
stop

; calculate the PAD for 48-106keV protons
rbsp_rbspice_pad, probe=probe, trange = trange, datatype='TOFxEH', energy=[48, 106], bin_size = 15, level = level

; calculate the PAD for 105-250 keV protons
mms_eis_pad, probe=probe, trange = trange, datatype='TOFxEH', energy=[105, 250], bin_size = 15, level = level

; plot the PAD for 48-106keV (top), 105-250 keV (bottom) protons 
tplot, '*TOFxEH_proton_omni_*keV_pad' 
stop

; load TOFxEnonH (helium and oxygen) data:
rbsp_load_rbspice, probes=probe, trange=trange, datatype='TOFxEH', level = level

; plot the He++ flux for all channels
tplot, '*TOFxEnonH_helium_omni_spin'
stop

; plot the O+ flux for all channels
tplot, '*TOFxEnonH_oxygen_omni_spin'

stop

; load PHxTOF (proton and oxygen) data:
rbsp_load_rbspice, probes=probe, trange=trange, datatype='TOFxPHHHLET', level = level 

; plot the PHxTOF proton spectra
tplot, '*_TOFxPHHHLET_proton_omni_spin'
stop

; plot the PHxTOF proton spectra
tplot, '*_TOFxPHHHLET_oxygen_omni_spin'
stop

; calculate the PHxTOF PAD for protons
mms_eis_pad, probe=probe, trange=trange, datatype='TOFxPHHHLET', energy=[0, 30], bin_size = 15, level = level

tplot, ['*TOFxPHHHLET_proton_omni_spin', $
        '*TOFxPHHHLET_proton_omni_0-30keV_pad_spin']
stop

end