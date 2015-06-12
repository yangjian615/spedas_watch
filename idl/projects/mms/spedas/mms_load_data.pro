;+
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Load MMS data for the AFG/DFG magnetometers into tplot variables
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: currently accepts AFG or DFG
;         datatype: not implemented yet
;         local_data_dir: local directory to store the CDF files; should be set if 
;             you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         remote_data_dir: server location where the data files are located; see
;             notes below for the default
;         attitude_data: load L-right ascension and L-declination attitude data
;             from the definitive attitude data files located at:
;         
;             http://lasp.colorado.edu/mms/sdc/about/browse/ancillary/mms#/defatt/
;             
;             WARNING: these data files are large (70MB+, in some cases), and the 
;             load routine may grab more than a single file to get full coverage
;             for a single day.
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     1) With no remote_data_dir specified, this routine grabs the data in CDFs from:
;         http://lasp.colorado.edu/mms/sdc/about/browse/mms#/?fg/srvy/[level]/YYYY/MM/
;         
;     2) I expect this routine to change significantly as the MMS data products are 
;         released to the public and feedback comes in from scientists - egrimes@igpp
;
;     3) See the following regarding rules for the use of MMS data:
;         https://lasp.colorado.edu/galaxy/display/mms/MMS+Data+Rights+and+Rules+for+Data+Use
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-06-10 15:09:43 -0700 (Wed, 10 Jun 2015) $
;$LastChangedRevision: 17850 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

; takes in 4-d AFG/DFG data as a tplot variable and splits into 2 tplot variables: 1) b_total, 2) b_vector (Bx, By, Bz)
pro mms_split_fgm_data, tplot_name, tplotnames = tplotnames
    get_data, tplot_name, data=fgm_data, dlimits=fgm_dlimits
    
    if is_struct(fgm_data) && is_struct(fgm_dlimits) then begin
        store_data, tplot_name + '_bvec', data={x: fgm_data.X, y: [[fgm_data.Y[*, 0]], [fgm_data.Y[*, 1]], [fgm_data.Y[*, 2]]]}, dlimits=fgm_dlimits
        store_data, tplot_name + '_btot', data={x: fgm_data.X, y: fgm_data.Y[*, 3]}, dlimits=fgm_dlimits
        
        ; need to add the newly created variables from the previous procedure to the list of tplot names
        append_array, tplotnames, tplot_name + '_bvec'
        append_array, tplotnames, tplot_name + '_btot'
        
        ; remove the old variable
        del_data, tplot_name
    endif else begin
        dprint, dlevel = 0, 'Error splitting the tplot variable: ', tplot_name
    endelse
end

; sets colors and labels for tplot
pro mms_load_fix_metadata, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = ''
    
    for name_idx = 0, n_elements(tplotnames)-1 do begin
        tplot_name = tplotnames[name_idx]

        case tplot_name of
            prefix + '_dfg_srvy_dmpa_bvec': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6]
                options, /def, tplot_name, 'ytitle', 'MMS DFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
            end
            prefix + '_dfg_srvy_dmpa_btot': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [0]
                options, /def, tplot_name, 'ytitle', 'MMS DFG'
                options, /def, tplot_name, 'labels', ['B_total']
            end
            prefix + '_afg_srvy_dmpa_bvec': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6]
                options, /def, tplot_name, 'ytitle', 'MMS AFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
            end
            prefix + '_afg_srvy_dmpa_btot': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [0]
                options, /def, tplot_name, 'ytitle', 'MMS AFG'
                options, /def, tplot_name, 'labels', ['B_total']
            end
            prefix + '_ql_pos_gsm': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'labels', ['Xgsm', 'Ygsm', 'Zgsm', 'R']
            end
            prefix + '_ql_pos_gse': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'labels', ['Xgse', 'Ygse', 'Zgse', 'R']
            
            end
            else: ; not doing anything
        endcase
    endfor
end

function mms_load_defatt_file, filename
    if filename eq '' then begin
        dprint, dlevel = 0, 'Error loading a definitive attitude file - no filename given.'
        return, 0
    endif
    ; from ascii_template on a definitive attitude file
    defatt_template = { VERSION: 1.00000, $
        DATASTART: 49, $
        DELIMITER: 32b, $
        MISSINGVALUE: !values.D_NAN, $
        COMMENTSYMBOL: 'COMMENT', $
        FIELDCOUNT: 21, $
        FIELDTYPES: [7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7], $
        FIELDNAMES: ['Time', 'Elapsed', 'q1', 'q2', 'q3', 'qc', 'wX', 'wY', 'wZ', 'wPhase', 'zRA', 'zDec', 'ZPhase', 'LRA', 'LDec', 'LPhase', 'PRA', 'PDec', 'PPhase', 'Nut', 'QF'], $
        FIELDLOCATIONS: [0, 22, 38, 47, 55, 65, 73, 80, 87, 94, 102, 111, 118, 126, 135, 142, 150, 159, 166, 176, 183], $
        FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]}
    
    def_att = read_ascii(filename, template=defatt_template, count=num_items)
    
    return, def_att
end

