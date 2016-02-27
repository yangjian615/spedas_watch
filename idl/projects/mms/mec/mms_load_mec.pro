;+
; PROCEDURE:
;         mms_load_mec
;
; PURPOSE:
;         Load the attitude/ephemeris data from the LANL MEC files
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         datatype:     valid datatypes include ['ephts04d', 'epht89q', 'epht89d']
;                       default is 'ephts04d'
;         data_rate:    instrument data rates include ['srvy', 'brst']. The default is 'srvy'.
; 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system
;                       variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're
;                       using this load routine from a terminal without an X server running
;                       do not set colors
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
;         cdf_records:  specify a number of records to load from the CDF files.
;                       e.g., cdf_records=1 only loads in the first data point in the file
;                       This is especially useful for loading S/C position for a single time
;
; EXAMPLES:
;         to load/plot the S/C position data for probe 3 on 2/20/2016:
;         MMS> mms_load_mec, probe=3, trange=['2016-02-20', '2016-02-21']
;         MMS> tplot, 'mms3_mec_r_gsm'
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-26 07:49:22 -0800 (Fri, 26 Feb 2016) $
;$LastChangedRevision: 20207 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_load_mec.pro $
;-

pro mms_load_mec, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, $
    varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, latest_version = latest_version, $
    min_version = min_version, cdf_records = cdf_records

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'ephts04d'
    if undefined(level) then level = 'l2'
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'mec', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        cdf_records = cdf_records

    ; turn the right ascension and declination of the L vector into separate tplot variables
    ; this is for passing to dmpa2gse
    for probe_idx = 0, n_elements(probes)-1 do begin
        if tnames('mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_ang_mom_vec') ne '' then begin
            split_vec, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_ang_mom_vec', $
                names_out=ras_dec_vars
            copy_data, ras_dec_vars[0], 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defatt_spinras'
            copy_data, ras_dec_vars[1], 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defatt_spindec'
        endif else dprint, dlevel = 1, 'No right ascension/declination of the L-vector found.'
    endfor
end