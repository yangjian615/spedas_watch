pro spp_fld_dfb_ac_spec_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then return

  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_ac_spec_load_l1', dlevel = 2

    return

  endif

  spp_fld_dfb_spec_load_l1, file, prefix = prefix
  
  ac_spec_names = tnames(prefix + '*')

  if ac_spec_names[0] NE '' then begin

    for i = 0, n_elements(ac_spec_names) - 1 do begin

      ac_spec_name_i = strmid(ac_spec_names[i], strlen(prefix))

      if ac_spec_name_i EQ 'spec_converted' then begin

        options, prefix + ac_spec_name_i, 'ytitle', 'SPP DFB!CAC SPEC' + $
          string(spec_ind)
          
        options, prefix + ac_spec_name_i, 'ysubtitle', 'Freq [Hz]'

      endif else begin

        options, prefix + ac_spec_name_i, 'ytitle', 'SPP DFB!CAC SPEC' + $
          string(spec_ind) + '!C' + strupcase(ac_spec_name_i)

      endelse

    endfor

  endif

end