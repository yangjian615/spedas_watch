pro spp_fld_load_l1, filename

  ; Load only the global attributes

  cdf_vars = cdf_load_vars(filename, verbose = -1)

  print, cdf_vars.g_attributes.LOGICAL_SOURCE

  load_procedure = cdf_vars.g_attributes.LOGICAL_SOURCE + '_load_l1'
  
  call_procedure, load_procedure, filename

end