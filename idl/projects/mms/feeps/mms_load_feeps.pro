;+
; PROCEDURE:
;         mms_load_feeps
;         
; PURPOSE:
;         Load data from the Fly's Eye Energetic Particle Sensor (FEEPS) onboard MMS
; 
; KEYWORDS: 
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is '1'
;         level:        indicates level of data processing. levels include 'l1a', 'l1b'. 
;                       The default if no level is specified is 'l1b'
;         datatype:     feeps data types include:
;                 L1a: 'electron-bottom', 'electron-top', 'ion-bottom', 'ion-top']
;                 L1b: ['electron', 'ion']
;                 sitl: 'electron'
;                       If no value is given the default is 'electron'.
;         data_rate:    instrument data rates for feeps include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using 
;                       this load routine from a terminal without an X server runningdo not set 
;                       colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;
; OUTPUT:
;  
; EXAMPLE:
;     See crib sheet mms_load_feeps_crib.pro for usage examples
;
;     load electron data (srvy mode)
;     MMS1> mms_load_feeps, probes='1', trange=['2015-08-15', '2015-08-16'], datatype='electron'
;     MMS1> mms_feeps_pad,  probe='1', datatype='electron'
;     
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-12 13:06:30 -0800 (Tue, 12 Jan 2016) $
;$LastChangedRevision: 19716 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_load_feeps.pro $
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

pro mms_load_feeps, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  varformat = varformat, cdf_filenames = cdf_filenames


    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'electron' 
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'feeps', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames
    

    if undefined(tplotnames) || tplotnames[0] eq '' then return

;    for probe_idx = 0, n_elements(probes)-1 do $
;        mms_feeps_spin_avg, probe=probes[probe_idx], datatype=datatype, $
;            suffix = suffix
    
    ; interpolate to account for gaps in data near perigee for srvy data
    if data_rate eq 'srvy' then begin
        tdeflag, tnames('*_intensity_*'), 'linear', /overwrite
    endif
end