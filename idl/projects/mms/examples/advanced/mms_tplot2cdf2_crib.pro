;+
;
; Warning: this file is under development!
;
; Example of tplot2cdf2 
; It is originally designed for testing purpuses
; This examples loads and processes data from MMS mission. It saves the results into the cdf file using tplot variables.
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-23 20:19:00 -0800 (Tue, 23 Jan 2018) $
; $LastChangedRevision: 24572 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_tplot2cdf2_crib.pro $
;-

del_data, '*'

trange = ['2015-12-15', '2015-12-16']

; load mms data and get electron fluxes and pitch angles distributions 
mms_load_feeps, trange=trange, probe=1, datatype='electron', level='l2'
mms_feeps_pad,  probe=1, datatype='electron'


tplot_names
; select following:
;mms1_epd_feeps_srvy_l2_electron_intensity_omni
;mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin


tvars = ['mms1_epd_feeps_srvy_l2_electron_intensity_omni','mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']
; set the file na
tplot2cdf2, filename='test', tvars=tvars, /default 

end