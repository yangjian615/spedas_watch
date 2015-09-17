;+
; MMS HPCA quick look plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-27 11:42:08 -0700 (Thu, 27 Aug 2015) $
; $LastChangedRevision: 18640 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_hpca_crib_qlplots.pro $
;-


; initialize and define parameters
@mms_load_hpca
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
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='srvy'

; retrieve data from tplot variable
get_data, tplotvar, data=srvy_data, dlimits=dl, limits=l
store_data, tplotvar+'_srvy', data=srvy_data, dlimits=dl, limits=l   ; save so not clobbered when loading brst

if is_struct(srvy_data) then begin

  ; sum over all anodes
  updated_spectra = mms_hpca_sum_fov(srvy_data, fov=fov)
  store_data, tplotvar+'_total_srvy', data=updated_spectra, dlimits=dl, limits=l

  ; sum over anodes 5 and 6 
  anodes=[4,5]
  data2sum = srvy_data.Y[*,*,anodes]
  datatotal = dblarr(n_elements(srvy_data.x), n_elements(srvy_data.v))
  datatotal = total(data2sum, 3, /nan)
  datatotal(where(datatotal eq 0.)) = !VALUES.F_NAN
  hpca_data_total = {x: srvy_data.x, y: datatotal, v: srvy_data.v}
  thisl = l
  thisl.ysubtitle=thisl.ysubtitle + ' anodes 5-6'     ; 
  store_data, tplotvar+'_total_5_6_srvy', data=hpca_data_total, dlimits=dl, limits=thisl
  
  ; sum over anodes 13 and 14
  anodes=[12,13]
  data2sum = srvy_data.Y[*,*,anodes]
  datatotal = total(data2sum, 3, /nan)
  datatotal(where(datatotal eq 0.)) = !VALUES.F_NAN
  hpca_data_total = {x: srvy_data.x, y: datatotal, v: srvy_data.v}
  thisl = l
  thisl.ysubtitle=thisl.ysubtitle + ' anodes 13-14'     ;
  store_data, tplotvar+'_total_13_14_srvy', data=hpca_data_total, dlimits=dl, limits=thisl
  
endif

; do the same for burst data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='brst'

get_data, tplotvar, data=brst_data, dlimits=dl, limits=l
store_data, tplotvar+'_brst', data=brst_data, dlimits=dl, limits=l

if is_struct(brst_data) then begin

  ; sum over all anodes
  updated_spectra = mms_hpca_sum_fov(brst_data, fov=fov)
  store_data, tplotvar+'_total_brst', data=updated_spectra, dlimits=dl, limits=l

  ; sum over anodes 5 and 6
  anodes=[4,5]
  data2sum = brst_data.Y[*,*,anodes]
  datatotal = dblarr(n_elements(brst_data.x), n_elements(brst_data.v))
  datatotal = total(data2sum, 3, /nan)
  datatotal(where(datatotal eq 0.)) = !VALUES.F_NAN
  hpca_data_total = {x: brst_data.x, y: datatotal, v: brst_data.v}
  thisl = l
  thisl.ysubtitle=thisl.ysubtitle + ' 5-6'     ;
  store_data, tplotvar+'_total_5_6_brst', data=hpca_data_total, dlimits=dl, limits=thisl

  ; sum over anodes 13 and 14
  anodes=[12,13]
  data2sum = brst_data.Y[*,*,anodes]
  datatotal = total(data2sum, 3, /nan)
  datatotal(where(datatotal eq 0.)) = !VALUES.F_NAN
  hpca_data_total = {x: brst_data.x, y: datatotal, v: brst_data.v}
  thisl = l
  thisl.ysubtitle=thisl.ysubtitle + ' 13-14'     ;
  store_data, tplotvar+'_total_13_14_brst', data=hpca_data_total, dlimits=dl, limits=thisl

endif

; create a tplot variable with flags for burst and survey data
mode_var=mms_hpca_mode(tplotvar+'_brst', tplotvar+'_srvy')

; create pseudo variables for the combined burst and survey data
store_data, tplotvar+'_brst_srvy', data=[tplotvar+'_brst', tplotvar+'_srvy']
store_data, tplotvar+'_total_5_6_brst_srvy', data=[tplotvar+'_total_5_6_brst', tplotvar+'_total_5_6_srvy']
store_data, tplotvar+'_total_13_14_brst_srvy', data=[tplotvar+'_total_13_14_brst', tplotvar+'_total_13_14_srvy']

; get ephemeris data for x-axis annotation
mms_load_state, probes=pid, trange = trange, /ephemeris
eph_gei = 'mms'+pid+'_defeph_pos'
eph_gse = 'mms'+pid+'_defeph_pos_gse'
eph_gsm = 'mms'+pid+'_defeph_pos_gsm'

; convert from gei to gsm coordinates
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
panels=[mode_var, tplotvar+'*_brst_srvy']
tplot, panels, var_label=position_vars

stop

end