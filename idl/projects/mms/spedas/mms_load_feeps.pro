;+
; PROCEDURE:
;         mms_load_feeps
;         
; PURPOSE:
;         Load data from the Fly's Eye Energetic Particle Sensor (FEEPS) onboard MMS
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         datatype: not implemented yet 
;         local_data_dir: local directory to store the CDF files
;         no_color_setup: don't setup graphics configuration; use this
;             keyword when you're using this load routine from a
;             terminal without an X server running
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-09-24 14:17:09 -0700 (Thu, 24 Sep 2015) $
;$LastChangedRevision: 18919 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_feeps.pro $
;-
pro mms_feeps_spin_avg, probe=probe, data_units = data_units, datatype = datatype
    if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
    if undefined(datatype) then datatype = 'electron'
    if undefined(data_units) then data_units = 'intensity'
    ;electron_idxs = [0, 1, 2, 3, 4, 8, 9, 10, 11] ; all 9, but some are missing at the moment
    electron_idxs = [2, 3, 4, 10, 11]
    ion_idxs = [5, 6, 7]
    num_sensors = datatype eq 'electron' ? n_elements(electron_idxs) : n_elements(ion_idxs)
    sensors = datatype eq 'electron' ? electron_idxs : ion_idxs

    prefix = 'mms'+probe+'_epd_feeps_'
    ; get the spin #s associated with each measurement
    get_data, prefix + 'spin', data=spin_nums

    ; find where the spins start
    spin_starts = uniq(spin_nums.Y)

    prefix = 'mms'+probe+'_epd_feeps_top_intensity_sensorID_'
    
    ; loop over the sensors
    for scope_idx = 0, num_sensors-1 do begin
        suffix = strcompress(string(sensors[scope_idx]+1), /rem)
        get_data, prefix+suffix, data=flux_data, dlimits=flux_dl

        spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.Y[0, *]))

        current_start = 0
        ; loop through the spins for this telescope
        for spin_idx = 0, n_elements(spin_starts)-1 do begin
            ;spin_sum_flux[spin_idx, *] = total(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)
            spin_sum_flux[spin_idx, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)

            current_start = spin_starts[spin_idx]+1
        endfor
        suffix = suffix + '_spin'
        store_data, prefix+suffix, data={x: spin_nums.X[spin_starts], y: spin_sum_flux, v: flux_data.V}, dlimits=flux_dl
        options, prefix+suffix, spec=1
        ylim, prefix+suffix, 50., 500., 1
        zlim, prefix+suffix, 0, 0, 1
    endfor
end

pro mms_load_feeps, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update


    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'electron' 
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'feeps', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update
    
    for probe_idx = 0, n_elements(probes)-1 do mms_feeps_spin_avg, probe=probes[probe_idx], datatype=datatype

end