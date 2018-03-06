;+
;
; This crib sheet shows how to save MMS data loaded into tplot variables to a CDF file
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-03-01 12:32:10 -0800 (Thu, 01 Mar 2018) $
; $LastChangedRevision: 24811 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_tplot2cdf_crib.pro $
;-

trange = ['2015-10-16', '2015-10-17']

; load MMS data and get electron fluxes and pitch angles distributions 
mms_load_feeps, trange=trange, probe=1, datatype='electron', level='l2'
mms_feeps_pad, probe=1, datatype='electron'

; /default keyword is required
tplot2cdf, /default, filename='test', tvars=['mms1_epd_feeps_srvy_l2_electron_intensity_omni','mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']

end