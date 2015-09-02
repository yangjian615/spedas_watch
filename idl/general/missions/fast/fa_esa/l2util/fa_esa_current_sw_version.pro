;+
;NAME:
; fa_esa_current_sw_version
;PURPOSE:
; Records the current MAVEN STATIC SW version number
;CALLING SEQUENCE:
; version = fa_esa_current_sw_version()
;HISTORY:
; 2015-07-23
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-09-01 15:45:13 -0700 (Tue, 01 Sep 2015) $
; $LastChangedRevision: 18686 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_current_sw_version.pro $
;-
Function fa_esa_current_sw_version

; make the software version number common block - used for CDF file production
;	common fa_esa_software_version,ver & ver=0		; software version was "0" prior to 20141219
  common fa_esa_software_version,ver & ver=1 ; changed 20150118 when all SIS required elements were included in common blocks, some element not filled in
  
  Return, ver
End
