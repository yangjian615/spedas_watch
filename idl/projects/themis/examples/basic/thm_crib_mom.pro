;+
;pro thm_crib_mom
; This is an example crib sheet that will load onboard MOMent data.
; It also shows how to compute moments from the full distributions.
; Data is corrected for spacecraft potential.
;
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window. Or alternatively compile and run
; using the command:
; .RUN THM_CRIB_MOM
;-

if not keyword_set(sc) then sc = 'c'

;------------ On Board moments: ----------------

; load onboard moments
thm_load_mom,probe=sc

; load magnetic field data:
thm_load_fit,probe=sc


; ------------- Ground processed moments: ----------------


; load ESA distribution data:
thm_load_esa_pkt,probe=sc

; load Spacecraft Potential, this results in a tplot variable with the
; spacecraft potential for all ESA modes. Note that setting the
; datatype keyword equal to anything that is not 'mom' will result in
; the direct use of EFI data for the potential. If datatype is not
; set, or is set to 'mom', then th?_pxxm_pot is used  
thm_load_esa_pot, sc = sc

; calculate esa electron and ion parameters  (moments and spectra) :
thm_part_moments, probe = sc, instrum = 'pe?f', scpot_suffix = '_esa_pot', mag_suffix = '_fgs', tplotnames = tn, verbose = 2 ; names are output into variable tn

; load SST data
thm_load_sst,probe=sc

; calculate SST parameters:
thm_part_moments,probe=sc,instrum='ps?f',mag_suffix='_fgs' ,tplotnames=tn, verbose=2    ; names are output into variable tn
thm_part_moments,probe=sc,instrum='ps?r',mag_suffix='_fgs' ,tplotnames=tn, verbose=2    ; names are output into variable tn

; get eflux spectra of reduced distributions  (but not moments)
thm_part_moments, probe = sc, instrum = 'pe?r', moments = ''

; Create overview variables

store_data,'Th'+sc+'_pXiX_en_eflux',data='th'+sc+['_peif_en_eflux','_peir_en_eflux','_psif_en_eflux','_psir_en_eflux'], $
    dlimit={yrange:[1,1e6],ylog:1,panel_size:1.5,ztitle:'Eflux [eV/cm2/s/ster/eV]',zrange:[1e3,1e9],zlog:1}

store_data,'Th'+sc+'_pXeX_en_eflux',data='th'+sc+['_peef_en_eflux','_peer_en_eflux','_psef_en_eflux', '_pxxm_pot'], $
    dlimit={yrange:[1,1e6],ylog:1,panel_size:1.5,ztitle:'Eflux [eV/cm2/s/ster/eV]',zrange:[1e3,1e9],zlog:1}

options,'th?_p?if_density',colors='b'
options,'th?_p?ef_density',colors='r'
options,'th?_p?im_density',colors='c'
options,'th?_p?em_density',colors='m'

store_data,'Th'+sc+'_peXf_density',data='th'+sc+['_peef_density','_peif_density']   ;, '_pxxm_pot'
store_data,'Th'+sc+'_peXm_density',data='th'+sc+['_peem_density','_peim_density']   ;, '_pxxm_pot'

store_data,'Th'+sc+'_peiX_density',data='th'+sc+['_peim_density','_peif_density']   ;, '_pxxm_pot'
store_data,'Th'+sc+'_peeX_density',data='th'+sc+['_peem_density','_peef_density']   ;, '_pxxm_pot'

ylim,'*density',.1,400,1


tplot,'T* '

stop

;
; Eclipse spin model corrections for onboard moments
;



; Example showing use of eclipse spin model corrections for onboard MOM data

; THB passed through a lunar shadow during this flyby.  The eclipse
; occurs between approximately 0853 and 0930 UTC.

timespan,'2010-02-13/08:00',4,/hours

; 2012-08-03: By default, the eclipse spin model corrections are not
; applied. For clarity, we'll explicitly set use_eclipse_corrections to 0
; to get a comparison plot, showing how the lack of eclipse spin model
; corrections induces an apparent rotation in the data.

thm_load_mom,probe='b',level=1,type='calibrated',suffix='_before',use_eclipse_corrections=0

; Here we load the same data, but enable the full set of eclipse spin
; model corrections by setting use_eclipse_corrections to 2.  
;  
; use_eclipse_corrections=1 is not recommended except for SOC processing.
; It omits an important spin phase offset value that is important
; for data types that are despun on board:  particles, moments, and
; spin fits.
;
; Note that calibrated L1 data must be requested in order to use
; the eclipse spin model corrections.  The corrections are not
; yet enabled in the L1->L2 processing.

thm_load_mom,probe='b',level=1,type='calibrated',suffix='_after',use_eclipse_corrections=2

; Plot the data to compare the results before and after the eclipse
; spin model corrections have been applied.  In the uncorrected
; data, the field is clearly rotating in the spin plane, due to
; the spin-up that occurs during the eclipse as the probe and
; booms cool and contract.

tplot,['thb_peim_velocity_before','thb_peim_velocity_after','thb_peem_velocity_before','thb_peem_velocity_after']

print, "This plot shows some onboard velocity moments, without (_before)"
print, "and with (_after) the eclipse spin model corrections enabled."
print, "During the eclipse (0853-0930 UTC), a spin phase offset and "
print, "slow rotation are visible in the uncorrected data, due to the"
print, "spin-up that occurs as the probe and booms cool and contract."

stop

end

