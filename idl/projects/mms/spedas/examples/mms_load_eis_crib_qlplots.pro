;+
; MMS EIS quick look plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-10-06 15:45:39 -0700 (Tue, 06 Oct 2015) $
; $LastChangedRevision: 19019 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_eis_crib_qlplots.pro $
;-

probe = '1'
trange = ['2015-08-15', '2015-08-16']
width = 650
height = 750
prefix = 'mms'+probe+'_epd_eis'

; load ExTOF and electron data:
mms_load_eis, probes=probe, trange=trange, datatype='extof', level='l1b'
mms_load_eis, probes=probe, trange=trange, datatype='electronenergy', level='l1b'

; load DFG data
mms_load_dfg, probes=probe, trange=trange, level='ql'

; setup for plotting the proton flux for all channels
ylim, prefix+'_electronenergy_electron_flux_omni_spin', 30, 1000, 1
zlim, prefix+'_electronenergy_electron_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_proton_flux_omni_spin', 50, 500, 1
zlim, prefix+'_extof_proton_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_oxygen_flux_omni_spin', 150, 1000, 1
zlim, prefix+'_extof_oxygen_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_alpha_flux_omni_spin', 80, 800, 1
zlim, prefix+'_extof_alpha_flux_omni_spin', 0, 0, 1

; force the min/max of the Y axes to the limits
options, '*_flux_omni*', ystyle=1

; get ephemeris data for x-axis annotation
mms_load_state, probes=probe, trange=trange, /ephemeris
eph_j2000 = 'mms'+probe+'_defeph_pos'
eph_gei = 'mms'+probe+'defeph_pos_gei'
eph_gse = 'mms'+probe+'_defeph_pos_gse'
eph_gsm = 'mms'+probe+'_defeph_pos_gsm'

; convert from gei to gsm coordinates
cotrans, eph_j2000, eph_gei, /j20002gei
cotrans, eph_gei, eph_gse, /gei2gse
cotrans, eph_gse, eph_gsm, /gse2gsm

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; calculate R to spacecraft
calc, '"mms'+probe+'_defeph_R_gsm" = sqrt("'+eph_gsm+'_re_x'+'"^2+"'+eph_gsm+'_re_y'+'"^2+"'+eph_gsm+'_re_z'+'"^2)'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_x',ytitle='X (Re)'
options, eph_gsm+'_re_y',ytitle='Y (Re)'
options, eph_gsm+'_re_z',ytitle='Z (Re)'
options, 'mms'+probe+'_defeph_R_gsm',ytitle='R (Re)'
position_vars = ['mms'+probe+'_defeph_R_gsm', eph_gsm+'_re_z', eph_gsm+'_re_y', eph_gsm+'_re_x']

tplot_options, 'ymargin', [5, 5]
tplot_options, 'xmargin', [15, 15]
tplot_options, 'title', 'EIS - Quicklook'

; clip the DFG data to -150nT to 150nT
tclip, 'mms'+probe+'_dfg_srvy_gse_bvec', -150., 150., /overwrite

panels = ['mms'+probe+'_dfg_srvy_gse_bvec', $
          prefix+'_electronenergy_electron_flux_omni_spin', $
          prefix+'_extof_proton_flux_omni_spin', $
          prefix+'_extof_alpha_flux_omni_spin', $
          prefix+'_extof_oxygen_flux_omni_spin']

window, xsize=width, ysize=height
tplot, panels, var_label=position_vars

end