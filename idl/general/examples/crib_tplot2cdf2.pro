;+
;
; Warning: this file is under development!
;
; Example of tplot2cdf2 
; It is designed for testing purpuses
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2017-12-22 00:22:23 -0800 (Fri, 22 Dec 2017) $
; $LastChangedRevision: 24457 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot2cdf2.pro $
;-

del_data, '*'

trange = ['2015-12-15', '2015-12-16']

; load mms data and get electron fluxes and pitch angles distributions 
mms_load_feeps, trange=trange, probe=1, datatype='electron', level='l2'
mms_feeps_pad,  probe=1, datatype='electron'

;loads themis particle data for data type and set electron fluxes and pitch angles distributions
thm_part_load,probe='a',trange=trange,datatype='psef'
thm_part_products,probe='a',datatype='psef',trange=trange,outputs=['energy','pa']


tplot_names
; select following:
;tha_psef_data
;tha_psef_count_rate
;mms1_epd_feeps_srvy_l2_electron_intensity_omni
;mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin


tvars = ['tha_psef_data','tha_psef_count_rate','mms1_epd_feeps_srvy_l2_electron_intensity_omni','mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']
tplot2cdf2, filename='test', tvars=tvars, /default 

end