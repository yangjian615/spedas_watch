pro spp_fld_dfb_dc_spec_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then return

  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_dc_spec_load_l1', dlevel = 2

    return

  endif

  spp_fld_dfb_spec_load_l1, file, prefix = prefix
  
  dc_spec_names = tnames(prefix + '*')

  if dc_spec_names[0] NE '' then begin

    for i = 0, n_elements(dc_spec_names) - 1 do begin

      dc_spec_name_i = strmid(dc_spec_names[i], strlen(prefix))

      options, prefix + dc_spec_name_i, 'ytitle', 'SPP DFB!CDC SPEC' + $
        string(spec_ind) + '!C' + strupcase(dc_spec_name_i)

    endfor

  endif


end