pro spp_fld_sc_fsw_rec_alloc_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_fsw_rec_alloc_'
  
  cdf2tplot, file, prefix = prefix
  
  sc_fsw_rec_alloc_names = tnames(prefix + '*')
  
  if sc_fsw_rec_alloc_names[0] NE '' then begin
    
    for i = 0, n_elements(sc_fsw_rec_alloc_names) - 1 do begin
      
      name = sc_fsw_rec_alloc_names[i]

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      options, name, 'psym', 4
      options, name, 'symsize', 0.5
      
    endfor
    
  endif

end