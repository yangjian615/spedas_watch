;+
; MMS FIELDS quicklook plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-10-07 09:20:46 -0700 (Wed, 07 Oct 2015) $
; $LastChangedRevision: 19025 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_fields_crib_qlplots.pro $
;-


; initialize and define parameters
probes = ['1', '2', '3', '4']
trange = ['2015-09-05', '2015-09-06']

;
; START OF FIELDS PLOTS - ALL SPACECRAFT 
;  
; load mms survey Fields data
mms_load_dfg, probes=probes, trange=trange,  level='ql', data_rate='srvy'

; DMPA - Handle Btot and Bvec 

; Btot - set title and colors and create psuedo variable
options, 'mms1*_btot', colors=[0]    ; black
options, 'mms2*_btot', colors=[6]    ; red
options, 'mms3*_btot', colors=[4]    ; green
options, 'mms4*_btot', colors=[2]    ; blue
store_data, 'mms_dfg_srvy_dmpa_btot', data = ['mms1_dfg_srvy_dmpa_btot', $
                                       'mms2_dfg_srvy_dmpa_btot', $
                                       'mms3_dfg_srvy_dmpa_btot', $
                                       'mms4_dfg_srvy_dmpa_btot']
options, 'mms_*_btot',ytitle='DFG Btot'
options, 'mms_*_btot',ysubtitle='QL [nT]'

; Bvec - set colors, psuedo variables and titles
options, 'mms1*_bvec', colors=[0]    ; black
options, 'mms2*_bvec', colors=[6]    ; red
options, 'mms3*_bvec', colors=[4]    ; green
options, 'mms4*_bvec', colors=[2]    ; blue
; split into components x, y, z for plotting
split_vec, 'mms*_bvec'
; create psuedo variables for each component x, y, and z
store_data, 'mms_dfg_srvy_dmpa_bvec_x', data = ['mms1_dfg_srvy_dmpa_bvec_x', $
  'mms2_dfg_srvy_dmpa_bvec_x', $
  'mms3_dfg_srvy_dmpa_bvec_x', $
  'mms4_dfg_srvy_dmpa_bvec_x']
store_data, 'mms_dfg_srvy_dmpa_bvec_y', data = ['mms1_dfg_srvy_dmpa_bvec_y', $
    'mms2_dfg_srvy_dmpa_bvec_y', $
    'mms3_dfg_srvy_dmpa_bvec_y', $
    'mms4_dfg_srvy_dmpa_bvec_y']
store_data, 'mms_dfg_srvy_dmpa_bvec_z', data = ['mms1_dfg_srvy_dmpa_bvec_z', $
    'mms2_dfg_srvy_dmpa_bvec_z', $
    'mms3_dfg_srvy_dmpa_bvec_z', $
    'mms4_dfg_srvy_dmpa_bvec_z']
; set titles
options, 'mms_*_bvec_x', ytitle='DFG Bx'
options, 'mms_*_bvec_y', ytitle='DFG By'
options, 'mms_*_bvec_z', ytitle='DFG Bz'
options, 'mms_*_bvec_*', ysubtitle='DMPA [nT]' 

; GSM-DMPA - do the same for gsm_dmpa data, note gsm_dmpa data is not separated into btot and bvec
options, 'mms1*_gsm_dmpa', colors=[0]    ; black
options, 'mms2*_gsm_dmpa', colors=[6]    ; red
options, 'mms3*_gsm_dmpa', colors=[4]    ; green
options, 'mms4*_gsm_dmpa', colors=[2]    ; blue
split_vec, 'mms*_dfg_srvy_gsm_dmpa'
store_data, 'mms_dfg_srvy_gsm_dmpa_x', data = ['mms1_dfg_srvy_gsm_dmpa_0', $
  'mms2_dfg_srvy_gsm_dmpa_0', $
  'mms3_dfg_srvy_gsm_dmpa_0', $
  'mms4_dfg_srvy_gsm_dmpa_0']
store_data, 'mms_dfg_srvy_gsm_dmpa_y', data = ['mms1_dfg_srvy_gsm_dmpa_1', $
  'mms2_dfg_srvy_gsm_dmpa_1', $
  'mms3_dfg_srvy_gsm_dmpa_1', $
  'mms4_dfg_srvy_gsm_dmpa_1']
