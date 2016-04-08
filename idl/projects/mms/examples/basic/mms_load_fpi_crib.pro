;+
; MMS FPI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-07 15:53:03 -0700 (Thu, 07 Apr 2016) $
; $LastChangedRevision: 20750 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fpi_crib.pro $
;-

timespan, '2015-12-15', 1, /day
probe = '4'
datatype = ['des-moms', 'dis-moms'] ; DES/DIS moments file (contains moments, as well as spectra and pitch angle distributions)
level = 'l2'
data_rate = 'fast'

mms_load_fpi, probes = probe, datatype = datatype, level = level, data_rate = data_rate

prefix = 'mms'+strcompress(string(probe), /rem)

; plot the pitch angle distribution
tplot, prefix+'_des_pitchangdist_avg'

; add the omni-directional electron spectra
tplot, prefix+'_des_energyspectr_omni_avg', /add

; add the ion density
tplot, prefix+'_dis_numberdensity_dbcs_fast', /add

; and the electron density...
tplot, prefix+'_des_numberdensity_dbcs_fast', /add
end