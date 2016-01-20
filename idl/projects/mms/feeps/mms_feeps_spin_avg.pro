;+
;Procedure:
;  mms_feeps_spin_avg
;
;Purpose:
;   spin-averages FEEPS spectra using the '_spin' 
;     variable (variable containing spin # associated 
;     with each measurement)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-19 15:25:55 -0800 (Tue, 19 Jan 2016) $
;$LastChangedRevision: 19762 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_spin_avg.pro $
;-
pro mms_feeps_spin_avg, probe=probe, data_units = data_units, datatype = datatype, $
  suffix = suffix
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = 'electron'
  if undefined(data_units) then data_units = 'intensity'
  if undefined(suffix) then suffix=''
  ;electron_idxs = [0, 1, 2, 3, 4, 8, 9, 10, 11] ; all 9, but some are missing at the moment
  electron_idxs = [2, 3, 4, 10, 11]
  ion_idxs = [5, 6, 7]
  num_sensors = datatype eq 'electron' ? n_elements(electron_idxs) : n_elements(ion_idxs)
  sensors = datatype eq 'electron' ? electron_idxs : ion_idxs

  prefix = 'mms'+probe+'_epd_feeps_'
  ; get the spin #s associated with each measurement
  get_data, prefix + 'spin' + suffix, data=spin_nums

  ; find where the spins start
  if ~is_struct(spin_nums) then begin
    dprint, dlevel = 0, 'Error, couldn''t find the tplot variable containing spin #s to do spin averaging'
    return
  endif
  spin_starts = uniq(spin_nums.Y)

  prefix = 'mms'+probe+'_epd_feeps_top_intensity_sensorID_'
  ; loop over the sensors
  for scope_idx = 0, num_sensors-1 do begin
    sensor = strcompress(string(sensors[scope_idx]+1), /rem)
    get_data, prefix+sensor+suffix, data=flux_data, dlimits=flux_dl
    if ~is_struct(flux_data) || ~is_struct(flux_dl) then begin
      dprint, dlevel = 0, 'Error, no data or metadata for the variable: ' + prefix+sensor+suffix
      continue
    endif

    spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.Y[0, *]))

    current_start = 0
    ; loop through the spins for this telescope
    for spin_idx = 0, n_elements(spin_starts)-1 do begin
      ;spin_sum_flux[spin_idx, *] = total(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)
      spin_sum_flux[spin_idx, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)

      current_start = spin_starts[spin_idx]+1
    endfor
    store_data, prefix+sensor+'_spin'+suffix, data={x: spin_nums.X[spin_starts], y: spin_sum_flux, v: flux_data.V}, dlimits=flux_dl
    options, prefix+sensor+'_spin'+suffix, spec=1
    ylim, prefix+sensor+'_spin'+suffix, 50., 600., 1
    zlim, prefix+sensor+'_spin'+suffix, 0, 0, 1
  endfor
end