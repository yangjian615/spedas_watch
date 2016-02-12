;+
; PROCEDURE:
;         mms_feeps_omni
;
; PURPOSE:
;       Calculates the omni-directional flux for all 24 sensors
;
; NOTES:
;       Originally based on Brian Walsh's EIS code from 7/29/2015
;
; CREATED BY: I. Cohen, 2016-01-19
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-11 09:08:45 -0800 (Thu, 11 Feb 2016) $
; $LastChangedRevision: 19954 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_omni.pro $
;-
pro mms_feeps_omni, probe, datatype = datatype, tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
  
  ; default to electrons
  if undefined(datatype) then datatype = 'electron'
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(data_units) then data_units = 'flux'
  if (data_units eq 'flux') then data_units = 'intensity'
  if (data_units eq 'cps') then data_units = 'count_rate'
  units_label = data_units eq 'intensity' ? '#/(cm!U2!N-sr-s-keV)' : 'Counts/s'

  ; the following works for srvy mode, but doesn't get all of the sensors for burst mode
  if datatype eq 'electron' then sensors = ['3', '4', '5', '11', '12'] else sensors = ['6', '7', '8']

  ; special case for burst mode data
  if data_rate eq 'brst' && datatype eq 'electron' then sensors = ['1','2','3','4','5','9','10','11','12']
  if data_rate eq 'brst' && datatype eq 'ion' then sensors = ['6','7','8']
  
  lower_en = datatype eq 'electron' ? 71 : 96

  probe = strcompress(string(probe), /rem)
  ;species_str = datatype+'_'+species
  ;if (data_rate) eq 'brst' then prefix = 'mms'+probe+'_epd_feeps_brst_' else prefix = 'mms'+probe+'_epd_feeps_'
  prefix = 'mms'+probe+'_epd_feeps_'
  get_data, prefix+'top_'+data_units+'_sensorID_'+sensors[0]+'_clean'+suffix, data = d, dlimits=dl

  if is_struct(d) then begin
    flux_omni = dblarr(n_elements(d.x),n_elements(d.v))
    
    for i=0, n_elements(sensors)-1. do begin ; loop through each top sensor
      get_data, prefix+'top_'+data_units+'_sensorID_'+sensors[i]+'_clean'+suffix, data = d
      flux_omni = flux_omni + d.Y
    endfor
    for i=0, n_elements(sensors)-1. do begin ; loop through each bottom sensor
      get_data, prefix+'bottom_'+data_units+'_sensorID_'+sensors[i]+'_clean'+suffix, data = d
      flux_omni = flux_omni + d.Y
    endfor
    newname = prefix+datatype+'_'+data_units+'_omni'+suffix
    store_data, newname[0], data={x:d.x, y:flux_omni/n_elements(sensors)*2., v:d.v}, dlimits=dl

    ylim, newname[0], lower_en, 500., 1
    zlim, newname[0], 0, 0, 1

    options, newname[0], spec = 1, yrange = en_range, $
      ytitle = 'mms'+probe+'!Cfeeps!C'+datatype+'!Comni', $
      ysubtitle='Energy [keV]', ztitle=units_label, ystyle=1, /default, minzlog = .01
    append_array, tplotnames, newname[0]
    ; degap the data
    tdegap, newname[0], /overwrite
  endif
  
end