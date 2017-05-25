;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-05-10 14:36:10 -0700 (Wed, 10 May 2017) $
;  $LastChangedRevision: 23294 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mag_hk_load_l1.pro $
;

pro spp_fld_mag_hk_load_l1, file, prefix = prefix, colors = colors

  cdf2tplot, file, prefix = prefix

  mag_hk_names = tnames(prefix + '*')
  
  foreach name, mag_hk_names do begin
    
    options, name, 'ynozero', 1
    options, name, 'psym', 4
    options, name, 'symsize', 0.5
    options, name, 'colors', colors
    
  endforeach
  
  mag_hk_raw_names = tnames(prefix + '*_raw')

  foreach name, mag_hk_raw_names do begin
    
    options, name, 'ytickformat', '(I8)'
    
  endforeach

end