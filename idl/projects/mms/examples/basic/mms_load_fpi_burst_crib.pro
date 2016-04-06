;+
; MMS FPI burst mode crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-01 12:06:38 -0700 (Fri, 01 Apr 2016) $
; $LastChangedRevision: 20701 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fpi_burst_crib.pro $
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