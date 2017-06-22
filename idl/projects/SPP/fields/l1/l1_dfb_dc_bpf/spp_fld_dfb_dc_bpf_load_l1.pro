pro spp_fld_dfb_dc_bpf_load_l1, file, prefix = prefix

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_dc_bpf_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, file, prefix = prefix, varnames = varnames

  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'colors', 6
  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'psym', 4
  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'panel_size', 0.75
  

  options, prefix + 'peak', 'spec', 1
  options, prefix + 'peak', 'no_interp', 1

  options, prefix + 'avg', 'spec', 1
  options, prefix + 'avg', 'no_interp', 1

  get_data, prefix + 'peak', data = peak_data
  
  if size(peak_data, /type) EQ 8 then begin
    
    store_data, prefix + 'peak_converted', $
      data = {x:peak_data.x, y:spp_fld_dfb_psuedo_log_decompress(peak_data.y)}
    
    options, prefix + 'peak_converted', 'panel_size', 2
    options, prefix + 'peak_converted', 'spec', 1
    options, prefix + 'peak_converted', 'no_interp', 1
    
  endif
  
  get_data, prefix + 'avg', data = avg_data
  
  if size(avg_data, /type) EQ 8 then begin

    store_data, prefix + 'avg_converted', $
      data = {x:avg_data.x, y:spp_fld_dfb_psuedo_log_decompress(avg_data.y)}

    options, prefix + 'avg_converted', 'panel_size', 2
    options, prefix + 'avg_converted', 'spec', 1
    options, prefix + 'avg_converted', 'no_interp', 1

  endif


  if varnames[0] EQ '' then begin

    dprint, 'No variables found in file ' + file, dlevel = 2

    return

  endif

end