store_data, 'mms_dfg_srvy_gsm_dmpa_z', data = ['mms1_dfg_srvy_gsm_dmpa_2', $
  'mms2_dfg_srvy_gsm_dmpa_2', $
  'mms3_dfg_srvy_gsm_dmpa_2', $
  'mms4_dfg_srvy_gsm_dmpa_2']
options, 'mms_*_gsm_dmpa_x', ytitle='DFG Bx'
options, 'mms_*_gsm_dmpa_y', ytitle='DFG By'
options, 'mms_*_gsm_dmpa_z', ytitle='DFG Bz'
options, 'mms_*_gsm_dmpa_*', ysubtitle='GSM-DMPA [nT]'

;mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='epsd', level='l2'
;mms_load_dsp,  data_rate='srvy', probes=[1, 2, 3, 4], datatype='bpsd', level='l2'

tplot_options, 'xmargin', [20, 15]
tplot_options, 'ymargin', [5, 5]
tplot_options, 'title', 'MMS Quicklook Plots for Fields Data'
tplot_options, 'charsize', 1.
window, 1, xsize=850, ysize=1000
tplot, ['mms_*_btot', 'mms_*_gsm_dmpa_*', 'mms_*_bvec_*'], window=1
stop

;
; START OF FIELDS2 E&B PLOTS - ALL SPACECRAFT
;
; Get dec data
timespan, '2015-09-05', 1, /day
mms_load_edp, data_rate='fast', probes=[1, 2, 3, 4], datatype='dce', level='ql'
options, 'mms1*_dce_dsl', colors=[0]    ; black
options, 'mms2*_dce_dsl', colors=[6]    ; red
options, 'mms3*_dce_dsl', colors=[4]    ; green
options, 'mms4*_dce_dsl', colors=[2]    ; blue
split_vec, 'mms*_dce_dsl'
store_data, 'mms_edp_fast_dce_dsl_x', data = ['mms1_edp_fast_dce_dsl_x', $
  'mms2_edp_fast_dce_dsl_x', $
  'mms3_edp_fast_dce_dsl_x', $
  'mms4_edp_fast_dce_dsl_x']
store_data, 'mms_edp_fast_dce_dsl_y', data = ['mms1_edp_fast_dce_dsl_y', $
  'mms2_edp_fast_dce_dsl_y', $
  'mms3_edp_fast_dce_dsl_y', $
  'mms4_edp_fast_dce_dsl_y']
store_data, 'mms_edp_fast_dce_dsl_z', data = ['mms1_edp_fast_dce_dsl_z', $
  'mms2_edp_fast_dce_dsl_z', $
  'mms3_edp_fast_dce_dsl_z', $
  'mms4_edp_fast_dce_dsl_z']
options, 'mms_*_dce_dsl_x', ytitle='EDP Ex'
options, 'mms_*_dce_dsl_y', ytitle='EDP Ey'
options, 'mms_*_dce_dsl_z', ytitle='EDP Ez'

; get scpot
mms_load_aspoc, datatype='asp1', trange=trange, level='l1b', probe=probes
options, 'mms1*_spot*', colors=[0]    ; black
options, 'mms2*_spot*', colors=[6]    ; red
options, 'mms3*_spot*', colors=[4]    ; green
options, 'mms4*_spot*', colors=[2]    ; blue
store_data, 'mms_asp1_spot_l1b', data = ['mms1_asp1_spot_l1b', $
  'mms2_asp1_spot_l1b', $
  'mms3_asp1_spot_l1b', $
  'mms4_asp1_spot_l1b']
options, 'mms_*spot_l1b', ytitle='ASP1 Scpot'

tplot_options, 'title', 'MMS E&B Quicklook Plots'
tplot, ['mms_*_dce_dsl_*', 'mms_asp1_spot_l1b', 'mms_*_btot', 'mms_*_gsm_dmpa_*'], window=1
stop

;
; EDP QuickLook Plots 
;
tplot_options, 'title', 'MMS EDP Quicklook Plots'
tplot, ['mms_asp1_spot_l1b', 'mms_*_dce_dsl_*'], window=1
stop

end