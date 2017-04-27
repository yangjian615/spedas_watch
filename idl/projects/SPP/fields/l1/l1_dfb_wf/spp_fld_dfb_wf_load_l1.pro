pro spp_fld_dfb_wf_load_l1, file, prefix = prefix

  cdf2tplot, file, prefix = prefix
  
  options, 'dfb_wav_tap', 'yrange', [-1.,16.]
  options, 'dfb_wav_tap', 'ystyle', 1

  options, 'dfb_wav_tap', 'psym', 4
  options, 'dfb_wav_tap', 'symsize', 0.5

  options, 'dfb_compression', 'yrange', [-0.5,1.5]
  options, 'dfb_compression', 'ystyle', 1

  options, 'dfb_compression', 'psym', 4
  options, 'dfb_compression', 'symsize', 0.5

  options, 'dfb_wav_en', 'yrange', [-0.5,1.5]
  options, 'dfb_wav_en', 'ystyle', 1

  options, 'dfb_wav_en', 'psym', 4
  options, 'dfb_wav_en', 'symsize', 0.5

  options, 'dfb_wav_sel', 'yrange', [-1,16]
  options, 'dfb_wav_sel', 'ystyle', 1

  options, 'dfb_wav_sel', 'psym', 4
  options, 'dfb_wav_sel', 'symsize', 0.5

  get_data, 'wf_pkt_data', data = d
  get_data, 'dfb_wav_tap', data = d_tap
  
  all_wf_time = []
  all_wf_decompressed = []
  
  for i = 0, n_elements(d.x) - 1 do begin
    
    wf_compressed0 = d.y[i,*]
    
    wf_compressed = wf_compressed0[where(finite(wf_compressed0))]
    
    wf_decompressed = spp_dfb_wf_decompress(fix(wf_compressed), stopit = 0)
        
    all_wf_decompressed = [all_wf_decompressed, wf_decompressed]
    
    wf_time = d_tap.x[i] + dindgen(n_elements(wf_decompressed)) / (18750. / (2.^d_tap.y[i]))
    
    all_wf_time = [all_wf_time, wf_time]
    
  endfor
  
  store_data, 'dfb_wav_decompressed', dat = {x:all_wf_time, y:all_wf_decompressed}
  
;stop

end