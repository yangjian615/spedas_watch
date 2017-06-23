pro spp_fld_dfb_dc_spec_load_l1, file, prefix = prefix

  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_dc_spec_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, file, prefix = prefix, varnames = varnames

  options, prefix + ['enable','bin','src_sel','scm_rotate','gain','navg','concat'], 'colors', 6
  options, prefix + ['enable','bin','src_sel','scm_rotate','gain','navg','concat'], 'psym', 4
  options, prefix + ['enable','bin','src_sel','scm_rotate','gain','navg','concat'], 'panel_size', 0.75

end