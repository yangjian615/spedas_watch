pro spp_fld_dfb_spec_load_l1, file, prefix = prefix

  if n_elements(file) LT 1 then begin
    print, 'Must provide a CDF file to load"
    return
  endif

  cdf2tplot, file, prefix = prefix, varnames = varnames

  status_items = ['enable','bin','src_sel','scm_rotate','gain','navg','concat']

  spec_number = fix(strmid(prefix,1,1,/rev))

  case spec_number of
    1: colors = 6 ; red
    2: colors = 4 ; green
    3: colors = 2 ; blue
    4: colors = 1 ; magenta
  endcase
  
  options, prefix + status_items, 'colors', colors
  options, prefix + status_items, 'psym', spec_number + 3
  options, prefix + status_items, 'panel_size', 0.75
  options, prefix + status_items, 'ysubtitle', ''

  options, prefix + 'spec', 'spec', 1

  options, prefix + 'src_sel', 'yrange', [-0.5,15.5]
  options, prefix + 'src_sel', 'ystyle', 1
  options, prefix + 'src_sel', 'labels', [string(spec_number,format='(I1)')]

  options, prefix + 'enable', 'yrange', [-0.25,1.25]
  options, prefix + 'enable', 'ystyle', 1
  options, prefix + 'enable', 'yticks', 1
  options, prefix + 'enable', 'ytickv', [0,1]
  options, prefix + 'enable', 'yminor', 1
  options, prefix + 'enable', 'ysubtitle', ''
  options, prefix + 'enable', 'panel_size', 0.35

  options, prefix + 'bin', 'yrange', [-0.25,1.25]
  options, prefix + 'bin', 'ystyle', 1
  options, prefix + 'bin', 'yticks', 1
  options, prefix + 'bin', 'ytickv', [0,1]
  options, prefix + 'bin', 'ytickname', ['56','96']
  options, prefix + 'bin', 'yminor', 1
  options, prefix + 'bin', 'ysubtitle', ''
  options, prefix + 'bin', 'panel_size', 0.35

  options, prefix + 'scm_rotate', 'yrange', [-0.25,1.25]
  options, prefix + 'scm_rotate', 'ystyle', 1
  options, prefix + 'scm_rotate', 'yticks', 1
  options, prefix + 'scm_rotate', 'ytickv', [0,1]
  options, prefix + 'scm_rotate', 'yminor', 1
  options, prefix + 'scm_rotate', 'ysubtitle', ''
  options, prefix + 'scm_rotate', 'panel_size', 0.35

  options, prefix + 'gain', 'yrange', [-0.25,1.25]
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ytickv', [0,1]
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'ysubtitle', ''
  options, prefix + 'gain', 'panel_size', 0.35

  options, prefix + 'navg', 'yrange', [-0.5,15.5]
  options, prefix + 'navg', 'ystyle', 1

  options, prefix + 'concat', 'yrange', [-0.5,15.5]
  options, prefix + 'concat', 'ystyle', 1

  options, prefix + 'saturation_flags', 'tplot_routine', 'bitplot'
  options, prefix + 'saturation_flags', 'numbits', 16
  options, prefix + 'saturation_flags', 'yminor', 1
  options, prefix + 'saturation_flags', 'colors', colors
  options, prefix + 'saturation_flags', 'psyms', spec_number + 3

  get_data, prefix + 'spec', data = spec_data

  get_data, prefix + 'navg', data = navg_data

  get_data, prefix + 'bin', data = bin_data

  get_data, prefix + 'spec_nelem', data = nelem_data

  get_data, prefix + 'concat', data = concat_data

  get_data, prefix + 'saturation_flags', data = sat_data

  ; TODO: Make this work with all configurations of spectra

  if size(spec_data, /type) EQ 8 then begin

    if n_elements(spec_data.x) GT 1 then begin

      ; Check if all spectra items in the file have the same number of data
      ; elements and concatenated spectra.

      if n_elements(uniq(nelem_data.y)) EQ 1 and $
        n_elements(uniq(navg_data.y)) EQ 1 and $
        n_elements(uniq(concat_data.y)) EQ 1 then begin

        if strpos(prefix, 'ac_spec') NE -1 then is_ac = 1 else is_ac = 0

        n_spec = concat_data.y[0] + 1
        n_bins = nelem_data.y[0] / n_spec
        n_avg = 2l^(navg_data.y[0])

        if is_ac then begin
          freq_bins = spp_get_fft_bins_04_ac(n_bins)
        endif else begin
          freq_bins = spp_get_fft_bins_04_dc(n_bins)
        endelse

        n_total = n_elements(spec_data.y)

        ; The spectral data as returned by TMlib are not in order, instead 
        ; the order goes like (fs represent increasing frequencies)
        ; [f1, f0, f3, f2, f5, f4, ...]
        ; This reorders the spectra:
        
        spec_data_y = reform( $
          transpose($
          [[[spec_data.y[*,1:*:2]]], $
          [[spec_data.y[*,0:*:2]]]],[0,2,1]), $
          size(/dim,spec_data.y))

        ; This takes the concatenated spectra array and makes a new array with
        ; one spectra per column
        
        new_data_y = transpose(reform(reform(transpose(spec_data_y), n_total), $
          n_bins, n_total/n_bins))

        ; TODO: Make this more precise using TMlib time

        new_data_x = []
        new_data_sat_y = []

        if is_ac then begin

          if n_avg LE 16 then delta_x = 2d^17 / 150d3 * n_avg / n_spec;; base dt is 1 PPC
          if n_avg GE 32 then delta_x = 2d^17 / 150d3 * double(floor(n_avg / 16d)) / n_spec ;; base dt is N PPC

        endif else begin

          delta_x = 2d^17 / 150d3 * 512. / n_spec

        endelse

        for i = 0, n_elements(spec_data.x)-1 do begin
          new_data_x = [new_data_x,spec_data.x[i] + $
            delta_x * dindgen(n_spec)]

          new_data_sat_y = [new_data_sat_y, $
            (sat_data.y[i] / 2l^lindgen(16) MOD 2)[0:n_spec-1]]
        endfor

        data_v = transpose(rebin(freq_bins.freq_avg,$
          n_elements(freq_bins.freq_avg),$
          n_elements(new_data_x)))

        store_data, prefix + 'spec_converted', $
          data = {x:new_data_x, $
          y:alog10(spp_fld_dfb_psuedo_log_decompress(new_data_y, $
          type = 'spectra')), $
          v:data_v}

        options, prefix + 'spec_converted', 'panel_size', 2
        options, prefix + 'spec_converted', 'spec', 1
        options, prefix + 'spec_converted', 'no_interp', 1
        options, prefix + 'spec_converted', 'zlog', 0
        options, prefix + 'spec_converted', 'ylog', 1
        options, prefix + 'spec_converted', 'ztitle', 'Log Auto [arb.]'
        options, prefix + 'spec_converted', 'ystyle', 1
        options, prefix + 'spec_converted', 'yrange', minmax(freq_bins.freq_avg)

        store_data, prefix + 'sat', $
          data = {x:new_data_x, y:new_data_sat_y}
        
        options, prefix + 'sat', 'psym', spec_number + 3
        options, prefix + 'sat', 'yrange', [-0.25,1.25]
        options, prefix + 'sat', 'ystyle', 1
        options, prefix + 'sat', 'yticks', 1
        options, prefix + 'sat', 'ytickv', [0,1]
        options, prefix + 'sat', 'yminor', 1
        options, prefix + 'sat', 'ysubtitle', ''
        options, prefix + 'sat', 'panel_size', 0.35
        options, prefix + 'sat', 'colors', colors

      endif else begin

        print, 'Different spectra configuration in same CDF file'

      endelse

    endif

  endif

  ; Clean up some formatting

  ac_dc_string = strupcase(strmid(prefix,12,2))
  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  dfb_spec_names = tnames(prefix + '*')

  if dfb_spec_names[0] NE '' then begin

    for i = 0, n_elements(dfb_spec_names) - 1 do begin

      dfb_spec_name_i = strmid(dfb_spec_names[i], strlen(prefix))

      if dfb_spec_name_i EQ 'spec_converted' then begin

        options, prefix + dfb_spec_name_i, 'ytitle', $
          'SPP DFB!C' + ac_dc_string + ' SPEC' + $
          string(spec_ind)

        options, prefix + dfb_spec_name_i, 'ysubtitle', 'Freq [Hz]'

      endif else begin

        if strmid(prefix + dfb_spec_name_i,6,/rev) EQ '_string' then begin

          options, prefix + dfb_spec_name_i, 'ysubtitle', ''

          dfb_spec_name_ytitle = $
            strmid(dfb_spec_name_i, 0, strlen(dfb_spec_name_i) - 7)

        endif else begin

          dfb_spec_name_ytitle = dfb_spec_name_i

        endelse

        options, prefix + dfb_spec_name_i, 'ytitle', $
          'DFB!C' + ac_dc_string + ' SP' + $
          string(spec_ind) + '!C' + strupcase(dfb_spec_name_ytitle)

      endelse

    endfor

  endif

  options, prefix + '*string', 'tplot_routine', 'strplot'
  options, prefix + '*string', 'yrange', [-0.1,1.0]
  options, prefix + '*string', 'ystyle', 1
  options, prefix + '*string', 'yticks', 1
  options, prefix + '*string', 'ytickformat', '(A1)'
  options, prefix + '*string', 'noclip', 0
  
  all_prefix = strmid(prefix, 0, strlen(prefix) - 2)

  src_names = tnames(all_prefix + '?_src_sel')

  store_data, all_prefix + 'all_src_sel', data = src_names

  options, all_prefix + 'all_src_sel', 'yrange', [-0.5,15.5]
  options, all_prefix + 'all_src_sel', 'ystyle', 1
  options, all_prefix + 'all_src_sel', 'panel_size', 2.0

end