pro mms_load_defatt_tplot, filenames, tplotnames = tplotnames, prefix = prefix
    ; print a warning about how long this takes so user's do not
    ; assume the process is frozen after a few seconds
    dprint, dlevel = 1, 'Loading definitive attitude files can take some time; please be patient...'
    if undefined(prefix) then prefix = 'mms'

    for file_idx = 0, n_elements(filenames)-1 do begin
        ; load the data from the ASCII file
        new_def_att_data = mms_load_defatt_file(filenames[file_idx])
        if is_struct(new_def_att_data) then begin
            ; note on time format in this file:
            ; date/time values are stored in the format: YYYY-DOYThh:mm:ss.fff
            ; so to convert the first time value to a time_double, 
            ;    time_values = time_double(new_def_att_data.time, tformat='YYYY-DOYThh:mm:ss.fff')
            append_array, time_values, time_double(new_def_att_data.time[0:n_elements(new_def_att_data.time)-2], tformat='YYYY-DOYThh:mm:ss.fff')
            append_array, def_att_data_ras, new_def_att_data.LRA[0:n_elements(new_def_att_data.time)-2]
            append_array, def_att_data_dec, new_def_att_data.LDEC[0:n_elements(new_def_att_data.time)-2]
        endif
    endfor
    
    ; check that some data was actually loaded in
    if undefined(time_values) then begin
        dprint, dlevel = 0, 'Error loading attitude data - no data was loaded.'
        return
    endif
    
    store_data, prefix + '_defatt_spinras', data={x: time_values, y: def_att_data_ras}
    store_data, prefix + '_defatt_spindec', data={x: time_values, y: def_att_data_dec}
    
    append_array, tplotnames, prefix + ['_defatt_spinras', '_defatt_spindec']
end

pro mms_load_defatt_data, probe = probe, trange = trange, tplotnames = tplotnames
    
    if undefined(trange) then begin
        dprint, dlevel = 0, 'Error loading the definitive attitude data - no time range given.'
        return
    endif
    if undefined(probe) then begin
        dprint, dlevel = 0, 'Error loading MMS definitive attitude data - no probe given.'
        return
    endif 
    if not keyword_set(remote_data_dir) then remote_data_dir = 'http://lasp.colorado.edu/mms/sdc/about/browse/'
    if not keyword_set(local_data_dir) then local_data_dir = 'c:\data\mms\'
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if not keyword_set(source) then source = !mms
    probe = strcompress(string(probe), /rem)
    start_time = time_struct(trange[0])
    end_time = time_struct(trange[1])
    
    ; these aren't by day, so we should get several days to ensure we have overlap
    doys = end_time.doy-start_time.doy+1
    
    for doy=0, doys-1 do begin
        start_doy = strcompress(string(doy+start_time.doy-1), /rem)
        end_doy = strcompress(string(start_time.doy+doy), /rem)

        the_path_format = 'ancillary/mms'+probe+'/defatt/MMS'+probe+'_DEFATT_2015'+start_doy+'_2015'+end_doy+'.V00'
        append_array, daily_names, the_path_format
    endfor
    
    files = file_retrieve(daily_names, _extra=source, /last_version)
    
    ; load the data into tplot variables
    mms_load_defatt_tplot, files, tplotnames = tplotnames, prefix = 'mms'+probe
end

pro mms_load_data, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, level = level, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                   attitude_data = attitude_data, no_download = no_download, $
                   no_server = no_server

    if not keyword_set(datatype) then datatype = '*'
    ; currently, datatype = level
    if datatype ne '*' && undefined(level) then level = datatype
    if not keyword_set(level) then level = 'ql'
    if not keyword_set(instrument) then instrument = 'dfg' ; default to DFG
    if not keyword_set(probes) then probes = ['1']
    if probes[0] eq '*' then probes = [1, 2, 3, 4]
    
    ; make sure important strings are lower case
    instrument = strlowcase(instrument)
    level = strlowcase(level)
    
    if not keyword_set(remote_data_dir) then remote_data_dir = 'http://lasp.colorado.edu/mms/sdc/about/browse/'
    if not keyword_set(local_data_dir) then local_data_dir = 'c:\data\mms\'
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if not keyword_set(source) then source = !mms
      
    tn_list_before = tnames('*')
    
    pathformat = strarr(n_elements(probes))
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        ; currently defaulting to V0.0.0 of the CDFs 
        ; TODO: this needs to be updated to grab the latest version of the CDF file.
        pathformat[probe_idx] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
            instrument + '/srvy/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
            '_' + instrument + '_srvy_'+level+'_YYYYMMDD_v0.0.0.cdf'
    endfor

    for probe_idx = 0, n_elements(probes)-1 do begin
        relpathnames = file_dailynames(file_format=pathformat[probe_idx], trange=tr, /unique)
        
        ; the following is a kludge to deal with the fact that "mm" in "mms" 
        ; is interpreted by file_dailynames as 00 (minute?)
        for path_idx = 0, n_elements(relpathnames)-1 do begin
            real_path = relpathnames[path_idx]
            str_replace, real_path, 'PROBE', 'mms'
            str_replace, real_path, 'PROBE', 'mms' ; str_replace only replaces the first it finds
            relpathnames[path_idx] = real_path
        endfor
        files = file_retrieve(relpathnames, _extra=source, /last_version, no_download=no_download, no_server=no_server)
        cdf2tplot, files, tplotnames = tplotnames
        
        ; if this is AFG/DFG data, split the tplot variables into one for the vector
        ; and one for the magnitude
        mms_split_fgm_data, 'mms' + strcompress(string(probes[probe_idx]), /rem) + '_' + instrument + '_srvy_dmpa', tplotnames = tplotnames
        
        ; fix the metadata. currently sets the colors
        mms_load_fix_metadata, tplotnames, prefix = 'mms' + strcompress(string(probes[probe_idx]), /rem)
        
        ; load the attitude data for this probe, if the user requested it
        if ~undefined(attitude_data) then begin
            mms_load_defatt_data, probe=strcompress(string(probes[probe_idx]), /rem), trange=tr, tplotnames = tplotnames
        endif
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
end