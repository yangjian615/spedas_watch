;+
;NAME:
; mvn_lpw_anc_unset_spice_check
;PURPOSE:
; Unsets the 'kernel verified' flag in the mvn_spc_met_to_unixtime
; common block. Use this after clearing kernels, so that
; mvn_spc_met_to_unixtime doesn't crash
;CALLING SEQUENCE:
; mvn_lpw_anc_unset_spice_check
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-02-11 14:26:26 -0800 (Wed, 11 Feb 2015) $
; $LastChangedRevision: 16959 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/lpw/mvn_lpw_anc_unset_spice_check.pro $
;-
Pro mvn_lpw_anc_unset_spice_check

  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed  , kernel_verified, time_verified, sclk,tls
  undefine, kernel_verified

Return
End
