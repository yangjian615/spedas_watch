pro spp_fld_rfs_rawspectra_load_l1, file, prefix = prefix

  ;  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_rawspectra_'
  ;
  ;  if typename(file) EQ 'UNDEFINED' then begin
  ;
  ;    dprint, 'No file provided to spp_fld_dfb_wf_load_l1', dlevel = 2
  ;
  ;    return
  ;
  ;  endif
  ;
  ;  cdf2tplot, file, prefix = prefix

  ; Some definitions

  n_wf = 32768l
  f_wf = 38.4e6
  n_fft = 4096l

  freq_hfr = spp_fld_rfs_freqs()
  freq_lfr = spp_fld_rfs_freqs(/lfr)

  get_data, 'spp_fld_rfs_rawspectra_ch0', data = dat_ch0

  get_data, 'spp_fld_rfs_rawspectra_ch0', data = dat_ch1

  get_data, 'spp_fld_rfs_rawspectra_algorithm', data = dat_algorithm

  hfr_ind = where(dat_algorithm.y EQ 1, hfr_count, $
    complement = lfr_ind, ncomplement = lfr_count)

  dat_v = dblarr(n_fft/2,n_elements(dat_algorithm.y))

  if hfr_count GT 0 then dat_v[*, hfr_ind] = rebin(freq_hfr.full_freq[1:*], n_fft/2, hfr_count, /sample)
  if lfr_count GT 0 then dat_v[*, lfr_ind] = rebin(freq_lfr.full_freq[1:*], n_fft/2, lfr_count, /sample)

  get_data, 'spp_fld_rfs_rawspectra_ch0_re', data = dat_ch0_re
  get_data, 'spp_fld_rfs_rawspectra_ch0_im', data = dat_ch0_im

  ch0_comp = dcomplex(dat_ch0_re.y, dat_ch0_im.y)

  ch0_pow = abs(ch0_comp)

  store_data, 'spp_fld_rfs_sp_ch0_pow', $
    data = {x:dat_ch0_re.x, y:ch0_pow, v:transpose(dat_v)}, $
    dlim = {spec:1, ystyle:1, ylog:1, zlog:1, yrange:[1.e3,1.e8], $
    no_interp:1}

  get_data, 'spp_fld_rfs_rawspectra_ch1_re', data = dat_ch1_re
  get_data, 'spp_fld_rfs_rawspectra_ch1_im', data = dat_ch1_im

  ch1_comp = dcomplex(dat_ch1_re.y, dat_ch1_im.y)

  ch1_pow = abs(ch1_comp)

  store_data, 'spp_fld_rfs_sp_ch1_pow', $
    data = {x:dat_ch1_re.x, y:ch1_pow, v:transpose(dat_v)}, $
    dlim = {spec:1, ystyle:1, ylog:1, zlog:1, yrange:[1.e3,1.e8], $
    no_interp:1}


  chs = [0,1]

  algs = [0,1]

  srcs = [0,1,2,3,4,5,6,7]

  foreach ch, chs do begin

    if ch EQ 0 then begin

      src_data = dat_ch0.y
      re_data = dat_ch0_re.y
      im_data = dat_ch0_im.y
      pow_data = ch0_pow

    endif else begin

      src_data = dat_ch1.y
      re_data = dat_ch1_re.y
      im_data = dat_ch1_im.y
      pow_data = ch1_pow

    endelse

    foreach alg, algs do begin

      foreach src, srcs do begin

        alg_match = where(dat_algorithm.y EQ alg, alg_count)
        src_match = where(src_data EQ src, src_count)

        match = where(dat_algorithm.y EQ alg and src_data EQ src, match_count)

        print, ch, alg, src, match_count

      endforeach

    endforeach

  endforeach



end