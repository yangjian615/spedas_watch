pro spp_fld_rfs_auto_load_l1, file, prefix = prefix

  prefix = 'spp_fld_rfs_hfr_auto_'
  
  cdf2tplot, file, prefix = prefix
  
  options, 'spp_fld_rfs_hfr_auto_compression', 'yrange', [-0.5, 1.5]
  options, 'spp_fld_rfs_hfr_auto_compression', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_compression', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_compression', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_compression', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_compression', 'panel_size', 0.5
  options, 'spp_fld_rfs_hfr_auto_compression', 'ytitle', 'HFR Auto!CCmprs'

  options, 'spp_fld_rfs_hfr_auto_peaks', 'yrange', [-0.5, 1.5]
  options, 'spp_fld_rfs_hfr_auto_peaks', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_peaks', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_peaks', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_peaks', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_peaks', 'panel_size', 0.5
  options, 'spp_fld_rfs_hfr_auto_peaks', 'ytitle', 'HFR Auto!CPks En'

  options, 'spp_fld_rfs_hfr_auto_averages', 'yrange', [-0.5, 1.5]
  options, 'spp_fld_rfs_hfr_auto_averages', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_averages', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_averages', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_averages', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_averages', 'panel_size', 0.5
  options, 'spp_fld_rfs_hfr_auto_averages', 'ytitle', 'HFR Auto!CAvg En'

  options, 'spp_fld_rfs_hfr_auto_gain', 'yrange', [-0.5, 1.5]
  options, 'spp_fld_rfs_hfr_auto_gain', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_gain', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_gain', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_gain', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_gain', 'panel_size', 0.5
  options, 'spp_fld_rfs_hfr_auto_gain', 'ytitle', 'HFR Auto!CGain'

  options, 'spp_fld_rfs_hfr_auto_hl', 'yrange', [-0.5, 3.5]
  options, 'spp_fld_rfs_hfr_auto_hl', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_hl', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_hl', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_hl', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_hl', 'panel_size', 0.5
  options, 'spp_fld_rfs_hfr_auto_hl', 'ytitle', 'HFR Auto!CHL'

  options, 'spp_fld_rfs_hfr_auto_nsum', 'yrange', [0, 128]
  options, 'spp_fld_rfs_hfr_auto_nsum', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_nsum', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_nsum', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_nsum', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_nsum', 'ytitle', 'HFR Auto!CNSUM'

  options, 'spp_fld_rfs_hfr_auto_ch?', 'yrange', [-0.5, 7.5]
  options, 'spp_fld_rfs_hfr_auto_ch?', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_ch?', 'yminor', 1
  options, 'spp_fld_rfs_hfr_auto_ch?', 'psym', 4
  options, 'spp_fld_rfs_hfr_auto_ch?', 'symsize', 0.5
  options, 'spp_fld_rfs_hfr_auto_ch0', 'ytitle', 'HFR Auto!CCH0 Source'
  options, 'spp_fld_rfs_hfr_auto_ch1', 'ytitle', 'HFR Auto!CCH1 Source'

  options, 'spp_fld_rfs_hfr_auto_spec0_ch?', 'spec', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?', 'no_interp', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?', 'yrange', [0.,64.]
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?', 'datagap', -1

  options, 'spp_fld_rfs_hfr_auto_spec0_ch0', 'ytitle', 'HFR Auto!CSpec0 Ch0 Raw'
  options, 'spp_fld_rfs_hfr_auto_spec0_ch1', 'ytitle', 'HFR Auto!CSpec0 Ch1 Raw'
 
  get_data, 'spp_fld_rfs_hfr_auto_spec0_ch0', data = rfs_hfr_dat_spec0_ch0
  rfs_freqs = spp_fld_rfs_freqs()
  store_data, 'spp_fld_rfs_hfr_auto_spec0_ch0_converted', $
    data = {x:rfs_hfr_dat_spec0_ch0.x, y:rfs_float(rfs_hfr_dat_spec0_ch0.y), $
    v:rfs_freqs.reduced_freq}

  get_data, 'spp_fld_rfs_hfr_auto_spec0_ch1', data = rfs_hfr_dat_spec0_ch1
  rfs_freqs = spp_fld_rfs_freqs()
  store_data, 'spp_fld_rfs_hfr_auto_spec0_ch1_converted', $
    data = {x:rfs_hfr_dat_spec0_ch1.x, y:rfs_float(rfs_hfr_dat_spec0_ch1.y), $
    v:rfs_freqs.reduced_freq}


  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'spec', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'no_interp', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'ylog', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'zlog', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'yrange', [1.e6,2.e7]
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'ystyle', 1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'datagap', -1
  options, 'spp_fld_rfs_hfr_auto_spec0_ch?_converted', 'panel_size', 2.

  options, 'spp_fld_rfs_hfr_auto_spec0_ch0_converted', 'ytitle', 'HFR Auto!CSpec0 Ch0'
  options, 'spp_fld_rfs_hfr_auto_spec0_ch1_converted', 'ytitle', 'HFR Auto!CSpec0 Ch1'



end