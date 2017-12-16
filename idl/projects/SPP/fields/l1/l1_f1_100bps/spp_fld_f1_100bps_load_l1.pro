pro spp_fld_f1_100bps_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_f1_100bps_'

  cdf2tplot, file, prefix = prefix

  options, prefix + 'VOLT1', 'colors', 6 ; red
  options, prefix + 'VOLT2', 'colors', 4 ; green
  options, prefix + 'VOLT3', 'colors', 2 ; blue
  options, prefix + 'VOLT4', 'colors', 1 ; magenta

  options, prefix + 'VOLT1', 'labels', '1'
  options, prefix + 'VOLT2', 'labels', '  2'
  options, prefix + 'VOLT3', 'labels', '    3'
  options, prefix + 'VOLT4', 'labels', '      4'

  store_data, prefix + 'V_PEAK', $
    data = prefix + 'VOLT?'

  options, prefix + 'MNMX_V1', 'colors', 6 ; red
  options, prefix + 'MNMX_V2', 'colors', 4 ; green
  options, prefix + 'MNMX_V3', 'colors', 2 ; blue
  options, prefix + 'MNMX_V4', 'colors', 1 ; magenta

  options, prefix + 'MNMX_V1', 'labels', '1'
  options, prefix + 'MNMX_V2', 'labels', '  2'
  options, prefix + 'MNMX_V3', 'labels', '    3'
  options, prefix + 'MNMX_V4', 'labels', '      4'

  store_data, prefix + 'V_MNMX', $
    data = prefix + 'MNMX_V?'


  options, prefix + '*BX', 'colors', 6 ; red
  options, prefix + '*BY', 'colors', 4 ; green
  options, prefix + '*BZ', 'colors', 2 ; blue

  options, prefix + '*BX', 'labels', 'X'
  options, prefix + '*BY', 'labels', '  Y'
  options, prefix + '*BZ', 'labels', '    Z'
  
  store_data, prefix + 'B_PEAK', $
    data = prefix + 'B?'

  store_data, prefix + 'B_MNMX', $
    data = prefix + 'MNMX_B?'

  options, prefix + 'CBS_*0', 'colors', 6
  options, prefix + 'CBS_*1', 'colors', 4
  options, prefix + 'CBS_*2', 'colors', 2
  options, prefix + 'CBS_*3', 'colors', 1 ; magenta
  
  options, prefix + 'CBS_*0', 'labels', '0'
  options, prefix + 'CBS_*1', 'labels', '  1'
  options, prefix + 'CBS_*2', 'labels', '    2'
  options, prefix + 'CBS_*3', 'labels', '      3'

  store_data, prefix + 'CBS_PEAK', $
    data = prefix + 'CBS_PEAK?'
    
  options, prefix + 'CBS_PEAK', 'yrange', [0,256]
  options, prefix + 'CBS_PEAK', 'ystyle', 1
  options, prefix + 'CBS_PEAK', 'yticks', 8
  options, prefix + 'CBS_PEAK', 'yminor', 4

  store_data, prefix + 'CBS_AVG', $
    data = prefix + 'CBS_AVG?'

  options, prefix + 'CBS_AVG', 'yrange', [0,256]
  options, prefix + 'CBS_AVG', 'ystyle', 1
  options, prefix + 'CBS_AVG', 'yticks', 8
  options, prefix + 'CBS_AVG', 'yminor', 4

  options, prefix + ['DFB_V12AC_PEAK', 'DFB_SCM_PEAK'], 'spec', 1
  options, prefix + ['DFB_V12AC_PEAK', 'DFB_SCM_PEAK'], 'no_interp', 1

  options, prefix + ['DFB_V12AC_AVG', 'DFB_SCM_AVG'], 'spec', 1
  options, prefix + ['DFB_V12AC_AVG', 'DFB_SCM_AVG'], 'no_interp', 1


  f1_100bps_names = tnames(prefix + '*')

  if f1_100bps_names[0] NE '' then begin

    for i = 0, n_elements(f1_100bps_names)-1 do begin

      name = f1_100bps_names[i]

      options, name, 'ynozero', 1
      ;options, name, 'horizontal_ytitle', 1
      ;options, name, 'colors', [6]
      options, name, 'ytitle', 'F1 100BPS!C' + name.Remove(0, prefix.Strlen()-1)

      options, name, 'ysubtitle', ''

      options, name, 'psym', -4
      options, name, 'symsize', 0.5

    endfor

  endif

end