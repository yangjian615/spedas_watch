pro spp_fld_rfs_rawspectra_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_rawspectra_'

  file = '/Users/pulupa/Desktop/spp_fld_make_cdf/20170713_rfs_rawspectra_test/' + $
    'spp_fld_l1_rfs_rawspectra_20170706_210000_20170707_000000_v00.cdf'

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_wf_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, file, prefix = prefix

  n_wf = 32768l
  f_wf = 38.4e6
  n_fft = 4096l

  freq_hfr = spp_fld_rfs_freqs()
  freq_lfr = spp_fld_rfs_freqs(/lfr)

  get_data, 'spp_fld_rfs_rawspectra_ch0', data = dat_ch0

  get_data, 'spp_fld_rfs_rawspectra_ch1', data = dat_ch1

  get_data, 'spp_fld_rfs_rawspectra_algorithm', data = dat_algorithm

  get_data, 'spp_fld_rfs_rawspectra_ch0_gain', data = dat_ch0_gain
  get_data, 'spp_fld_rfs_rawspectra_ch1_gain', data = dat_ch1_gain


  if size(/type, dat_ch0) NE 8 or $
    size(/type, dat_ch1) NE 8 or $
    size(/type, dat_algorithm) NE 8 then begin

    print, 'No RFS raw spectral data'

    return

  end

  options, 'spp_fld_rfs_rawspectra_ch?_??', 'spec', 0

  hfr_ind = where((dat_algorithm.y MOD 2) EQ 0, hfr_count, $
    complement = lfr_ind, ncomplement = lfr_count)

  dat_v = dblarr(n_fft/2,n_elements(dat_algorithm.y))

  if hfr_count GT 0 then dat_v[*, hfr_ind] = rebin(freq_hfr.full_freq[1:*], n_fft/2, hfr_count, /sample)
  if lfr_count GT 0 then dat_v[*, lfr_ind] = rebin(freq_lfr.full_freq[1:*], n_fft/2, lfr_count, /sample)

  get_data, 'spp_fld_rfs_rawspectra_ch0_re', data = dat_ch0_re
  get_data, 'spp_fld_rfs_rawspectra_ch0_im', data = dat_ch0_im

  ch0_comp = dcomplex(dat_ch0_re.y, dat_ch0_im.y)

  ch0_pow = abs(ch0_comp)^2d

  dat_ch0_pow = {x:dat_ch0_re.x, y:ch0_pow, v:transpose(dat_v)}

  store_data, 'spp_fld_rfs_rawspectra_ch0_pow', $
    data = dat_ch0_pow, $
    dlim = {spec:1, ystyle:1, ylog:1, zlog:1, yrange:[1.e3,1.e8], $
    no_interp:1}

  get_data, 'spp_fld_rfs_rawspectra_ch1_re', data = dat_ch1_re
  get_data, 'spp_fld_rfs_rawspectra_ch1_im', data = dat_ch1_im

  ch1_comp = dcomplex(dat_ch1_re.y, dat_ch1_im.y)

  ch1_pow = abs(ch1_comp)^2d

  dat_ch1_pow = {x:dat_ch1_re.x, y:ch1_pow, v:transpose(dat_v)}

  store_data, 'spp_fld_rfs_rawspectra_ch1_pow', $
    data = dat_ch1_pow, $
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
      gain_data = dat_ch0_gain.y

    endif else begin

      src_data = dat_ch1.y
      re_data = dat_ch1_re.y
      im_data = dat_ch1_im.y
      pow_data = ch1_pow
      gain_data = dat_ch1_gain.y

    endelse

    foreach alg, algs do begin

      foreach src, srcs do begin

        alg_match = where((dat_algorithm.y MOD 2) EQ alg, alg_count)
        src_match = where(src_data EQ src, src_count)

        match = where(dat_algorithm.y EQ alg and src_data EQ src, match_count)

        if match_count GT 0 then begin

          if alg EQ 0 then begin
            hfr_lfr_str = 'hfr'
            yrange = [8.e3,2.e7]
          endif else begin
            hfr_lfr_str = 'lfr'
            yrange = [8.e2,2.e6]
          endelse

          if ch EQ 0 then begin

            dat_pow = dat_ch0_pow
            case src of
              0: source_txt = 'V1-V2'
              1: source_txt = 'V1-V3'
              2: source_txt = 'V2-V4'
              3: source_txt = 'SCM'
              4: source_txt = 'V1'
              5: source_txt = 'V3'
              6: source_txt = 'GND'
              7: source_txt = 'GND'
            endcase

          endif else begin

            dat_pow = dat_ch1_pow

            case src of
              0: source_txt = 'V3-V4'
              1: source_txt = 'V3-V2'
              2: source_txt = 'V1-V4'
              3: source_txt = 'SCM'
              4: source_txt = 'V2'
              5: source_txt = 'V4'
              6: source_txt = 'GND'
              7: source_txt = 'GND'
            endcase

          endelse

          ; Using definition of power spectral density
          ;  S = 2 * Nfft / fs |x|^2 / Wss where
          ; where |x|^2 is an auto spec value of the PFB/DFT
          ;
          ; 2             : from definition of S_PFB
          ; 4096          : number of FFT points
          ; 38.4e6        : fs in Hz (divide fs by 8 for LFR)
          ; 250           : RFS high gain
          ;               :  (multiply by 50^2 later on if in low gain)
          ;               :  (multiply by 0.042 for SCM)
          ; 2048          : 2048 counts in the ADC = 1 volt
          ; 0.782         : WSS for our implementation of the PFB (see pfb_norm.pdf)
          ; 65536         : factor from integer PFB, equal to (2048./8.)^2

          if source_txt NE 'SCM' then gain0 = 250d else gain0 = 0.042d

          gain = dblarr(match_count) + gain0

          if source_txt NE 'SCM' then begin
            lo_gain = where(gain_data[match] EQ 0, n_lo_gain)
            if n_lo_gain GT 0 then gain[lo_gain] = 5d
          endif

          V2_factor = 2d * 4096d / 38.4d6 / ((gain*2048d)^2d * 0.782d * 65536d)

          if hfr_lfr_str EQ 'lfr' then V2_factor *= 8
          dat_pow.y[match,*] *= transpose(rebin(V2_factor,n_elements(V2_factor),2048))

          tplot_prefix = 'spp_fld_rfs_rawspectra_' + hfr_lfr_str + $
            '_ch' + string(ch, format='(I1)') + $
            '_src' + string(src, format = '(I1)')

          ytitle = 'RFS ' + strupcase(hfr_lfr_str) + ' AUTO!C' + $
            'CH' + string(ch, format='(I1)') + ' ' + $
            source_txt

          print, ch, alg, src, match_count, ' ', tplot_prefix, $
            format = '(I2,I2,I2,I6,A,A)'

          store_data, tplot_prefix + '_pow', $
            data = {x:dat_pow.x[match], $
            y:dat_pow.y[match,*], $
            v:dat_pow.v[match,*]}

          options, tplot_prefix + '_*', 'spec', 1
          options, tplot_prefix + '_*', 'ylog', 1
          options, tplot_prefix + '_*', 'zlog', 1
          options, tplot_prefix + '_*', 'no_interp', 1
          options, tplot_prefix + '_*', 'yrange', yrange
          options, tplot_prefix + '_*', 'ystyle', 1
          options, tplot_prefix + '_pow', 'ytitle', ytitle
          options, tplot_prefix + '_*', 'ztitle', 'V2/Hz'

        endif else begin
          print, ch, alg, src, match_count, $
            format = '(I2,I2,I2,I6)'
        end

      endforeach

    endforeach

  endforeach

  tplot, 'spp_fld_rfs_rawspectra_?fr_ch?_src?_pow'

end