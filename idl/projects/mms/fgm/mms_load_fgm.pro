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
;         level:        indicates level of data processing. the default if no level is specified is 'l2'
;         datatype:     currently all data types for FGM are retrieved (datatype not specified)
;         data_rate:    instrument data rates for FGM include 'brst' 'fast' 'slow' 'srvy'. The
;                       default is 'srvy'.
;         instrument:   FGM instruments are 'fgm', 'dfg' and 'afg'. default value is 'fgm'; you probably
;                       shouldn't be using 'dfg' or 'afg' without talking to the instrument team
;         local_data_dir: local directory to store the CDF files
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: load support data (defined by support_data VAR_TYPE in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using 
;                       this load routine from a terminal without an X server runningdo not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variables.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval 
;                       (e.g., /latest_version)
;         min_version:  specify a minimum CDF version # to load 
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public data)
;         no_split_vars: don't split the FGM variables into vector + magnitude tplot variables; if set
;                        vector transformations won't work on the FGM tplot variables. 
;         keep_flagged: don't remove flagged data (flagged data are set to NaNs by default, this keyword
;                       turns this off)
;         get_fgm_ephemeris: keep the ephemeris variables in the FGM files
;
; 
; EXAMPLE:
;     See mms_load_fgm_crib.pro and mms_load_fgm_brst_crib.pro for usage examples
;     
;     load MMS FGM burst data for MMS 1
;     MMS>  mms_load_fgm, probes=['1'], data_rate='brst'
;     
;     load MMS FGM data for MMS 1 and MMS 2
;     MMS>  mms_load_fgm, probes=[1, 2], trange=['2015-06-22', '2015-06-23']
;
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-19 10:50:42 -0700 (Thu, 19 May 2016) $
;$LastChangedRevision: 21137 $
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
                  latest_version = latest_version, min_version = min_version, $
                  spdf = spdf, no_split_vars=no_split_vars, keep_flagged = keep_flagged, $
                  get_fgm_ephemeris = get_fgm_ephemeris

    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    probes = strcompress(string(probes), /rem) ; force the array to be an array of strings
    if undefined(datatype) then datatype = '' ; grab all data in the CDF
    ; default to QL if the trange is within the last 2 weeks, L2pre if older
    if undefined(level) then begin 
        fourteen_days_ago = systime(/seconds)-60*60*24.*14.
        if tr[1] ge fourteen_days_ago then level = 'ql' else level = 'l2'
    endif else level = strlowcase(level)
    if undefined(instrument) then instrument = 'fgm'
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix = ''
    ; need support data by default to deflag bad data
    if undefined(get_support_data) then get_support_data = 1 

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
        spdf = spdf

    for probe_idx = 0, n_elements(probes)-1 do begin
        this_probe = 'mms'+strcompress(string(probes[probe_idx]), /rem)
        
        for data_rate_idx = 0, n_elements(data_rate)-1 do begin
            this_data_rate = data_rate[data_rate_idx]
            if ~keyword_set(keep_flagged) then begin
                ; B-field data
                get_data, this_probe+'_'+instrument+'_b_gse_'+this_data_rate+'_'+level+suffix, data=b_data_gse, dlimits=gse_dl
                get_data, this_probe+'_'+instrument+'_b_gsm_'+this_data_rate+'_'+level+suffix, data=b_data_gsm, dlimits=gsm_dl
                get_data, this_probe+'_'+instrument+'_b_dmpa_'+this_data_rate+'_'+level+suffix, data=b_data_dmpa, dlimits=dmpa_dl
                get_data, this_probe+'_'+instrument+'_b_bcs_'+this_data_rate+'_'+level+suffix, data=b_data_bcs, dlimits=bcs_dl
                ; flags
                get_data, this_probe+'_'+instrument+'_flag_'+this_data_rate+'_'+level+suffix, data=flags
                if is_struct(flags) then begin
                  bad_data = where(flags.Y ne 0, flag_count) 
                  if flag_count ne 0 then begin
                      if is_struct(b_data_gse) then b_data_gse.Y[bad_data, *] = !values.d_nan
                      if is_struct(b_data_gsm) then b_data_gsm.Y[bad_data, *] = !values.d_nan
                      if is_struct(b_data_dmpa) then b_data_dmpa.Y[bad_data, *] = !values.d_nan
                      if is_struct(b_data_bcs) then b_data_bcs.Y[bad_data, *] = !values.d_nan
                      
                      ; resave them
                      if is_struct(b_data_gse) then store_data, this_probe+'_'+instrument+'_b_gse_'+this_data_rate+'_'+level+suffix, data=b_data_gse, dlimits=gse_dl
                      if is_struct(b_data_gsm) then store_data, this_probe+'_'+instrument+'_b_gsm_'+this_data_rate+'_'+level+suffix, data=b_data_gsm, dlimits=gsm_dl
                      if is_struct(b_data_dmpa) then store_data, this_probe+'_'+instrument+'_b_dmpa_'+this_data_rate+'_'+level+suffix, data=b_data_dmpa, dlimits=dmpa_dl
                      if is_struct(b_data_bcs) then store_data, this_probe+'_'+instrument+'_b_bcs_'+this_data_rate+'_'+level+suffix, data=b_data_bcs, dlimits=bcs_dl
                  endif
                endif
            endif
            
            ; force the FGM data to be monotonic
            tplot_force_monotonic, this_probe+'_'+instrument+'_b_*_'+this_data_rate+'_'+level+suffix, /forward
            
            if ~keyword_set(no_split_vars) then begin
                ; split the FGM data into 2 tplot variables, one containing the vector and one containing the magnitude
                mms_split_fgm_data, this_probe, instrument=instrument, tplotnames = tplotnames, suffix = suffix, level = level, data_rate = this_data_rate
            endif 
            
            ; delete the ephemeris variables if not requested
            if ~keyword_set(get_fgm_ephemeris) then begin
                del_data, this_probe+'_'+instrument+'_r_gse_'+this_data_rate+'_'+level+suffix
                del_data, this_probe+'_'+instrument+'_r_gsm_'+this_data_rate+'_'+level+suffix
                del_data, this_probe+'_pos_gse'+suffix
                del_data, this_probe+'_pos_gsm'+suffix
            endif else begin
                dprint, dlevel = 0, 'Keeping ephemeris variables from FGM data files.'
                ; force the ephemeris variables to be monotonic
                tplot_force_monotonic, this_probe+'_'+instrument+'_r_*_'+this_data_rate+'_'+level+suffix, /forward
                tplot_force_monotonic, this_probe+'_pos_gse'+suffix, /forward
                tplot_force_monotonic, this_probe+'_pos_gsm'+suffix, /forward
                if ~keyword_set(no_split_vars) then begin
                    mms_split_fgm_eph_data, probe=this_probe, level = level, suffix = suffix, data_rate = data_rate, $
                      instrument=instrument, tplotnames = tplotnames
                endif
            endelse
            
            ; set some of the metadata
            mms_fgm_fix_metadata, tplotnames, prefix = 'mms' + probes, instrument = instrument, data_rate = this_data_rate, suffix = suffix, level=level
            
        endfor
    endfor

end