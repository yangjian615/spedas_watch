;+
; MMS FPI burst mode crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-03 15:17:41 -0800 (Thu, 03 Mar 2016) $
; $LastChangedRevision: 20322 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fpi_burst_crib.pro $
;-

trange = ['2015-10-16/13:05', '2015-10-16/13:10']
probe = '4'
datatype = ['des-moms', 'dis-moms']
level = 'l2'
data_rate = 'brst'

mms_load_fpi, probes=probe, trange=trange, datatype=datatype, level=level, data_rate=data_rate

prefix = 'mms'+strcompress(string(probe), /rem)

; plot the electron pitch angle distribution
tplot, prefix+'_des_pitchangdist_avg'

; add the omni-directional electron spectra
tplot, prefix+'_des_energyspectr_omni_avg', /add
stop

; add the omni-directional ion spectra
tplot, prefix+'_dis_energyspectr_omni_avg', /add
end