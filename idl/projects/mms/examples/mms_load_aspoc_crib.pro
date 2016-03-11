;+
; MMS ASPOC crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-10 13:15:32 -0800 (Thu, 10 Mar 2016) $
; $LastChangedRevision: 20392 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_aspoc_crib.pro $
;-

;;  example  for mms1
scid='1'

;; load l2  data for MMS 1    (merged data for aspoc1 and aspoc2)
mms_load_aspoc, trange=['2015-07-15', '2015-07-16'], probe=scid, level='l2'

;; Make tplot parameter for combined aspoc ioncurrent using l2 data
;;
join_vec, 'mms'+scid+['_aspoc_ionc_l2', '_asp1_ionc_l2', '_asp2_ionc_l2'], 'mms'+scid+'_asp_ionc_all'

; plot ioncurrent from aspoc1, aspoc2, and total current,  all current in one panel,  onboard processed spacecraft potential
;
tplot, 'mms'+scid+['_asp1_ionc_l2','_asp2_ionc_l2','_aspoc_ionc_l2','_asp_ionc_all'], trange=trange0
stop


end