;+
;NAME:
; run_sta_L2gen
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes. It the lock file exists, no processing
;CALLING SEQUENCE:
; run_sta_l2gen, noffset_sec = noffset_sec
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; none
;HISTORY:
; 25-jun-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-06-27 15:03:05 -0700 (Fri, 27 Jun 2014) $
; $LastChangedRevision: 15460 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/run_sta_l2gen.pro $
;-

Pro run_sta_l2gen

  test_file = file_search('/tmp/STAL2lock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /tmp/STAL2lock.txt Exists, Returning'
  Endif Else Begin
     file_touch, test_file[0]
     mvn_call_sta_l2gen
     message, /info, 'Removing Lock file /tmp/STAL2lock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

