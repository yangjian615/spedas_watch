

mms_init;, local_data_dir='/Users/frwi7273/data/mms/'


Re = 6378.137


;timespan, '2015-05-11/00:00:00', 24, /hour

timespan, '2015-06-22/19:00:00', 1, /hour
;timespan, '2015-06-26/00:00:00', 24, /hour



mms_sitl_get_hpca_basic, sc_id='mms1'

mms_sitl_get_hpca_moments, sc_id='mms1'

mms_sitl_get_dfg, sc_id=['mms1','mms2','mms3','mms4']

get_data, 'mms1_ql_pos_gsm', data = mms1_ephem

ephem_times = mms1_ephem.x
mms1_x = mms1_ephem.y(*,0)/Re
mms1_y = mms1_ephem.y(*,1)/Re
mms1_z = mms1_ephem.y(*,2)/Re
mms1_r = sqrt(mms1_x^2 + mms1_y^2 + mms1_z^2)

store_data, 'mms1_x', data = {x:ephem_times, y:mms1_x}
options, 'mms1_x', 'ytitle', 'MMS1 X'
store_data, 'mms1_y', data = {x:ephem_times, y:mms1_y}
options, 'mms1_y', 'ytitle', 'MMS1 Y'
store_data, 'mms1_z', data = {x:ephem_times, y:mms1_z}
options, 'mms1_z', 'ytitle', 'MMS1 Z'
store_data, 'mms1_r', data = {x:ephem_times, y:mms1_r}
options, 'mms1_r', 'ytitle', 'R'



;print,'Stop1' & stop  

;=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%
;      H+
;    flux
options,'mms1_hpca_hplus_count_rate','spec',1 
options, 'mms1_hpca_hplus_count_rate','ylog',1
options, 'mms1_hpca_hplus_count_rate','zlog',1
options, 'mms1_hpca_hplus_count_rate','no_interp',1
options, 'mms1_hpca_hplus_count_rate','ytitle','H+ (eV)'
options, 'mms1_hpca_hplus_count_rate','ztitle','counts'
ylim,    'mms1_hpca_hplus_count_rate', 1, 40000.
zlim,    'mms1_hpca_hplus_count_rate', .1, 2000.

;    data quality
;ylim, 'mms1_hpca_hplus_data_quality',0, 255.
;options, 'mms1_hpca_hplus_data_quality','ytitle','Data Quality'

options,'mms1_hpca_heplusplus_count_rate','spec',1 
options, 'mms1_hpca_heplusplus_count_rate','ylog',1
options, 'mms1_hpca_heplusplus_count_rate','zlog',1
options, 'mms1_hpca_heplusplus_count_rate','no_interp',1
options, 'mms1_hpca_heplusplus_count_rate','ytitle','He++ (eV)'
options, 'mms1_hpca_heplusplus_count_rate','ztitle','counts'
ylim,    'mms1_hpca_heplusplus_count_rate', 1, 40000.
zlim,    'mms1_hpca_heplusplus_count_rate', .1, 2000.

options,'mms1_hpca_heplus_count_rate','spec',1 
options, 'mms1_hpca_heplus_count_rate','ylog',1
options, 'mms1_hpca_heplus_count_rate','zlog',1
options, 'mms1_hpca_heplus_count_rate','no_interp',1
options, 'mms1_hpca_heplus_count_rate','ytitle','He+ (eV)'
options, 'mms1_hpca_heplus_count_rate','ztitle','counts'
ylim,    'mms1_hpca_heplus_count_rate', 1, 40000.
zlim,    'mms1_hpca_heplus_count_rate', .1, 2000.

options,'mms1_hpca_oplus_count_rate','spec',1 
options, 'mms1_hpca_oplus_count_rate','ylog',1
options, 'mms1_hpca_oplus_count_rate','zlog',1
options, 'mms1_hpca_oplus_count_rate','no_interp',1
options, 'mms1_hpca_oplus_count_rate','ytitle','O+ (eV)'
options, 'mms1_hpca_oplus_count_rate','ztitle','counts'
ylim,    'mms1_hpca_oplus_count_rate', 1, 40000.
zlim,    'mms1_hpca_oplus_count_rate', .1, 2000.

ylim, 'mms1_hpca_hplus_number_density', 1, 100
options, 'mms1_hpca_hplus_number_density', 'ylog', 1
options, 'mms1_hpca_hplus_number_density', 'ytitle', 'h!U+!N, cm!U-3!N'

ylim, 'mms1_hpca_aplus_number_density', 1, 10
options, 'mms1_hpca_aplus_number_density', 'ylog', 1
options, 'mms1_hpca_aplus_number_density', 'ytitle', 'he!U+!!U+!N, cm!U-3!N'

ylim, 'mms1_hpca_heplus_number_density', 1, 100
options, 'mms1_hpca_heplus_number_density', 'ylog', 1
options, 'mms1_hpca_heplus_number_density', 'ytitle', 'he!U+!N, cm!U-3!N'

ylim, 'mms1_hpca_oplus_number_density', 1, 100
options, 'mms1_hpca_oplus_number_density', 'ylog', 1
options, 'mms1_hpca_oplus_number_density', 'ytitle', 'o!U+!N, cm!U-3!N'

ylim, 'mms1_hpca_hplusoplus_number_densities', 1, 100
options, 'mms1_hpca_hplusoplus_number_densities', 'ylog', 1
options, 'mms1_hpca_hplusoplus_number_densities', colors = [2,4]
options, 'mms1_hpca_hplusoplus_number_densities', 'ytitle', 'cm!U-3!N'
options, 'mms1_hpca_hplusoplus_number_densities', labels=['h!U+!N', 'o!U+!N']
options, 'mms1_hpca_hplusoplus_number_densities','labflag',-1

ylim, 'mms1_hpca_hplus_bulk_velocity', -300, 300
options, 'mms1_hpca_hplus_bulk_velocity', 'ylog', 0
options, 'mms1_hpca_hplus_bulk_velocity', colors = [6,4,2]
options, 'mms1_hpca_hplus_bulk_velocity', 'ytitle', 'h!U+!N km s!U-1!N'
options, 'mms1_hpca_hplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, 'mms1_hpca_hplus_bulk_velocity','labflag',-1

ylim, 'mms1_hpca_oplus_bulk_velocity', -300, 300
options, 'mms1_hpca_oplus_bulk_velocity', 'ylog', 0
options, 'mms1_hpca_oplus_bulk_velocity', colors = [6,4,2]
options, 'mms1_hpca_oplus_bulk_velocity', 'ytitle', 'o!U+!N km s!U-1!N'
options, 'mms1_hpca_oplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, 'mms1_hpca_oplus_bulk_velocity','labflag',-1

WINDOW, 1, XSIZE=1000, YSIZE=700
tplot, ['mms1_hpca_hplus_count_rate','mms1_hpca_heplusplus_count_rate',$
  'mms1_hpca_oplus_count_rate','mms1_hpca_hplusoplus_number_densities',$
   'mms1_hpca_hplus_bulk_velocity','mms1_hpca_oplus_bulk_velocity'], window=1;, var_label=['mms1_r','mms1_z','mms1_y','mms1_x']


end

