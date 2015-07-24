;+
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Generic MMS load data routine; typically called from instrument specific 
;           load routines - mms_load_???, i.e., mms_load_fgm, mms_load_fpi, etc.
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: instrument, AFG, DFG, etc.
;         datatype: not implemented yet 
;         local_data_dir: local directory to store the CDF files; should be set if 
;             you're on *nix or OSX, the default currently assumes the IDL working directory
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
;$LastChangedDate: 2015-07-23 09:55:18 -0700 (Thu, 23 Jul 2015) $
;$LastChangedRevision: 18218 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

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

pro mms_load_data, trange = trange, probes = probes, datatype = datatype, $
                  level = level, instrument = instrument, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, login_info = login_info
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    
    ; currently, datatype = level
    if datatype ne '*' && undefined(level) then level = datatype
    if undefined(level) then level = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'
   ; if undefined(local_data_dir) then local_data_dir = 'c:\data\mms\'
    if undefined(local_data_dir) then local_data_dir = ''
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if undefined(source) then source = !mms
    
    status = mms_login_lasp(login_info = login_info)
    if status ne 1 then return
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        probe = 'mms' + strcompress(string(probes[probe_idx]), /rem)
        pathformat = instrument + '/' + data_rate + '/'+level+'/YYYY/MM/DD'
        
        daily_names = file_dailynames(file_format=pathformat, trange=tr, /unique, times=times)

        for name_idx = 0, n_elements(daily_names)-1 do begin
            day_string = time_string(times[name_idx], tformat='YYYY-MM-DD')
            end_string = time_string(times[name_idx]+86401, tformat='YYYY-MM-DD') ; +1 day
            
            ; want to store all the CDFs in the month folder, not create a new folder for each day
            ; note: we still use /DD in the pathformat because file_dailynames needs it to 
            ; create a different name for each day
            split_dir = strsplit(daily_names[name_idx], '/', /extract)
            month_directory = strjoin(split_dir[0:n_elements(split_dir)-2], '/')
            
            data_file = mms_get_science_file_info(sc_id=probe, instrument_id=instrument, $
                    data_rate_mode=data_rate, data_level=level, start_date=day_string, end_date=end_string)
            
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
            num_filenames = n_elements(filename)
            
            file_dir = strlowcase(local_data_dir + probe + '/' + month_directory)
            
            for file_idx = 0, num_filenames-1 do begin
                same_file = mms_check_file_exists(remote_file_info[file_idx], file_dir = file_dir)
                
                if same_file eq 0 then begin
                    dprint, dlevel = 0, 'Downloading ' + filename[file_idx] + ' to ' + file_dir
                    status = get_mms_science_file(filename=filename[file_idx], local_dir=file_dir)
                    
                    if status eq 0 then append_array, files, file_dir + '/' + filename[file_idx]
                endif else begin
                    dprint, dlevel = 0, 'Loading local file ' + file_dir + '/' + filename[file_idx]
                    append_array, files, file_dir + '/' + filename[file_idx]
                endelse
            endfor
        endfor
        
        if ~undefined(files) then cdf2tplot, files, tplotnames = tplotnames, varformat='*'
        
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