;+
; PROCEDURE:
;         mms_load_state
;
; PURPOSE:
;         Load MMS state (position, attitude) data
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
;$LastChangedDate: 2015-07-23 09:55:18 -0700 (Thu, 23 Jul 2015) $
;$LastChangedRevision: 18218 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_state.pro $
;-

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
    ;if not keyword_set(local_data_dir) then local_data_dir = 'c:\data\mms\'
    if undefined(local_data_dir) then local_data_dir = ''
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