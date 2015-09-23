;+
; MMS EDI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-22 08:04:56 -0700 (Tue, 22 Sep 2015) $
; $LastChangedRevision: 18865 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_edi_crib.pro $
;-

timespan, '2015-09-6', 1, /day

mms_load_edi, data_rate='srvy', probes=1, datatype='efield', level='ql'

; plot the electric field (computed via the "bestarg" method)
tplot, 'mms1_edi_E_dmpa'
stop

; plot the electric field (computed via the "beam convergence" method)
tplot, 'mms1_edi_E_bc_dmpa'
stop

; plot the ExB drift velocity (computed via the "bestarg" method)
tplot, 'mms1_edi_v_ExB_dmpa'
stop

; plot the ExB drift velocity (computed via the "beam convergence" method)
tplot, 'mms1_edi_v_ExB_bc_dmpa'
stop


end