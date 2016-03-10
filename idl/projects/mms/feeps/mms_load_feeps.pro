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
;         datatype:     feeps data types include ['electron', 'electron-bottom', 'electron-top', 
;                       'ion', 'ion-bottom', 'ion-top']. 
;                       If no value is given the default is 'electron'.
;         data_rate:    instrument data rates for feeps include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   specify units for omni-directional calculation and spin averaging
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
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
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval 
;                       (e.g., /latest_version)
;         min_version:  specify a minimum CDF version # to load 
;         spdf: grab the data from the SPDF instead of the LASP SDC (only works for public access)
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
;     The spectra variables created with "_clean" in their names have 
;       the 500 keV integral channel removed.
;     The spectra variables with '_sun_removed' in their names 
;       have the sun contamination removed 
;       
;       (*_clean_sun_removed variables have both the 500 keV integral 
;         channel removed and the sun contamination removed)
; 
; 
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-09 13:55:59 -0800 (Wed, 09 Mar 2016) $
;$LastChangedRevision: 20377 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_load_feeps.pro $
;-
pro mms_load_feeps, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, data_units= data_units, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  varformat = varformat, cdf_filenames = cdf_filenames, $
                  cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version, spdf = spdf

    if undefined(probes) then probes_in = ['1'] else probes_in = probes
    if undefined(datatype) then datatype_in = 'electron' else datatype_in = datatype
    if undefined(level) then level_in = 'l1b' else level_in = level
    if undefined(data_units) then data_units = 'flux'
    if undefined(data_rate) then data_rate_in = 'srvy' else data_rate_in = data_rate
    if undefined(min_version) && undefined(latest_version) && undefined(cdf_version) then min_version = '4.3.0'
      
    mms_load_data, trange = trange, probes = probes_in, level = level_in, instrument = 'feeps', $
        data_rate = data_rate_in, local_data_dir = local_data_dir, source = source, $
        datatype = datatype_in, /get_support_data, $ ; support data is needed for spin averaging, etc.
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf
    
    if undefined(tplotnames) || tplotnames[0] eq '' then return
    
    for probe_idx = 0, n_elements(probes_in)-1 do begin
      this_probe = string(probes_in[probe_idx])
      ; split the extra integral channel from all of the spectrograms
      mms_feeps_split_integral_ch, ['count_rate', 'intensity'], datatype_in, this_probe, $
        suffix = suffix, data_rate = data_rate_in, level = level_in
        
      ; remove the sunlight contamination
      mms_feeps_remove_sun, probe = this_probe, datatype = datatype_in, level = level_in, $
          data_rate = data_rate_in, suffix = suffix, data_units = ['count_rate', 'intensity']

      ; calculate the omni-directional spectra
      mms_feeps_omni, this_probe, datatype = datatype_in, tplotnames = tplotnames, data_units = data_units, $
          data_rate = data_rate_in, suffix=suffix

      ; calculate the spin averages
      mms_feeps_spin_avg, probe=this_probe, datatype=datatype_in, suffix = suffix, data_units = data_units
    endfor
    
    ; interpolate to account for gaps in data near perigee for srvy data
    if data_rate_in eq 'srvy' then begin
      tdeflag, tnames('*_intensity_*'), 'repeat', /overwrite
      tdeflag, tnames('*_count_rate_*'), 'repeat', /overwrite
      tdeflag, tnames('*_counts_*'), 'repeat', /overwrite
    endif
end