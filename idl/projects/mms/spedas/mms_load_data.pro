;+
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Load MMS data
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: instrument, AFG, DFG, etc.
;         datatype: not implemented yet 
;         local_data_dir: local directory to store the CDF files; should be set if 
;             you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         attitude_data: load L-right ascension and L-declination attitude data
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     1) I expect this routine to change significantly as the MMS data products are 
;         released to the public and feedback comes in from scientists - egrimes@igpp
;
;     2) See the following regarding rules for the use of MMS data:
;         https://lasp.colorado.edu/galaxy/display/mms/MMS+Data+Rights+and+Rules+for+Data+Use
;         
;     3) Updated to use the MMS web services API
;     
;     4) The LASP web services API uses SSL/TLS, which is only supported by IDLnetURL 
;         in IDL 7.1 and later. 
;         
;     5) CDF version 3.6 is required to correctly handle the 2015 leap second.  CDF versions before 3.6
;         will give incorrect time tags for data loaded after June 30, 2015 due to this issue.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-06-24 13:20:52 -0700 (Wed, 24 Jun 2015) $
;$LastChangedRevision: 17959 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

function mms_login_lasp, login_info = login_info
    ; halt and warn the user if they're using IDL before 7.1 due to SSL/TLS issue
    if double(!version.release) lt 7.1d then begin
      dprint, dlevel = 0, 'Error, IDL 7.1 or later is required to use mms_load_data.'
      return, -1
    endif
    
    ; restore the login info
    if undefined(login_info) then login_info = 'mms_auth_vassilis.sav'
    
    ; check that the auth file exists before trying to restore it
    file_exists = file_test(login_info, /regular)
    
    if file_exists eq 1 then begin
        restore, login_info
    endif else begin
        ; prompt the user for their SDC username/password
        login_info_widget = login_widget(title='MMS SDC Login')
        
        if is_struct(login_info_widget) then begin
            auth_info = {user: login_info_widget.username, password: login_info_widget.password}
            
            ; now save the user/pass to a sav file to remember it in future sessions
            save, auth_info, filename = login_info
        endif
    endelse
    
    if is_struct(auth_info) then begin
        username = auth_info.user
        password = auth_info.password
    endif else begin
        ; need to login to access the web services API
        dprint, dlevel = 0, 'Error, need to provide login information to access the web services API via the login_info keyword'
        return, -1
    endelse
    
    
    ; the IDLnetURL object returned here is also stored in the common block
    ; (this is why we never use net_object after this line, but this call is still 
    ; necessary to login)
    net_object = get_mms_sitl_connection(username=username, password=password)
    return, 1
end

; returns 1 for the file exists and has the same filesize as the remote file
; returns 0 otherwise
function mms_check_file_exists, remote_file_info, file_dir = file_dir
    filename = remote_file_info.filename
    
    ; make sure the directory exists
    dir_search = file_search(file_dir, /test_directory)
    if dir_search eq '' then file_mkdir2, file_dir
    
    ; check if the file exists
    file_exists = file_test(file_dir + '/' + filename, /regular)

    ; if it does, only download if it the sizes are different
    same_file = 0
    if file_exists eq 1 then begin
        ; the file exists, check the size
        f_info = file_info(file_dir + '/' + filename)
        local_file_size = f_info.size
        remote_file_size = remote_file_info.filesize
        if long(local_file_size) eq long(remote_file_size) then same_file = 1
    endif
    return, same_file
end

; for some reason, the JSON object returned by the server is
; an array of strings, with even indices (0, 2, 4, ..) containing
; file names (along with other JSON stuff) and odd indices (1, 3, 5, ..) 
; containing file sizes (also along with other JSON stuff). This
; function parses out the filenames/filesizes from this array
; and returns an array of structs with the names and sizes
function mms_get_filename_size, json_object
    ; kludgy to deal with IDL's lack of a parser for json
    num_structs = n_elements(json_object)/2
    counter = 0
    remote_file_info = replicate({filename: '', filesize: 0l}, num_structs)
    
    for struct_idx = 0, n_elements(json_object)-1, 2 do begin
        ; even indices are filenames
        remote_file_info[counter].filename = (strsplit(json_object[struct_idx], '": "', /extract))[2]
        ; odd indices are filesizes
        remote_file_info[counter].filesize = (strsplit((strsplit(json_object[struct_idx+1], '": "', /extract))[1], '}', /extract))[0]
        counter += 1
    endfor
    return, remote_file_info
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

