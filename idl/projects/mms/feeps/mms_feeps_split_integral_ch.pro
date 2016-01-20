;+
;Procedure:
;  mms_feeps_split_integral_ch
;
;Purpose:
;    this function splits the last integral channel from the FEEPS spectra
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-19 15:25:55 -0800 (Tue, 19 Jan 2016) $
;$LastChangedRevision: 19762 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_split_integral_ch.pro $
;-

pro mms_feeps_split_integral_ch, type, species, probe, suffix = suffix
  if undefined(species) then species = 'electron' ; default to electrons
  if undefined(probe) then probe = '1' ; default to probe 1
  if undefined(suffix) then suffix = ''
  bottom_en = species eq 'electron' ? 71 : 96
  if species eq 'electron' then sensors = [3, 4, 5, 11, 12] else sensors = [6, 7, 8]

  for sensor_idx = 0, n_elements(sensors)-1 do begin
    top_name = strcompress('mms'+probe+'_epd_feeps_top_'+type+'_sensorID_'+string(sensors[sensor_idx])+suffix, /rem)
    bottom_name = strcompress('mms'+probe+'_epd_feeps_bottom_'+type+'_sensorID_'+string(sensors[sensor_idx])+suffix, /rem)
    get_data, top_name, data=top_data, dlimits=top_dl
    get_data, bottom_name, data=bottom_data, dlimits=bottom_dl

    store_data, top_name+'_clean', data={x: top_data.X, y: top_data.Y[*, 0:n_elements(top_data.V)-2], v: top_data.V[0:n_elements(top_data.V)-2]}, dlimits=top_dl
    store_data, bottom_name+'_clean', data={x: bottom_data.X, y: bottom_data.Y[*, 0:n_elements(bottom_data.V)-2], v: bottom_data.V[0:n_elements(bottom_data.V)-2]}, dlimits=bottom_dl

    ; limit the lower energy plotted
    options, top_name+'_clean', ystyle=1
    options, bottom_name+'_clean', ystyle=1
    ylim, top_name+'_clean', bottom_en, 510., 1
    ylim, bottom_name+'_clean', bottom_en, 510., 1
    zlim, top_name+'_clean', 0, 0, 1
    zlim, bottom_name+'_clean', 0, 0, 1

    ; store the integral channel
    store_data, top_name+'_500keV_int', data={x: top_data.X, y: top_data.Y[*, n_elements(bottom_data.V)-1]}
    store_data, bottom_name+'_500keV_int', data={x: bottom_data.X, y: bottom_data.Y[*, n_elements(bottom_data.V)-1]}
  endfor
end
