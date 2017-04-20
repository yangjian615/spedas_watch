;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-19 16:48:53 -0700 (Wed, 19 Apr 2017) $
;  $LastChangedRevision: 23200 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mag_hk_load_l1.pro $
;

pro spp_fld_mag_hk_load_l1, file, prefix = prefix

  cdf2tplot, file, prefix = prefix

  mag_hk_names = tnames(prefix + '*')
  
  foreach name, mag_hk_names do begin
    
    options, name, 'ynozero', 1
    options, name, 'psym', 4
    options, name, 'symsize', 0.5
    
  endforeach

end