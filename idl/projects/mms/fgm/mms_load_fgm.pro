;+
; PROCEDURE:
;         mms_load_fgm
;         
; PURPOSE:
;         Load MMS magnetometer data
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. fgm levels include 'l1a', 'l1b', 'l2' and
;                        'ql'. the default if no level is specified is 'l2'
;         datatype:     currently all data types for fgm are retrieved (datatype not specified)
;         data_rate:    instrument data rates for fgm include 'brst' 'fast' 'slow' 'srvy'. The
;                       default is 'srvy'.
;         instrument:   fgm instruments are 'fgm', 'dfg' and 'afg'. default value is 'fgm'; you probably
;                       shouldn't be using 'dfg' or 'afg' without talking to the instrument team
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using 
;                       this load routine from a terminal without an X server runningdo not set colors
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
;             
; OUTPUT:
; 
; EXAMPLE:
;     For examples see crib sheets mms_load_fgm_crib.pro, and mms_load_fgm_brst_crib.pro
;     
;     load MMS FGM burst data for MMS 1
;     MMS>  mms_load_fgm, probes=['1'], data_rate='brst'
;     
;     load MMS FGM data for MMS 1 and MMS 2
;     MMS>  mms_load_fgm, probes=[1, 2], trange=['2015-06-22', '2015-06-23']
;
; NOTES:
;     1) See the notes in mms_load_data for rules on the use of MMS data
;     
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-26 13:35:52 -0800 (Fri, 26 Feb 2016) $
;$LastChangedRevision: 20220 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_load_fgm.pro $
;-


pro mms_load_fgm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, instrument = instrument, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  no_attitude_data = no_attitude_data, varformat = varformat, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    probes = strcompress(string(probes), /rem) ; force the array to be an array of strings
    if undefined(datatype) then datatype = '' ; grab all data in the CDF
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    ; default to QL if the trange is within the last 2 weeks, L2pre if older
    if undefined(level) then begin 
        fourteen_days_ago = systime(/seconds)-60*60*24.*14.
        if trange[1] ge fourteen_days_ago then level = 'ql' else level = 'l2'
    endif else level = strlowcase(level)
    if undefined(instrument) then instrument = 'fgm'
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix = ''

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version

    
    ; load the atttude data to do the coordinate transformation 
    if undefined(no_attitude_data) && level ne 'l2pre' then begin
      mms_load_state, trange = trange, probes = probes, level = 'def', /attitude_only, suffix = suffix
    endif
    ; Note: not all MEC files have right ascension and declination data, commented out until LANL reprocesses
  ;  if undefined(no_attitude_data) && level ne 'l2pre' then mms_load_mec, trange = trange, probes = probes, suffix = suffix

    ; DMPA coordinates to GSE, for each probe
    for probe_idx = 0, n_elements(probes)-1 do begin
        this_probe = 'mms'+strcompress(string(probes[probe_idx]), /rem)
        ; make sure the attitude data has been loaded before doing the cotrans operation
        if tnames(this_probe+'_defatt_spinras'+suffix) ne '' && tnames(this_probe+'_defatt_spindec'+suffix) ne '' $
            && tnames(this_probe+'_'+instrument+'_'+data_rate+'_dmpa'+suffix) ne '' $
            && undefined(no_attitude_data) && level ne 'l2pre' then begin 

            dmpa2gse, this_probe+'_'+instrument+'_'+data_rate+'_dmpa'+suffix, this_probe+'_defatt_spinras'+suffix, $
                this_probe+'_defatt_spindec'+suffix, this_probe+'_'+instrument+'_'+data_rate+'_gse'+suffix, /ignore_dlimits
            append_array, tplotnames, this_probe+'_'+instrument+'_'+data_rate+'_gse'+suffix
            
        endif
        ; split the FGM data into 2 tplot variables, one containing the vector and one containing the magnitude
        mms_split_fgm_data, this_probe, instrument=instrument, tplotnames = tplotnames, suffix = suffix, level = level, data_rate = data_rate
    endfor

    
    ; set some of the metadata for the DFG/AFG instruments
    mms_fgm_fix_metadata, tplotnames, prefix = 'mms' + probes, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level

end