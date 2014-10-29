;+
;NAME:
;thm_efi_sdt_test
;PURPOSE:
;Checks houesekeeping data to flag the presence of EFI SDT (Sensor
;Diagnostic Tests).
;CALLING SEQUENCE:
;thm_efi_sdt_test, probe=probe, trange=trange
;INPUT:
;All via keyword
;OUTPUT:
;None explicit, instead the program creates a tplot variable with an
;sdt_flag for each HSK data point, 'th?_efi_sdt_flag' is set to 1, if
;there is an SDT.
;KEYWORDS:
;probe = The default is: ['a', 'b', 'c', 'd', 'e']
;trange  = (Optional) Time range of interest  (2 element array), if
;this is not set, the default is to use any timespan that has been
;previously set, and then to prompt the user. Note that if the input
;time range is not a full day, a full day's data is loaded
;HISTORY:
; 2014-10-13, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-10-27 12:53:44 -0700 (Mon, 27 Oct 2014) $
; $LastChangedRevision: 16041 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_efi_sdt_test.pro $
;-
Pro thm_efi_sdt_test, probe = probe, trange = trange, $
                      ibias_ddt = ibias_ddt, $
                      _extra=_extra
  

  If(keyword_set(ibias_ddt)) Then ibdt = ibias_ddt $
  Else ibdt = 12.5

  If (keyword_set(trange) && n_elements(trange) Eq 2) $
  Then tr = timerange(trange) $
  Else tr = timerange()

;Given the tr value, load the hsk data
  If(keyword_set(probe)) Then Begin
     sc = thm_valid_input(probe, 'probe', vinput='a b c d e', $
                          definput = ['a', 'b', 'c', 'd', 'e'], $
                          /include_all)
  Endif Else sc = ['a', 'b', 'c', 'd', 'e']

  thm_load_hsk, probe = sc, trange = tr

  thx = 'th'+sc
  nsc = n_elements(sc)
  For j = 0, nsc-1 Do Begin
     vhvars = tnames(thx[j]+['*ibias_raw', '*guard_raw', '*usher_raw'])
     If(n_elements(vhvars) Ne 3) Then Begin
        dprint, 'Insufficient HSK data'
        Return
     Endif
     deriv_data, vhvars
;Use the ibias data to create a flag
     bvar = tnames(thx[j]+'*ibias_raw_ddt')
     If(is_string(bvar) Eq 0) Then Begin
        dprint, 'Missing variable: '+thx[j]+'*ibias_raw_ddt'
        Continue
     Endif
     bvar = bvar[0]
     get_data, bvar, data = dbvar
     ny = n_elements(dbvar.y[0,*])
     For k = 0, ny-1 Do Begin
        If(k Eq 0) Then ck = abs(dbvar.y[*, k]) Gt ibdt $
        Else ck = ck + (abs(dbvar.y[*, k]) Gt ibdt)
     Endfor
     fvar =  thx[j]+'_efi_sdt_flag'
     store_data, fvar, data = {x:dbvar.x, y:ck/2.0}
     options, fvar, 'yrange', [0.0, 1.20]
  Endfor
End
