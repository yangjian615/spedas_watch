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
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-06-12 14:32:34 -0700 (Fri, 12 Jun 2015) $
;$LastChangedRevision: 17871 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

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
                options, /def, tplot_name, 'colors', [2,4,6]
                options, /def, tplot_name, 'ytitle', strupcase(prefix) + ' DFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
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
                options, /def, tplot_name, 'colors', [2,4,6]
                options, /def, tplot_name, 'ytitle', strupcase(prefix) + ' AFG'
                options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
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
                  login_info = login_info
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    if undefined(level) then level = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(local_data_dir) then local_data_dir = 'c:\data\mms\'
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if undefined(source) then source = !mms
    
    ; restore the login info
    if undefined(login_info) then login_info = 'mms_auth_vassilis.sav'
    restore, login_info
    if is_struct(auth_info) then begin
        username = auth_info.user
        password = auth_info.password
    endif else begin
        ; need to login to access the web services API
        dprint, dlevel = 0, 'Error, need to provide login information to access the web services API via the login_info keyword'
        return
    endelse
    
    net_object = get_mms_sitl_connection(username=username, password=password)
    
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
        
            filename = (strsplit(data_file[0], '": "', /extract))[2] ;kldugy
            
            ; make sure the directory exists
            file_dir = local_data_dir + probe+'/'+month_directory
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
                remote_file_size = (strsplit((strsplit(data_file[1], '": "', /extract))[1], '}', /extract))[0]
                if long(local_file_size) eq long(remote_file_size) then same_file = 1
            endif
            
            if same_file eq 0 then begin
                dprint, dlevel = 1, 'Downloading ' + filename + ' to ' + file_dir
                status = get_mms_science_file(filename=filename, local_dir=file_dir)
                
                if status eq 0 then append_array, files, file_dir + '/' + filename
            endif else append_array, files, file_dir + '/' + filename
        endfor
        
        if ~undefined(files) then cdf2tplot, files, tplotnames = tplotnames
        
        ; MMS fluxgate data includes the magnitude as the last component; this routine
        ; splits the tplot variable into 2 variables: one containing b_total and one containing
        ; the field vector
        mms_split_fgm_data, probe + '_' + instrument + '_srvy_dmpa', tplotnames = tplotnames
        
        ; set some metadata
        mms_load_fix_metadata, tplotnames, prefix = probe
        
        ; forget about the files for this probe
        undefine, files
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
    
end