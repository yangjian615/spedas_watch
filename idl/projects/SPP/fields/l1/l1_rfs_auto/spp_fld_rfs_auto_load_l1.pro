pro spp_fld_rfs_auto_load_l1, file, prefix = prefix, color = color
  
  receiver_str = strupcase(strmid(prefix, 12, 3))
  
  if receiver_str EQ 'LFR' then lfr_flag = 1 else lfr_flag = 0

  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag)
  
  cdf2tplot, file, prefix = prefix
  
  options, prefix + 'compression', 'yrange', [0, 1]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'colors', color
  options, prefix + 'compression', 'yminor', 1
  options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.35
  options, prefix + 'compression', 'ytitle', receiver_str + ' Auto!CCmprs'

  options, prefix + 'peaks', 'yrange', [0, 1]
  options, prefix + 'peaks', 'ystyle', 1
  options, prefix + 'peaks', 'colors', color
  options, prefix + 'peaks', 'yminor', 1
  options, prefix + 'peaks', 'psym', 4
  options, prefix + 'peaks', 'symsize', 0.5
  options, prefix + 'peaks', 'panel_size', 0.35
  options, prefix + 'peaks', 'ytitle', receiver_str + ' Auto!CPks En'

  options, prefix + 'averages', 'yrange', [0, 1]
  options, prefix + 'averages', 'ystyle', 1
  options, prefix + 'averages', 'colors', color
  options, prefix + 'averages', 'yminor', 1
  options, prefix + 'averages', 'psym', 4
  options, prefix + 'averages', 'symsize', 0.5
  options, prefix + 'averages', 'panel_size', 0.35
  options, prefix + 'averages', 'ytitle', receiver_str + ' Auto!CAvg En'

  options, prefix + 'gain', 'yrange', [0, 1]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + ' Auto!CGain'

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
  options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + ' Auto!CHL'

  options, prefix + 'nsum', 'yrange', [0, 128]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + ' Auto!CNSUM'

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
  options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch0', 'ytitle', receiver_str + ' Auto!CCH0 Source'
  options, prefix + 'ch1', 'ytitle', receiver_str + ' Auto!CCH1 Source'

  options, prefix + 'spec0_ch?', 'spec', 1
  options, prefix + 'spec0_ch?', 'no_interp', 1
  options, prefix + 'spec0_ch?', 'yrange', [0,64]
  options, prefix + 'spec0_ch?', 'ystyle', 1
  options, prefix + 'spec0_ch?', 'datagap', 60

  options, prefix + 'spec0_ch0', 'ytitle', receiver_str + ' Auto!CSpec0 Ch0 Raw'
  options, prefix + 'spec0_ch1', 'ytitle', receiver_str + ' Auto!CSpec0 Ch1 Raw'
 
  get_data, prefix + 'spec0_ch0', data = rfs_hfr_dat_spec0_ch0

  store_data, prefix + 'spec0_ch0_converted', $
    data = {x:rfs_hfr_dat_spec0_ch0.x, y:rfs_float(rfs_hfr_dat_spec0_ch0.y), $
    v:rfs_freqs.reduced_freq}

  get_data, prefix + 'spec0_ch1', data = rfs_hfr_dat_spec0_ch1

  store_data, prefix + 'spec0_ch1_converted', $
    data = {x:rfs_hfr_dat_spec0_ch1.x, y:rfs_float(rfs_hfr_dat_spec0_ch1.y), $
    v:rfs_freqs.reduced_freq}

  options, prefix + 'spec0_ch?_converted', 'spec', 1
  options, prefix + 'spec0_ch?_converted', 'no_interp', 1
  options, prefix + 'spec0_ch?_converted', 'ylog', 1
  options, prefix + 'spec0_ch?_converted', 'zlog', 1
  options, prefix + 'spec0_ch?_converted', 'yrange', [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
  options, prefix + 'spec0_ch?_converted', 'ystyle', 1
  options, prefix + 'spec0_ch?_converted', 'datagap', 60
  options, prefix + 'spec0_ch?_converted', 'panel_size', 2.

  options, prefix + 'spec0_ch0_converted', 'ytitle', receiver_str + ' Auto!CSpec0 Ch0'
  options, prefix + 'spec0_ch1_converted', 'ytitle', receiver_str + ' Auto!CSpec0 Ch1'

  get_data, prefix + 'ch0', dat = ch0_src_dat
  if n_elements(uniq(ch0_src_dat.y) EQ 1) then $
    options, prefix + 'spec0_ch0_converted', 'ysubtitle', $
    'SRC:' + strcompress(string(ch0_src_dat.y[0]))

  get_data, prefix + 'ch1', dat = ch1_src_dat
  if n_elements(uniq(ch1_src_dat.y) EQ 1) then $
    options, prefix + 'spec0_ch1_converted', 'ysubtitle', $
    'SRC:' + strcompress(string(ch1_src_dat.y[0]))

  
end