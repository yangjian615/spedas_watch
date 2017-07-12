pro spp_fld_dfb_spec_load_l1, file, prefix = prefix

  cdf2tplot, file, prefix = prefix, varnames = varnames

  status_items = ['enable','bin','src_sel','scm_rotate','gain','navg','concat']

  options, prefix + status_items, 'colors', 6
  options, prefix + status_items, 'psym', 4
  options, prefix + status_items, 'panel_size', 0.75

  options, prefix + 'spec', 'spec', 1

  options, prefix + 'src_sel', 'yrange', [-0.5,15.5]
  options, prefix + 'src_sel', 'ystyle', 1

  options, prefix + 'enable', 'yrange', [-0.25,1.25]
  options, prefix + 'enable', 'ystyle', 1

  options, prefix + 'bin', 'yrange', [-0.25,1.25]
  options, prefix + 'bin', 'ystyle', 1

  options, prefix + 'scm_rotate', 'yrange', [-0.25,1.25]
  options, prefix + 'scm_rotate', 'ystyle', 1

  options, prefix + 'gain', 'yrange', [-0.25,1.25]
  options, prefix + 'gain', 'ystyle', 1

  options, prefix + 'navg', 'yrange', [-0.5,15.5]
  options, prefix + 'navg', 'ystyle', 1

  options, prefix + 'concat', 'yrange', [-0.5,15.5]
  options, prefix + 'concat', 'ystyle', 1

  get_data, prefix + 'spec', data = spec_data

  get_data, prefix + 'bin', data = bin_data

  get_data, prefix + 'spec_nelem', data = nelem_data

  get_data, prefix + 'concat', data = concat_data

  ; TODO: Make this work with all configurations of spectra

  if size(spec_data, /type) EQ 8 then begin

    if n_elements(spec_data.x) GT 1 then begin

      ; TODO: Make this work when the number of elements in the spectrum change

      n_spec = concat_data.y[0] + 1
      n_bins = nelem_data.y[0] / n_spec

      if strpos(prefix, 'ac_spec') NE -1 then begin
        freq_bins = spp_get_fft_bins_04_ac(n_bins)
      endif else begin
        freq_bins = spp_get_fft_bins_04_dc(n_bins)
      endelse

      n_total = n_elements(spec_data.y)

      new_data_y = transpose(reform(reform(transpose(spec_data.y), n_total), $
        n_bins, n_total/n_bins))

      ; TODO: Make this more precise using TMlib time

      new_data_x = []
      delta_x = (spec_data.x[1] - spec_data.x[0]) / n_spec

      for i = 0, n_elements(spec_data.x)-1 do begin
        new_data_x = [new_data_x,spec_data.x[i] + delta_x * dindgen(n_spec)]
      endfor

      data_v = transpose(rebin(freq_bins.freq_avg,$
        n_elements(freq_bins.freq_avg),$
        n_elements(new_data_x)))

      store_data, prefix + 'spec_converted', $
        data = {x:new_data_x, $
        y:spp_fld_dfb_psuedo_log_decompress(new_data_y, type = 'spectra'), $
        v:data_v}

      options, prefix + 'spec_converted', 'panel_size', 2
      options, prefix + 'spec_converted', 'spec', 1
      options, prefix + 'spec_converted', 'no_interp', 1
      options, prefix + 'spec_converted', 'zlog', 1
      options, prefix + 'spec_converted', 'ylog', 1
      options, prefix + 'spec_converted', 'ystyle', 1
      options, prefix + 'spec_converted', 'yrange', minmax(freq_bins.freq_avg)

    endif

  endif

end