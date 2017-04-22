;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-21 11:43:26 -0700 (Fri, 21 Apr 2017) $
;  $LastChangedRevision: 23207 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb2_hk/spp_fld_aeb2_hk_load_l1.pro $
;

pro spp_fld_aeb2_hk_load_l1, file

  prefix = 'spp_fld_aeb2_hk_'

  cdf2tplot, file, prefix = prefix

  aeb_hk_names = tnames(prefix + '*')

  if aeb_hk_names[0] NE '' then begin

    foreach name, aeb_hk_names do begin

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endforeach

  endif

end