;+
;
;  This crib sheet shows how to create a figure with multiple panels, one
;  of which contains 2 variables with independent axes (FPI temp and density)
;     i.e., line plots of two tplot variables in a single panel where one has its 
;     y-axis/title on the left and the other has its y-axis/title on the right
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-05-23 11:17:20 -0700 (Mon, 23 May 2016) $
; $LastChangedRevision: 21177 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_multi_axis_figure.pro $
;-

; need to set the ystyle to not draw the axes by default
!Y.STYLE = 4

; load the data
mms_load_fgm, trange=['2015-10-16/13:00', '2015-10-16/14:00'], probe=1, /time_clip
mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/14:00'], probe=1, datatype='des-moms', /time_clip

; remove the ytitle/labels
options, 'mms1_des_numberdensity_dbcs_fast', labels='', colors=0 ; black
options, 'mms1_des_tempzz_dbcs_fast', labels='', colors=2 ; blue

; setup the axes
options, 'mms1_des_numberdensity_dbcs_fast', axis={yaxis: 0, ystyle: 1, YNOZERO: 1, ytitle: 'DES!CDensity', color: 0}
options, 'mms1_des_tempzz_dbcs_fast', axis={yaxis: 1, ystyle: 1, YNOZERO: 1, ytitle: 'TempZZ!CeV', color: 2}
options, 'mms1_fgm_b_gse_srvy_l2_bvec', axis={yaxis: 0, ystyle: 1}
options, 'mms1_fgm_b_gse_srvy_l2_bvec', yaxis=0, ystyle=1
options, 'mms1_des_bulkspeed_dbcs_fast', yaxis=0, ystyle=1

; plot the data initially
tplot, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_des_numberdensity_dbcs_fast', 'mms1_des_bulkspeed_dbcs_fast', 'mms1_des_energyspectr_omni_avg']

; oplot, only difference is temp instead of number density
tplot, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_des_tempzz_dbcs_fast', 'mms1_des_bulkspeed_dbcs_fast', 'mms1_des_energyspectr_omni_avg'], /oplot

end