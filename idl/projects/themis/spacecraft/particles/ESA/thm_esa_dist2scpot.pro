;+
;NAME:
; thm_esa_dist2scpot
;CALLING SEQUENCE:
; scpot = thm_esa_dist2scpot(data)
;PURPOSE:
; Estimates the SC potential from an electron sepctrum, by comparing
; the slope of the electron energy distribution with the slope that
; would be expected from secondary electrons.
;INPUT:
; data = 3d data structure filled by themis routines get_th?_p???
;KEYWORDS:
; fit_npl = if set, fits the distribution to a multi-component power law
;HISTORY:
; Hacked from spec3d.pro, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-06-23 13:45:53 -0700 (Tue, 23 Jun 2015) $
; $LastChangedRevision: 17946 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_dist2scpot.pro $
;
;-
Function thm_esa_dist2scpot, tempdat, pr_slope = pr_slope, fit_npl = fit_npl, $
                             _extra=_extra

  If(~is_struct(tempdat) || tempdat.valid eq 0) Then Begin
     dprint, 'Invalid Data'
     return, -1
  endif

  data3d = conv_units(tempdat,'Eflux')
  data3d.data = data3d.data*data3d.denergy/(data3d.denergy+.00001)
  If(ndimen(data3d.data) Eq ndimen(data3d.bins)) Then data3d.data=data3d.data*data3d.bins

  nb = data3d.nbins

;Estimate potential by grabbing the lowest energy with a slope Gt M,
;where M is 2 at the low energy end, say 8 eV to 6 at 50 eV, to pick
;up photoelectrons.  The lower limit to the potential is the lowest
;energy, the upper limit will be 100 V

  nenergy = data3d.nenergy
  If(data3d.nbins Eq 1) Then odat2 = data3d Else odat2 = omni3d(data3d)
  energy = rotate(odat2.energy, 2)
  dist = rotate(odat2.data, 2)

;Fit this
  If(keyword_set(fit_npl)) Then Begin
     xxx = thm_esa_breakpln(dist, energy)
     If(is_struct(xxx)) Then Begin
        energy = xxx.x
        dist = xxx.fx
     Endif
;The energy array may have been reset if there are zero or non-finite dist values
     nenergy = n_elements(energy)
  Endif

  slope = alog10(dist[1:*]/dist[0:nenergy-2])/alog10(energy[1:*]/energy[0:nenergy-2])
;Also add a restriction that the slope should go positive at some
;point beyond the negative slope
  nen1 = n_elements(slope)
  pflag = bytarr(nen1)
  For j = 0, nen1-2 Do Begin
     pflj = where(slope[j+1:*] Gt 0, npflj)
     If(npflj Gt 0) Then pflag[j] = 1
  Endfor

;Note that these numbers are empirical, except for the lower linit,
;which is determined by the slope of the secondary electrons.
  yy0 = 2.0 & yy1 = 6.0
  xx0 = 8.0 & xx1 = 50.0
;  zz0 = 0.10                    ;test for positive slope
  bm = (yy0-yy1)/(xx0-xx1)
  am = yy0 - bm*xx0
  m = (am + bm * energy) > 2.0
;The magic slope is -m
  If(keyword_set(pr_slope)) Then print, slope, -m
  sltest = where(slope Lt -m and pflag Gt 0, nsltest)
  If(nsltest Eq 0 || (min(energy[sltest]) Gt 100.0)) Then Begin
     sc_pot_est = energy[0]
  Endif Else Begin
;Only do this if there is not too much positive slope below sltest[0]
     i = sltest[0]
     While (slope[i] Lt -m[i] and energy[i] Lt 100.0) Do Begin
        i = i+1
     Endwhile
;     print, -m[0:i], slope[0:i], energy[0:i]
     sc_pot_est = energy[i]
  Endelse

  Return, sc_pot_est

End
