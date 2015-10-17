;+
; PROCEDURE:
;         mms_load_fgm
;         
; PURPOSE:
;         Load MMS AFG and/or DFG data
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. fgm levels include 'l1a', 'l1b',
;                        'ql'. the default if no level is specified is 'ql'
;         datatype:     currently all data types for fgm are retrieved (datatype not specified)
;         data_rate:    instrument data rates for fgm include 'brst' 'fast' 'slow' 'srvy'. The
;                       default is 'srvy'.
;         instrument:   fgm instruments are 'dfg' and 'afg'. default value is 'dfg'
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using 
;                       this load routine from a terminal without an X server runningdo not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is 
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;             
; OUTPUT:
; 
; EXAMPLE:
;     For examples see crib sheets mms_load_fgm_crib.pro, and mms_load_fgm_brst_crib.pro
;     
;     load MMS AFG burst data for MMS 1
;     MMS>  mms_load_fgm, probes=['1'], instrument='afg', data_rate='brst', level='ql'
;     
;     load MMS QL DFG data for MMS 1 and MMS 2
;     MMS>  mms_load_dfg, probes=[1, 2], trange=['2015-06-22', '2015-06-23'], level='ql'
;
; NOTES:
;     1) See the notes in mms_load_data for rules on the use of MMS data
;     
;     2) This routine is meant to be called from mms_load_afg and mms_load_dfg
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-10-16 13:52:13 -0700 (Fri, 16 Oct 2015) $
;$LastChangedRevision: 19092 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fgm.pro $
;-

; takes in 4-d AFG/DFG data as a tplot variable and splits into 2 tplot variables: 
;   1) b_total, 2) b_vector (Bx, By, Bz)
pro mms_split_fgm_data, probe, tplotnames = tplotnames, suffix = suffix, level = level, data_rate = data_rate, instrument = instrument
    if undefined(level) then level = ''
    if undefined(suffix) then suffix = ''
    if level eq 'l2pre' then data_rate_mod = data_rate + '_l2pre' else data_rate_mod = data_rate
    coords = ['dmpa', 'gse']

    for c_idx = 0, n_elements(coords)-1 do begin
        tplot_name = probe + '_'+instrument+'_'+data_rate_mod+'_'+coords[c_idx]+suffix
    
        get_data, tplot_name, data=fgm_data, dlimits=fgm_dlimits
    
        if is_struct(fgm_data) && is_struct(fgm_dlimits) then begin
          
            ; strip suffix off tplot_name. this prevents suffix from occuring twice in tplot variable name
            if suffix NE '' then tplot_name=strmid(tplot_name, 0, strpos(tplot_name, suffix))
            store_data, tplot_name + '_bvec'+suffix, data={x: fgm_data.X, y: [[fgm_data.Y[*, 0]], [fgm_data.Y[*, 1]], [fgm_data.Y[*, 2]]]}, dlimits=fgm_dlimits
            store_data, tplot_name + '_btot'+suffix, data={x: fgm_data.X, y: fgm_data.Y[*, 3]}, dlimits=fgm_dlimits
            
            ; need to add the newly created variables from the previous procedure to the list of tplot names
            append_array, tplotnames, tplot_name + '_bvec'+suffix
            append_array, tplotnames, tplot_name + '_btot'+suffix
            
            ; uncomment the following to remove the old variable
            ; del_data, tplot_name+suffix
            ; tplotnames = ssl_set_complement([tplot_name+suffix], tplotnames)
        endif else begin
            dprint, dlevel = 0, 'Error splitting the tplot variable: ', tplot_name+suffix
        endelse
    endfor
end

; sets colors and labels for tplot
pro mms_load_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = ''
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'
    instrument = strlowcase(instrument) ; just in case we get an upper case instrument
    if level eq 'l2pre' then data_rate = data_rate + '_l2pre'

    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]
  
            case tplot_name of
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_gse_bvec'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_gse_btot'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['B_total']
                end 
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_dmpa_bvec'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_dmpa_btot'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['B_total']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_gsm_dmpa'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end 
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_dmpa'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_omb'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument) + ' OMB'
                end 
                prefix[sc_idx] + '_'+instrument+'_'+data_rate+'_bcs'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!C' + strupcase(instrument) + ' BCS'
                end
                prefix[sc_idx] + '_ql_pos_gsm'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'labels', ['Xgsm', 'Ygsm', 'Zgsm', 'R']
                end
                prefix[sc_idx] + '_ql_pos_gse'+suffix: begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'labels', ['Xgse', 'Ygse', 'Zgse', 'R']
                end
                else: ; not doing anything
            endcase
        endfor
    endfor
end

pro mms_load_fgm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, instrument = instrument, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    probes = strcompress(string(probes), /rem) ; force the array to be an array of strings
    if undefined(datatype) then datatype = '' ; grab all data in the CDF
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    
    if undefined(level) then level = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, time_clip = time_clip, no_update = no_update, $
        suffix = suffix

    ; load the atttude data to do the coordinate transformation 
    mms_load_state, trange = trange, probes = probes, level = 'def', datatypes=['spinras', 'spindec'], $
        suffix = suffix

    ; DMPA coordinates to GSE, for each probe
    for probe_idx = 0, n_elements(probes)-1 do begin
        this_probe = 'mms'+strcompress(string(probes[probe_idx]), /rem)
        ; make sure the attitude data has been loaded before doing the cotrans operation
        if tnames(this_probe+'_defatt_spinras'+suffix) ne '' && tnames(this_probe+'_defatt_spindec'+suffix) ne '' $
            && tnames(this_probe+'_'+instrument+'_'+data_rate+'_dmpa'+suffix) ne '' then begin

            dmpa2gse, this_probe+'_'+instrument+'_'+data_rate+'_dmpa'+suffix, this_probe+'_defatt_spinras'+suffix, $
                this_probe+'_defatt_spindec'+suffix, this_probe+'_'+instrument+'_'+data_rate+'_gse'+suffix
            append_array, tplotnames, this_probe+'_'+instrument+'_'+data_rate+'_gse'+suffix
            
        endif
        ; split the FGM data into 2 tplot variables, one containing the vector and one containing the magnitude
        mms_split_fgm_data, this_probe, instrument=instrument, tplotnames = tplotnames, suffix = suffix, level = level, data_rate = data_rate
    endfor
    
    ; set some of the metadata for the DFG/AFG instruments
    mms_load_fix_metadata, tplotnames, prefix = 'mms' + probes, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level

end