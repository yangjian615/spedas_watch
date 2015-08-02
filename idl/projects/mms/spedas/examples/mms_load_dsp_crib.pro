;+
; MMS DSP crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-07-31 15:51:21 -0700 (Fri, 31 Jul 2015) $
; $LastChangedRevision: 18338 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_dsp_crib.pro $
;-

; NOTE: I'm planning on changing this to use mms_load_dsp, once I can get it to run on my machine
mms_load_data, instrument='dsp', trange=['2015-06-22', '2015-06-23'], $
    probes=[1, 2, 3, 4], datatype='epsd', level='l2', data_rate='fast'

options, 'mms?_dsp_epsd_*', spec=1, zlog=1, ylog=1
options, 'mms?_dsp_epsd_omni', zrange=[1e-14, 1e-4], yrange=[30, 1e5]

; show the omni-directional electric spectral density for all MMS spacecraft
tplot, 'mms?_dsp_epsd_omni'
stop

window, 1
tplot, 'mms1_dsp_epsd_?', window=1
stop

; now download the SCM spectral density
mms_load_data, instrument='dsp', trange=['2015-06-22', '2015-06-23'], $
    probes=[1, 2, 3, 4], datatype='bpsd', level='l2', data_rate='fast'

options, 'mms?_dsp_bpsd_*', spec=1, zlog=1, ylog=1
options, 'mms?_dsp_bpsd_omni', zrange=[1e-14, 10], yrange=[10, 1e4]

window, 2
; show the omni-directional SCM spectral density for all MMS spacecraft
tplot, 'mms?_dsp_bpsd_omni', window=2
stop

window, 3
; show the components of the SCM spectral density for MMS1
tplot, 'mms1_dsp_bpsd_scm?', window=3
stop

end