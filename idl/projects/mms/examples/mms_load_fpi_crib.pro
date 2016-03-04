;+
; MMS FPI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-03 13:57:03 -0800 (Thu, 03 Mar 2016) $
; $LastChangedRevision: 20318 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fpi_crib.pro $
;-

timespan, '2015-12-15', 1, /day
probe = '4'
datatype = ['des-moms'] ; DES moments file (contains spectra and pitch angle distributions)
level = 'l2'
data_rate = 'fast'

mms_load_fpi, probes = probe, datatype = datatype, level = level, data_rate = data_rate

prefix = 'mms'+strcompress(string(probe), /rem)

; plot the pitch angle distribution
tplot, prefix+'_des_pitchangdist_avg'

; add the omni-directional electron spectra
tplot, prefix+'_des_energyspectr_omni_avg', /add

end