;+
;NAME:
; fa_esa_pa
;PURPOSE:
; creates a pitch angle array for FAST ESA data;
;CALLING SEQUENCE:
; pa = fa_esa_pa(theta, theta_shift, mode_ind)
;INPUT:
; theta = an array of (96, 64, 2 or 3) of angle values
; theta_shift = an array of (ntimes) values for the offset to get
;               pitch angle from theta, PA = theta+theta_shift
; mode = 0, 1 (or 2) the mode index used to get the correct value of
;               theta_shift to apply for each time interval
;KEYWORDS:
; fillval = the fill value, the default is !values.f_nan
;HISTORY:
; 2015-08-28, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-02-02 14:00:09 -0800 (Tue, 02 Feb 2016) $
; $LastChangedRevision: 19875 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_pa.pro $
;-
Function fa_esa_pa, theta, theta_shift, mode_ind, fillval = fillval

  ntimes = n_elements(mode_ind)
  If(n_elements(theta_shift) Ne ntimes) Then Return, -1
;It turns pout that non-NaN fillvals cause weird results, so
; Set fillval to NaN, will reset after addition,
  If(keyword_set(fillval)) Then Begin
     fv = fillval
     ss_fv = where(theta Eq fv, nfv)
     If(nfv Gt 0) Then theta[ss_fv] = !values.f_nan
  Endif Else fv = !values.f_nan
  theta_out = fltarr(96, 64, ntimes) & theta_out[*] = !values.f_nan
  
  mode0 = where(mode_ind Eq 0, nmode0)
  If(nmode0 Gt 0) Then Begin
     For j = 0, nmode0-1 Do theta_out[0, 0, mode0[j]] = (theta[*, *, 0]+theta_shift[mode0[j]]) mod 360.0
  Endif
  mode1 = where(mode_ind Eq 1, nmode1)
  If(nmode1 Gt 0) Then Begin
     For j = 0, nmode1-1 Do theta_out[0, 0, mode1[j]] = (theta[*, *, 1]+theta_shift[mode1[j]]) mod 360.0
  Endif
  mode2 = where(mode_ind Eq 2, nmode2)
  If(nmode2 Gt 0) Then Begin
     For j = 0, nmode2-1 Do theta_out[0, 0, mode2[j]] = (theta[*, *, 2]+theta_shift[mode2[j]]) mod 360.0
  Endif
  If(keyword_set(fillval)) Then Begin
     ss_fv = where(~finite(theta_out), nfv)
     If(nfv Gt 0) Then theta_out[ss_fv] = fillval
  Endif
  Return, theta_out
End