; data product:
;   defatt - definitive attitude data; currently loads RAs, decl of L vector
;   defeph - definitive ephemeris data; should load position, velocity
;   predatt - predicted attitude data
;   predeph - predicted ephemeris data
pro mms_load_defatt_data, probe = probe, trange = trange, tplotnames = tplotnames, $
                           login_info = login_info, data_product = data_product
    if undefined(trange) then begin
        dprint, dlevel = 0, 'Error loading MMS definitive attitude data - no time range given.'
        return
    endif
    if undefined(probe) then begin
        dprint, dlevel = 0, 'Error loading MMS definitive attitude data - no probe given.'
        return
    endif
    if undefined(data_product) then data_product = 'defatt'
    if not keyword_set(remote_data_dir) then remote_data_dir = 'https://lasp.colorado.edu/mms/sdc/about/browse/'
    if not keyword_set(local_data_dir) then local_data_dir = 'c:\data\mms\'
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if not keyword_set(source) then source = !mms
    
    probe = strcompress(string(probe), /rem)
    start_time = time_double(trange[0])-60*60*24.
    end_time = time_double(trange[1])
    
    start_time_str = time_string(start_time, tformat='YYYY-MM-DD')
    end_time_str = time_string(end_time, tformat='YYYY-MM-DD')
    
    file_dir = local_data_dir + 'ancillary/'

    status = mms_login_lasp(login_info=login_info)
    if status ne 1 then return
    
    ancillary_file_info = mms_get_ancillary_file_info(sc_id='mms'+probe, product=data_product, start_date=start_time_str, end_date=end_time_str)
    
    if ~is_array(ancillary_file_info) && ancillary_file_info eq '' then begin
        dprint, dlevel = 0, 'No MMS ' + data_product + ' files found for this time period.'
        return
    endif
    
    remote_file_info = mms_get_filename_size(ancillary_file_info)
    
    doys = n_elements(remote_file_info)
    
    
    ; make sure the directory exists
    dir_search = file_search(file_dir, /test_directory)
    if dir_search eq '' then file_mkdir2, file_dir
    
    for doy_idx = 0, doys-1 do begin
        ; check if the file exists
        same_file = mms_check_file_exists(remote_file_info[doy_idx], file_dir = file_dir)
        
        if same_file eq 0 then begin
            dprint, dlevel = 0, 'Downloading ' + remote_file_info[doy_idx].filename + ' to ' + file_dir
            status = get_mms_ancillary_file(filename=remote_file_info[doy_idx].filename, local_dir=file_dir)
    
            if status eq 0 then append_array, daily_names, file_dir + remote_file_info[doy_idx].filename
        endif else begin
            dprint, dlevel = 0, 'Loading local file ' + file_dir + remote_file_info[doy_idx].filename
            append_array, daily_names, file_dir + remote_file_info[doy_idx].filename
        endelse
    endfor
    mms_load_defatt_tplot, daily_names, tplotnames = tplotnames, prefix = 'mms'+probe

end


; takes in 4-d AFG/DFG data as a tplot variable and splits into 2 tplot variables: 
;   1) b_total, 2) b_vector (Bx, By, Bz)
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
                options, /def, tplot_name, 'ytitle', strupcase(prefix) + ' DFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
            end
            prefix + '_dfg_srvy_dmpa_btot': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [0]
                options, /def, tplot_name, 'ytitle',  strupcase(prefix) + ' DFG'
                options, /def, tplot_name, 'labels', ['B_total']
            end
            prefix + '_dfg_srvy_gsm_dmpa': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'ytitle', strupcase(prefix) + ' DFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
            end
            prefix + '_afg_srvy_dmpa_bvec': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6]
                options, /def, tplot_name, 'ytitle', strupcase(prefix) + ' AFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
            end
            prefix + '_afg_srvy_dmpa_btot': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [0]
                options, /def, tplot_name, 'ytitle',  strupcase(prefix) + ' AFG'
                options, /def, tplot_name, 'labels', ['B_total']
            end
            prefix + '_afg_srvy_gsm_dmpa': begin
                options, /def, tplot_name, 'labflag', 1
                options, /def, tplot_name, 'colors', [2,4,6,8]
                options, /def, tplot_name, 'ytitle', strupcase(prefix) + ' AFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
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

