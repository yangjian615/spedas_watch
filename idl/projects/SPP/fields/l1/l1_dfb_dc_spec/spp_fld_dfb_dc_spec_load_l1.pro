pro spp_fld_dfb_dc_spec_load_l1, file, prefix = prefix

  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_dc_spec_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, file, prefix = prefix, varnames = varnames

  status_items = ['enable','bin','src_sel','scm_rotate','gain','navg','concat']

  options, prefix + status_items, 'colors', 6
  options, prefix + status_items, 'psym', 4
  options, prefix + status_items, 'panel_size', 0.75

  options, prefix + 'dc_spec', 'spec', 1

  get_data, prefix + 'dc_spec', data = dc_spec_data

  ; TODO: Make this work with all configurations of DC spectra

  if size(dc_spec_data, /type) EQ 8 then begin

    n_bins = 56l
    n_spec = 16l

    n_total = n_elements(dc_spec_data.y)

    new_data_y = transpose(reform(reform(transpose(dc_spec_data.y), n_total), n_bins,n_total/n_bins))

  ; TODO: Make this more precise using TMlib time
    new_data_x = congrid(dc_spec_data.x, n_elements(dc_spec_data.x) * 16)

    store_data, prefix + 'dc_spec_converted', $
      data = {x:new_data_x, $
      y:spp_fld_dfb_psuedo_log_decompress(new_data_y, type = 'spectra'), $
      v:dindgen(n_bins)}

    options, prefix + 'dc_spec_converted', 'panel_size', 2
    options, prefix + 'dc_spec_converted', 'spec', 1
    options, prefix + 'dc_spec_converted', 'no_interp', 1
    options, prefix + 'dc_spec_converted', 'zlog', 1

  endif


end