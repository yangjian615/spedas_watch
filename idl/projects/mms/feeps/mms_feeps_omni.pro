;+
; PROCEDURE:
;         mms_feeps_omni
;
; PURPOSE:
;       Calculates the omni-directional flux for all 24 sensors 
;       
;       (this version re-bins the data due to the different energy channels for each s/c, sensor head and sensor ID)
;       
; INPUT:
;       probe:      spacecraft # (1, 2, 3, or 4)
;
; KEYWORDS:
;
;       datatype:   feeps data types include ['electron', 'electron-bottom', 'electron-top',
;                   'ion', 'ion-bottom', 'ion-top'].
;                   If no value is given the default is 'electron'.
;       data_rate:  instrument data rates for feeps include 'brst' 'srvy'. The
;                   default is 'srvy'
;       tplotnames: names of loaded tplot variables
;       suffix:     suffix used in call to mms_load_data; required to find the correct
;                   variables
;       data_units: specify units for omni-directional calculation
;
; NOTES:
;       New version, 1/26/17 - egrimes
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-01-27 11:33:23 -0800 (Fri, 27 Jan 2017) $
; $LastChangedRevision: 22685 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_omni.pro $
;-


pro mms_feeps_omni, probe, datatype = datatype, tplotnames = tplotnames, suffix = suffix, $
  data_units = data_units, data_rate = data_rate, level = level
  if undefined(level) then level = 'l2'
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe))
  ; default to electrons
  if undefined(datatype) then datatype = 'electron'
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(data_units) then data_units = 'cps'
  if (data_units eq 'flux') then data_units = 'intensity'
  if (data_units eq 'cps') then data_units = 'count_rate'
  units_label = data_units eq 'intensity' ? '1/(cm!U2!N-sr-s-keV)' : 'Counts/s'
  
  ; the following works for srvy mode, but doesn't get all of the sensors for burst mode
  if datatype eq 'electron' then sensors = ['3', '4', '5', '11', '12'] else sensors = ['6', '7', '8']
  
  ; special case for burst mode data
  if data_rate eq 'brst' && datatype eq 'electron' then sensors = ['1','2','3','4','5','9','10','11','12']
  if data_rate eq 'brst' && datatype eq 'ion' then sensors = ['6','7','8']
  
  if level eq 'sitl' && datatype eq 'electron' then sensors = ['5','11','12']

  if datatype eq 'electron' then begin
    energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
      200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]
  endif else energies = [57.900000d, 76.800000d, 95.400000d, 114.10000d, 133.00000d, 153.70000d, 177.60000d, $
       205.10000d, 236.70000d, 273.20000d, 315.40000d, 363.80000d, 419.70000d, 484.20000d,  558.60000d]

  en_bins = bin_edges(energies)
  n_enbins = n_elements(en_bins)-1
  en_label = energies
  
  probe = strcompress(string(probe), /rem)

  prefix = 'mms'+probe+'_epd_feeps_'

  var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_top_'+data_units+'_sensorid_'+string(sensors[0])+'_clean_sun_removed'+suffix, /rem)
  get_data, var_name, data = d, dlimits=dl

  en_flux = dblarr(n_elements(d.x), n_enbins)
  en_num_in_bin = fltarr(n_elements(d.X), n_enbins)
  
  if is_struct(d) then begin
    flux_omni = dblarr(n_elements(d.x), n_elements(sensors)*2., n_elements(d.v))
    sensor_count = 0

    for i=0, n_elements(sensors)-1. do begin ; loop through each top sensor
      var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_top_'+data_units+'_sensorid_'+string(sensors[i])+'_clean_sun_removed'+suffix, /rem)
      get_data, var_name, data = d
      for time_idx = 0, n_elements(d.x)-1 do begin
        for en_bin_idx = 0, n_enbins-1 do begin
          wherethisen = where(d.v ge en_bins[en_bin_idx] and d.v le en_bins[en_bin_idx+1], wherecount)
          if wherecount ne 0 then begin
            en_flux[time_idx, en_bin_idx] += total(d.Y[time_idx, wherethisen], 2, /nan, /double)
            en_num_in_bin[time_idx, en_bin_idx] += 1
          endif
        endfor
      endfor
      sensor_count += 1
    endfor
    if level ne 'sitl' then begin ; no bottom sensors for SITL data
      for i=0, n_elements(sensors)-1. do begin ; loop through each bottom sensor
        var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_bottom_'+data_units+'_sensorid_'+string(sensors[i])+'_clean_sun_removed'+suffix, /rem)
        get_data, var_name, data = d
        for time_idx = 0, n_elements(d.x)-1 do begin
          for en_bin_idx = 0, n_enbins-1 do begin
            wherethisen = where(d.v ge en_bins[en_bin_idx] and d.v le en_bins[en_bin_idx+1], wherecount)
            if wherecount ne 0 then begin
              en_flux[time_idx, en_bin_idx] += total(d.Y[time_idx, wherethisen], 2, /nan, /double)
              en_num_in_bin[time_idx, en_bin_idx] += 1
            endif
          endfor
        endfor
        sensor_count += 1
      endfor
    endif
  endif
  
  en_flux_out = dblarr(n_elements(d.x),n_enbins)

  for time_idx = 0, n_elements(en_flux[*, 0])-1 do begin
    for bin_idx = 0, n_elements(en_flux[time_idx, *])-1 do begin
      if en_num_in_bin[time_idx, bin_idx] ne 0.0 then begin
        en_flux_out[time_idx, bin_idx] = en_flux[time_idx, bin_idx]/float(en_num_in_bin[time_idx, bin_idx])
      endif else en_flux_out[time_idx, bin_idx] = !values.d_nan
    endfor
  endfor

  newname = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+data_units+'_omni'+suffix, /rem)

  str_element, /add, dl, 'num_sensors', sensor_count
  
  store_data, newname, data={x: d.x, y: en_flux_out, v: en_label}, dlimits=dl
  options, newname, spec=1, /ylog, /zlog;,  yrange = [47, 523], yticks=3, ystyle=1, zrange=[1., 1.e6];, no_interp=0, y_no_interp=0, x_no_interp=0

end
