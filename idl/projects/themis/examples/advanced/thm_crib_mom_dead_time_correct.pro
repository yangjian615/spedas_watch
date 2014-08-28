;+
;NAME:
; thm_crib_mom_dead_time_correct
;PURPOSE:
; example for use of dead time corrections for on-board moments
; calculated from ground-based moments.
;CALLING SEQUENCE:
; thm_crib_mom_dead_time_corrections
;
;-


;First call thm_load_mom to load data

timespan, '2011-05-05'

;input the moment data

;As of 10-August-2011, the default for loading MOM L2 data includes the
;dead time correction described here. For L1 data, this is not the
;default, we provide keywords:
;  /dead_time_correct: If set, then calculate dead time correction
;                      based on ESA moments, this is the default
;                      for L2 input
;  /no_dead_time_correct: If set, do not calculate a dead time
;                         correction based on ESA ground-based
;                         moments, this is the default for L1
;                         data. If both the no_dead and dead
;                         keywords are set, then NO correction is
;                         applied.

thm_load_mom,  probe = 'b'

;Do dead time correction, THM_APPLY_ESA_MOM_DTC calculates the dead
;time corrections for moments using the program THM_ESA_DTC4MOM.  This
;program obtains dead time corrections for moments using the following
;steps:

;1) Load ESA data, the default is to use full-mode data, but other
;modes can by set using the use_esa_mode keyword to 'f', 'r', or 'b'

;2) Alter the appropriate ESA 3d data structures by setting the dead
;time correction paramater 'DEAD' to 0.

;3) Calculate the moments, as if there is no dead time correction:
;['density', 'flux', 'mftens', 'eflux', 'velocity', 'ptens', 'ptot']
;are the moments calculated.

;4) Reset the DEAD parameter in the 3d data structure to it's original
;value (1.7e-7 it the typical value).

;5) Re-calculate the moments, as if there is a dead time correction,

;6) Obtain the dead-time correction variables for the moments by
;dividing the 'corrrected' variables from step 5 by the 'uncorrected'
;variables from step 3. Now you have a bunch of variables with names
;like: 'thb_peif_density_dtc', or 'thb_peem_velocity_dtc'

;Once THM_ESA_DTC4MOM is finished, the '*_dtc' variables are
;interpolated to the times of the appropriate on-board moments. After
;this step, the on-board moments are multiplied by the dead-time
;corrections and we now have corrected moments.

;the /save_esa keyword saves the ESA variables containing the
;dead-time corrections.


thm_apply_esa_mom_dtc, probe = 'b'

;Plot some dead time corrections:
tplot, 'thb_pe?f_density_dtc'

;The default behavoir is to overwrite the uncorrected variable, and
;add a tag in its dlimits.data_att structure to alert the correction
;program that the data has already been corrected. So that if you run
;it again, nothing happens, because the data has been corrected.

thm_apply_esa_mom_dtc, probe = 'b'

;If you wnat to compare corrected with uncorrected values, use the
;out_suffix keyword, this will avoid overwriting the MOM variables:

;start over, though because the variables are corrected
del_data, '*'
;input the moment data
thm_load_mom,  probe = 'b', /no_dead_time_correct

thm_apply_esa_mom_dtc, probe = 'b',  out_suffix = '_corrected'

;And plot, 

tplot,  'thb_pe?m_density*'

;Using the out_suffix keyword, you can also compare different options
;for the correction. As mentioned above, the default is to use ESA
;full-mode data, you can change this using the 'use_esa_mode' keyword

thm_apply_esa_mom_dtc,  probe = 'b', use_esa_mode = 'r', out_suffix = '_corrected_r'
tplot,  'thb_peim_density*'

tplot, 'thb_pei?_density_dtc*'   ;to compare the different corrections

;The default is to not include corrections for the spacecraft
;potential in the moments when calculating the _dtc variables. To add
;sc potential corrections, set the /scpot_correct keyword

thm_apply_esa_mom_dtc,  probe = 'b', /scpot_correct, out_suffix = '_corrected_scpot'

tplot,  'thb_peim_density*'

tplot, 'thb_pei?_density_dtc*'   ;to compare the different corrections


;As of 24-aug-2011, these corrections are only the default for L2 MOM
;input. To get corrected values for L1:

thm_load_mom, probe='b', suffix = '_corrected', /dead_time_correct

;If you want to make comparisons, load without corrections

thm_load_mom, probe='b', suffix = '_uncorrected'


End