pro mms_load_data, trange = trange, probes = probes, datatype = datatype, $
                  level = level, instrument = instrument, data_rate = date_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, login_info = login_info
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    
    ; currently, datatype = level
    if datatype ne '*' && undefined(level) then level = datatype
    if undefined(level) then level = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(local_data_dir) then local_data_dir = 'c:\data\mms\'
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if undefined(source) then source = !mms
    
    status = mms_login_lasp(login_info = login_info)
    if status ne 1 then return
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        probe = 'mms' + strcompress(string(probes[probe_idx]), /rem)
        pathformat = instrument + '/srvy/'+level+'/YYYY/MM/DD'
        
        daily_names = file_dailynames(file_format=pathformat, trange=tr, /unique, times=times)

        for name_idx = 0, n_elements(daily_names)-1 do begin
            day_string = time_string(times[name_idx], tformat='YYYY-MM-DD')
            
            ; want to store all the CDFs in the month folder, not create a new folder for each day
            ; note: we still use /DD in the pathformat because file_dailynames needs it to 
            ; create a different name for each day
            split_dir = strsplit(daily_names[name_idx], '/', /extract)
            month_directory = strjoin(split_dir[0:n_elements(split_dir)-2], '/')
            
            data_file = mms_get_science_file_info(sc_id=probe, instrument_id=instrument, $
                    data_rate_mode=data_rate, data_level=level, start_date=day_string, end_date=day_string)

            if ~is_array(data_file) && data_file eq '' then begin
                dprint, dlevel = 0, 'Error, no data files found for this time.'
                continue
            endif
            
            remote_file_info = mms_get_filename_size(data_file)
            
            if ~is_struct(remote_file_info) then begin
                dprint, dlevel = 0, 'Error getting the information on remote files'
                return
            endif
            
            filename = remote_file_info.filename
            file_dir = strlowcase(local_data_dir + probe + '/' + month_directory)
            same_file = mms_check_file_exists(remote_file_info, file_dir = file_dir)
            
            if same_file eq 0 then begin
                dprint, dlevel = 0, 'Downloading ' + filename + ' to ' + file_dir
                status = get_mms_science_file(filename=filename, local_dir=file_dir)
                
                if status eq 0 then append_array, files, file_dir + '/' + filename
            endif else begin
                dprint, dlevel = 0, 'Loading local file ' + file_dir + '/' + filename
                append_array, files, file_dir + '/' + filename
            endelse
        endfor
        
        if ~undefined(files) then cdf2tplot, files, tplotnames = tplotnames
        
        ; MMS fluxgate data includes the magnitude as the last component; this routine
        ; splits the tplot variable into 2 variables: one containing b_total and one containing
        ; the field vector
        mms_split_fgm_data, probe + '_' + instrument + '_srvy_dmpa', tplotnames = tplotnames
        
        ; set some metadata
        mms_load_fix_metadata, tplotnames, prefix = probe
        
        ; load the definitive attitude data (right ascension, declination) of the L vector
        mms_load_defatt_data, probe = probes[probe_idx], trange = trange, tplotnames = tplotnames
        
        ; check that the definitive attitude data was loaded
        if tnames(probe+'_defatt_spinras') ne '' && tnames(probe+'_defatt_spindec') ne '' then begin
            ; go ahead and do the DMPA -> transformation on the DFG/AFG data
            dmpa2gse, probe+'_'+instrument+'_srvy_dmpa_bvec', probe+'_defatt_spinras', probe+'_defatt_spindec',probe+'_'+instrument+'_srvy_gse'
            append_array, tplotnames, probe+'_'+instrument+'_srvy_gse' ; for time clipping
        endif
        
        ; forget about the daily files for this probe
        undefine, files
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
    
end