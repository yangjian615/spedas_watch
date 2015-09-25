;+
; MMS EDI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-24 09:31:48 -0700 (Thu, 24 Sep 2015) $
; $LastChangedRevision: 18915 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_edi_crib.pro $
;-

timespan, '2015-09-6', 1, /day
probe = '1'

mms_load_edi, data_rate='srvy', probes=1, datatype='efield', level='ql'

tplot, 'mms'+probe+['_edi_E_dmpa', $ electric field (computed via the "bestarg" method)
                    '_edi_E_bc_dmpa', $ ; electric field (computed via the "beam convergence" method)
                    '_edi_v_ExB_dmpa', $ ; ExB drift velocity (computed via the "bestarg" method)
                    '_edi_v_ExB_bc_dmpa'] ; ExB drift velocity (computed via the "beam convergence" method)
stop
end