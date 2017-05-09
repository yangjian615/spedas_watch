pro spp_fld_dfb_dbm_load_l1, file, prefix = prefix

  cdf2tplot, file, prefix = prefix

  options, prefix + 'acdc', 'yrange', [-0.5, 1.5]
  options, prefix + 'acdc', 'psym', 4
  options, prefix + 'acdc', 'symsize', 0.5

  options, prefix + 'ftap', 'yrange', [-0.5, 6.5]
  options, prefix + 'ftap', 'psym', 4
  options, prefix + 'ftap', 'symsize', 0.5


end