;+
; MMS HPCA quick look plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2015-10-15 07:40:57 -0700 (Thu, 15 Oct 2015) $
; $LastChangedRevision: 19078 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_hpca_crib_qlplots.pro $
;-


; initialize and define parameters
;@mms_load_hpca
probes = ['1', '2', '3', '4']
species = ['H+', 'He+', 'He++', 'O+']
tplotvar_species = ['hplus', 'heplus', 'heplusplus', 'oplus']

; set parameters  
pid = probes[0]      ; set probe to mms1
sid = species[0]     ; set species to H+
tsid = tplotvar_species[0]    

trange = ['2015-09-03', '2015-09-04']
tplotvar = 'mms'+pid + '_hpca_' + tsid + '_RF_corrected'

; load mms survey HPCA data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='srvy', suffix='_srvy'

; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid, suffix='_srvy'
mms_hpca_calc_anodes, anode=[13, 14], probe=pid, suffix='_srvy'
mms_hpca_calc_anodes, anode=[0, 15], probe=pid, suffix='_srvy'

; do the same for burst data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='brst', suffix='_brst'
; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid, suffix='_brst'
mms_hpca_calc_anodes, anode=[13, 14], probe=pid, suffix='_brst'
mms_hpca_calc_anodes, anode=[0, 15], probe=pid, suffix='_brst'
stop
;get_data, tplotvar, data=brst_data, dlimits=dl_brst, limits=l_brst
;store_data, tplotvar+'_brst', data=brst_data, dlimits=dl_brst, limits=l_brst   ; save so not clobbered when loading brst
;get_data, tplotvar+'_anodes_5_6', data=brst_data_5_6
;store_data, tplotvar+'_brst_anodes_5_6', data=brst_data_5_6, dlimits=dl_brst, limits=l_brst
;get_data, tplotvar+'_anodes_13_14', data=brst_data_13_14
;store_data, tplotvar+'_brst_anodes_13_14', data=brst_data_13_14, dlimits=dl_brst, limits=l_brst
;get_data, tplotvar+'_anodes_0-15', data=brst_data_0_15
;store_data, tplotvar+'_brst_anodes_0-15', data=brst_data_0_15, dlimits=dl_brst, limits=l_brst

; create a tplot variable with flags for burst and survey data
mode_var=mms_hpca_mode(tplotvar+'_brst', tplotvar+'_srvy')

; create pseudo variables for the combined burst and survey data
store_data, tplotvar+'_brst_srvy_0_15', data=[tplotvar+'_brst_anodes_0-15', tplotvar+'_srvy_anodes_0-15'], dlimits=dl, limits=l
store_data, tplotvar+'_brst_srvy_5_6', data=[tplotvar+'_brst_anodes_5_6', tplotvar+'_srvy_anodes_5_6'], dlimits=dl, limits=l
store_data, tplotvar+'_brst_srvy_13_14', data=[tplotvar+'_brst_anodes_13_14', tplotvar+'_srvy_anodes_13_14'], dlimits=dl, limits=l

; get ephemeris data for x-axis annotation
mms_load_state, probes=pid, trange = trange, /ephemeris
eph_j2000 = 'mms'+pid+'_defeph_pos'
eph_gei = 'mms'+pid+'_defeph_pos_gei'
eph_gse = 'mms'+pid+'_defeph_pos_gse'
eph_gsm = 'mms'+pid+'_defeph_pos_gsm'

; convert from J2000 to gsm coordinates
cotrans, eph_j2000, eph_gei, /j20002gei
cotrans, eph_gei, eph_gse, /gei2gse
cotrans, eph_gse, eph_gsm, /gse2gsm

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_x',ytitle='X (Re)'
options, eph_gsm+'_re_y',ytitle='Y (Re)'
options, eph_gsm+'_re_z',ytitle='Z (Re)'
position_vars = [eph_gsm+'_re_z', eph_gsm+'_re_y', eph_gsm+'_re_x']

; set up some plotting parameters
tplot_options, 'xmargin', [20, 15]
tplot_options, 'ymargin', [5, 5]
tplot_options, 'title', 'Quicklook Plots for HPCA '+sid+' Data'
panels=[mode_var, 'mms1_hpca_hplus_RF_corrected_brst_srvy_0_15,tplotvar', $
   'mms1_hpca_hplus_RF_corrected_brst_srvy_5_6', $
    'mms1_hpca_hplus_RF_corrected_brst_srvy_13_14']
window, 1
tplot, panels, var_label=position_vars, window=1

stop

end