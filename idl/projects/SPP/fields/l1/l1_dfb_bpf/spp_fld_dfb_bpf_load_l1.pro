pro spp_fld_dfb_bpf_load_l1, file, prefix = prefix

  if n_elements(file) LT 1 then begin
    print, 'Must provide a CDF file to load"
    return
  endif

  bpf_ind = strmid(prefix, strlen(prefix)-2, 1)

  if strpos(prefix, 'ac_bpf') NE -1 then is_ac = 1 else is_ac = 0
  if is_ac then ac_dc_str = 'AC' else ac_dc_str = 'DC'

  cdf2tplot, file, prefix = prefix, varnames = varnames

  bpf_number = fix(strmid(prefix,1,1,/rev))

  case bpf_number of
    1: colors = 6 ; red
    2: colors = 4 ; green
    3: colors = 2 ; blue
    4: colors = 1 ; magenta
  endcase

  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'colors', colors
  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'psym', bpf_number + 3
  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'panel_size', 0.75
  options, prefix + ['enable','rslt_sel','src_sel','cad_sel'], 'ysubtitle', ''

  options, prefix + 'src_sel', 'labels', [string(bpf_number,format='(I1)')]

  options, prefix + 'peak', 'spec', 1
  options, prefix + 'peak', 'no_interp', 1

  options, prefix + 'avg', 'spec', 1
  options, prefix + 'avg', 'no_interp', 1

  if is_ac then $
    freq_bins = spp_get_bp_bins_04_ac() else $
    freq_bins = spp_get_bp_bins_04_dc()

  get_data, prefix + 'peak', data = peak_data

  if size(peak_data, /type) EQ 8 then begin

    store_data, prefix + 'peak_converted', $
      data = {x:peak_data.x, $
      y:spp_fld_dfb_psuedo_log_decompress(peak_data.y, type = 'bandpass'), $
      v:freq_bins.freq_avg}

    options, prefix + 'peak_converted', 'panel_size', 2
    options, prefix + 'peak_converted', 'spec', 1
    options, prefix + 'peak_converted', 'no_interp', 1
    options, prefix + 'peak_converted', 'ylog', 1
    options, prefix + 'peak_converted', 'ystyle', 1
    options, prefix + 'peak_converted', 'yrange', minmax(freq_bins.freq_avg)
    options, prefix + 'peak_converted', 'ysubtitle', 'Freq [Hz]'

  endif

  get_data, prefix + 'avg', data = avg_data

  if size(avg_data, /type) EQ 8 then begin

    store_data, prefix + 'avg_converted', $
      data = {x:avg_data.x, $
      y:spp_fld_dfb_psuedo_log_decompress(avg_data.y, type = 'bandpass'), $
      v:freq_bins.freq_avg}

    options, prefix + 'avg_converted', 'panel_size', 2
    options, prefix + 'avg_converted', 'spec', 1
    options, prefix + 'avg_converted', 'no_interp', 1
    options, prefix + 'avg_converted', 'ylog', 1
    options, prefix + 'avg_converted', 'ystyle', 1
    options, prefix + 'avg_converted', 'yrange', minmax(freq_bins.freq_avg)
    options, prefix + 'avg_converted', 'ysubtitle', 'Freq [Hz]'

  endif

  bpf_names = tnames(prefix + '*')

  if bpf_names[0] NE '' then begin

    for i = 0, n_elements(bpf_names) - 1 do begin

      bpf_name_i = strmid(bpf_names[i], strlen(prefix))

      ytitle_i = bpf_name_i

      if bpf_name_i EQ 'peak_converted' then ytitle_i = 'peak'
      if bpf_name_i EQ 'avg_converted' then ytitle_i = 'avg'

      options, prefix + bpf_name_i, 'ytitle', 'SPP DFB!C' + ac_dc_str+ ' BPF' + $
        string(bpf_ind) + '!C' + strupcase(ytitle_i)

    endfor

  endif

  all_prefix = strmid(prefix, 0, strlen(prefix) - 2)

  src_names = tnames(all_prefix + '?_src_sel')

  store_data, all_prefix + 'all_src_sel', data = src_names

  options, all_prefix + 'all_src_sel', 'yrange', [-0.5,15.5]
  options, all_prefix + 'all_src_sel', 'ystyle', 1
  options, all_prefix + 'all_src_sel', 'panel_size', 2.0
  options, all_prefix + 'all_src_sel', 'ytitle', 'SPP DFB!C' + ac_dc_str + ' BPF!CSRC_SEL'

  if varnames[0] EQ '' then begin

    dprint, 'No variables found in file ' + file, dlevel = 2

    return

  endif

end