pro spp_fld_dcb_events_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_events_'

  cdf2tplot, file, prefix = prefix

  dcb_event_names = tnames(prefix + '*')

  if dcb_event_names[0] NE '' then begin

    for i = 0, n_elements(dcb_event_names)-1 do begin

      name = dcb_event_names[i]

      options, name, 'ynozero', 1
      ;options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', 'DCB Event!C' + name.Remove(0, prefix.Strlen()-1)

      options, name, 'ysubtitle', ''

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endfor

  endif

end