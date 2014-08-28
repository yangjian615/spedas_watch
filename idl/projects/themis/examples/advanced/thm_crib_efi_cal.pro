;+
;NAME:
; thm_crib_efi_cal
;PURPOSE:
; Allows comparison of calibrated, semi-calibrated and raw EFI data
;CALLING SEQUENCE:
; thm_crib_efi_cal, date = date, probe = probe, datatype = datatype, $
;                   trange = trange, /split_components
;INPUT:
; None explicit
;OUTPUT:
; No explicit output, a bunch of tplot variables are created for the
; given probe, date and datatype;for example, for probe='c' and
; datatype='eff', then varibles named: 'tha_eff_raw',
; 'tha_eff_no_edc_offset', 'tha_eff_calfile_edc_offset', and
; 'tha_eff_full' are created.
;  Variable: tha_raw contains raw data
;  Variable: tha_no_edc_offset contains data in physical units --
;             with no EDC offsets subtracted from the spin-plane components E12 and E34.
;  Variable: tha_calfile_edc_offset contains data in physical units -- 
;             with EDC offsets obtained from the calibration file subtracted 
;             from the spin-plane components E12 and E34.
;  Variable: tha_full contains data in physical units -- 
;             with spin-averaged EDC offsets from the spin-plane components E12 and E34.
;KEYWORDS:
; date = the date for the data needed, not used if trange is set. The
;        default is '2010-01-01'
; probe = probe, one of 'a', 'b', 'c','d', 'e'. The default is 'a'.
; datatype = the tye of EFI field data to be used, 'eff', 'efp',
;            'efw'. The default is 'eff'.
; trange = an input time range, will supercede the date keyword
; split_components = if set, then call split_vec on the outputs to
;                    compare individual components
;HISTORY:
; 20-sep-2010, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 11:14:02 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13081 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_efi_cal.pro $
;-

Pro thm_crib_efi_cal, date = date, probe = probe, datatype = datatype, $
                      split_components = split_components, trange = trange, $
                      _extra = _extra

;Initialize inputs: note minimal error checking is designed to force
;the user to use one datatype at a time and one probe at a time.
;time
  If(keyword_set(trange)) Then Begin
    tr = time_double(trange)
  Endif Else Begin
    If(keyword_set(date)) Then Begin
      tr = time_double(date)+[0.0d0, 86400.0d0]
    Endif Else tr = time_double('2010-01-01')+[0.0d0, 86400.0d0]
  Endelse
;probe
  If(keyword_set(probe)) Then sc = strlowcase(strcompress(/remove_all, probe[0])) $
  Else sc = 'a'
  ok =  where(sc Eq ['a', 'b', 'c', 'd', 'e'], nok)
  If(nok Eq 0) Then Begin
    message, /info, 'Bad probe: mut be one of a, b, c, d, e'
    Return
  Endif
;datatype
  If(keyword_set(datatype)) Then dt = strlowcase(strcompress(/remove_all, datatype[0])) $
  Else dt = 'eff'
  ok = where(dt Eq ['eff', 'efp', 'efw'], nok)
  If(nok Eq 0) Then Begin
    message, /info, 'Bad Datatype: must be one of efs, eff, efw'
    Return
  Endif
;Load data, use suffixes to denote the different stages of data:
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, type = 'raw', suffix = '_raw'
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, /no_edc_offset, suffix = '_no_edc_offset'
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, /calfile_edc_offset, suffix = '_calfile_edc_offset'
;For comparison sake, set the output coordinate system to 'spg'
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, coord = 'spg', suffix = '_full'
;print out an explanation
  thxv = 'th'+sc[0]+'_'+dt[0]
  print, 'Variable: '+thxv+'_raw contains raw data'
  print, 'Variable: '+thxv+'_no_edc_offset contains data in physical units -- '
  print, '           with no EDC offsets subtracted from the spin-plane components E12 and E34.'
  print, 'Variable: '+thxv+'_calfile_edc_offset contains data in physical units -- '
  print, '           with EDC offsets obtained from the calibration file subtracted '
  print, '           from the spin-plane components E12 and E34.'
  print, 'Variable: '+thxv+'_full contains data in physical units -- '
  print, '           with spin-averaged EDC offsets from the spin-plane components E12 and E34.'
  If(keyword_set(split_components)) Then Begin
    split_vec, thxv+'_raw'
    split_vec, thxv+'_no_edc_offset'
    split_vec, thxv+'_calfile_edc_offset'
    split_vec, thxv+'_full'
  Endif

  Return
End


