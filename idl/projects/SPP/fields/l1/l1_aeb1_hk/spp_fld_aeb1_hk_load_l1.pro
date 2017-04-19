;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-18 16:04:07 -0700 (Tue, 18 Apr 2017) $
;  $LastChangedRevision: 23186 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb1_hk/spp_fld_aeb1_hk_load_l1.pro $
;

pro spp_fld_aeb1_hk_load_l1, file

  prefix = 'spp_fld_aeb1_hk_'

  cdf2tplot, file, prefix = prefix

  aeb_hk_names = tnames(prefix + '*')

  foreach name, aeb_hk_names do begin
    
    options, name, 'ynozero', 1
    options, name, 'horizontal_ytitle', 1
    options, name, 'colors', [2]
    options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

    options, name, 'psym', 4
    options, name, 'symsize', 0.5
    
  endforeach

end