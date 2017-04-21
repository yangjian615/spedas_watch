;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2017-04-20 14:59:32 -0700 (Thu, 20 Apr 2017) $
;  $LastChangedRevision: 23203 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dcb_analog_hk/spp_fld_dcb_analog_hk_load_l1.pro $

pro spp_fld_dcb_analog_hk_load_l1, file

  prefix = 'spp_fld_dcb_analog_hk_'

  cdf2tplot, file, prefix = prefix

  dcb_hk_names = tnames(prefix + '*')

  if dcb_hk_names NE '' then begin

    for i = 0, n_elements(dcb_hk_names)-1 do begin

      name = dcb_hk_names[i]

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endfor

  endif

end