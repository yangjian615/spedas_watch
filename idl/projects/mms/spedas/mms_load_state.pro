;+
; PROCEDURE:
;         mms_load_state
;
; PURPOSE:
;         Load MMS state (position, attitude) data
;
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC ['*','1','2','3','4'] 
;         level: ['def', 'pred'] predicted or definitive attitude the default is to search for definitive
;              data first and if not found search for predicted data. To turn this feature off use the keyword
;              pred_or_def (see below)
;         datatypes: ephemeris or attitude or both ['*','pos', 'vel', 'spinras', 'spindec']  (default is '*')
;         local_data_dir: local directory to store the CDF files; should be set if
;             you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         attitude_data: flag to only load L-right ascension and L-declination attitude data 
;         ephemeris_data: flag to only load position and velocity data
;         no_download: set flag to use local data only (no download)
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
;         pred_or_def: set this flag to turn off looking for predicted data if definitive not found
;            (pred_or_def=0 will return only the level that was requested)
;            
; OUTPUT:
;
; EXAMPLES: 
; 
;   MMS> tr=['2015-07-21','2015-07-22']
;   MMS> mms_load_state, probe='1', trange=tr
;   MMS> mms_load_state, probe='*', level='def', trange=tr
;   MMS> mms_load_state, probe=['1','3'], datatypes='pos', trange=tr
;   MMS> mms_load_state, probe=['1','3'], datatypes=['pos', 'spinras'], trange=tr
;   MMS> mms_load_state, probe=['1','2,','3'], datatypes='*', level='pred', trange=tr
;   MMS> mms_load_state, probe='1', /attitude_only, trange=tr
;   MMS> mms_load_state, probe='*', /ephemeris_only, level='pred', trange=tr
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
;     6) If no level ('pred' or 'def') is specified the routine defaults to 'def'. When 'def' data is 
;        retrieved and the start time requested is the same as the time of the last available definitive 
;        file or near the current date it's possible that only partial definitive data is available or that 
;        no data is available. Partial data is due to the fact that MMS files don't go from 0-24hrs but 
;        rather start at ~midday. Whenever partial data is available a warning message is displayed in the 
;        console window and the partial data is loaded. 
;     
;        When no data is available the user is notified and no further action is taken. The user can re-request 
;        the data by adding or changing the keyword level to 'pred' or in the GUI by clicking on 'pred' in the 
;        level text box.
;        
;        Time frames can span several days or weeks. If long time spans start in the definitive range and
;        end in the predicted time range the user will get either partial 'def' or 'pred' depending on
;        what the level keyword is set to. 
;        
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-26 15:42:27 -0700 (Wed, 26 Aug 2015) $
;$LastChangedRevision: 18634 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_state.pro $
;-

function mms_read_def_att_file, filename
    if filename eq '' then begin
        dprint, dlevel = 0, 'Error loading a attitude file - no filename given.'
        return, 0
    endif
    ; from ascii_template on a definitive attitude file
    att_template = { VERSION: 1.00000, $
        DATASTART: 49, $
        DELIMITER: 32b, $
        MISSINGVALUE: !values.D_NAN, $
        COMMENTSYMBOL: 'COMMENT', $
        FIELDCOUNT: 21, $
        FIELDTYPES: [7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7], $
        FIELDNAMES: ['Time', 'Elapsed', 'q1', 'q2', 'q3', 'qc', 'wX', 'wY', 'wZ', 'wPhase', 'zRA', 'zDec', 'ZPhase', 'LRA', 'LDec', 'LPhase', 'PRA', 'PDec', 'PPhase', 'Nut', 'QF'], $
        FIELDLOCATIONS: [0, 22, 38, 47, 55, 65, 73, 80, 87, 94, 102, 111, 118, 126, 135, 142, 150, 159, 166, 176, 183], $
        FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]}

    att = read_ascii(filename, template=att_template, count=num_items)
    
    return, att
end

function mms_read_pred_att_file, filename
  if filename eq '' then begin
    dprint, dlevel = 0, 'Error loading a attitude file - no filename given.'
    return, 0
  endif
  ; from ascii_template on a definitive attitude file
  att_template = { VERSION: 1.00000, $
    DATASTART: 32, $
    DELIMITER: 32b, $
    MISSINGVALUE: !values.D_NAN, $
    COMMENTSYMBOL: 'COMMENT', $
    FIELDCOUNT: 5, $
    FIELDTYPES: [7, 4, 4, 4, 4], $
    FIELDNAMES: ['Time', 'Elapsed', 'LRA', 'LDec', 'wtot'], $
    FIELDLOCATIONS: [0, 22, 38, 47, 55], $
    FIELDGROUPS: [0, 1, 2, 3, 4]}

  att = read_ascii(filename, template=att_template, count=num_items)
 
  return, att
end

function mms_read_eph_file, filename
  if filename eq '' then begin
    dprint, dlevel = 0, 'Error loading a attitude file - no filename given.'
    return, 0
  endif
  ; from ascii_template on a definitive attitude file
  eph_template = { VERSION: 1.00000, $
    DATASTART: 14, $
    DELIMITER: 32b, $
    MISSINGVALUE: !values.D_NAN, $
    COMMENTSYMBOL: 'COMMENT', $
    FIELDCOUNT: 9, $
    FIELDTYPES: [7, 4, 4, 4, 4, 4, 4, 4, 4], $
    FIELDNAMES: ['Time', 'Elapsed', 'x', 'y', 'z', 'vx', 'vy', 'vz', 'kg'], $
    FIELDLOCATIONS: [0, 22, 40, 62, 88, 113, 138, 162, 188], $
    FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8]}

  ephdata = read_ascii(filename, template=eph_template, count=num_items)

  ephpos = make_array(n_elements(ephdata.x),3, /double)
  ephpos[*,0] = ephdata.x
  ephpos[*,1] = ephdata.y
  ephpos[*,2] = ephdata.z
  ephvel = make_array(n_elements(ephdata.x),3, /double)
  ephvel[*,0] = ephdata.vx
  ephvel[*,1] = ephdata.vy
  ephvel[*,2] = ephdata.vz
  eph={time:ephdata.time, pos:ephpos, vel:ephvel}

  return, eph
end

pro mms_load_att_tplot, filenames, tplotnames = tplotnames, prefix = prefix, level = level, $
  probe=probe, datatypes = datatypes, trange = trange

    ; print a warning about how long this takes so user's do not
    ; assume the process is frozen after a few seconds
    dprint, dlevel = 1, 'Loading attitude files can take some time; please be patient...'
    if undefined(prefix) then prefix = 'mms'
    if undefined(level) then level = 'def'
    
    for file_idx = 0, n_elements(filenames)-1 do begin
        ; load the data from the ASCII file
        if level EQ 'def' then new_att_data = mms_read_def_att_file(filenames[file_idx]) $
           else new_att_data = mms_read_pred_att_file(filenames[file_idx]) 

        if is_struct(new_att_data) then begin
            ; note on time format in this file:
            ; date/time values are stored in the format: YYYY-DOYThh:mm:ss.fff
            ; so to convert the first time value to a time_double,
            ;    time_values = time_double(new__att_data.time, tformat='YYYY-DOYThh:mm:ss.fff')
            append_array, time_values, time_double(new_att_data.time[0:n_elements(new_att_data.time)-2], tformat='YYYY-DOYThh:mm:ss.fff')            
            ; only load data products the user requested
            if where(datatypes EQ 'spinras') NE -1 then append_array, att_data_ras, new_att_data.LRA[0:n_elements(new_att_data.time)-2]
            if where(datatypes EQ 'spindec') NE -1 then append_array, att_data_dec, new_att_data.LDEC[0:n_elements(new_att_data.time)-2]            
        endif
    endfor

    ; sort and find uniq time_values since predicted files overlap each other
    idx=[uniq(time_values, sort(time_values))]
    time_values = time_values[idx]
    if ~undefined(att_data_ras) then att_data_ras = att_data_ras[idx]
    if ~undefined(att_data_dec) then att_data_dec = att_data_dec[idx]
    
    ; check that some data was actually loaded in
    if undefined(time_values) then begin
        dprint, dlevel = 0, 'Error loading attitude data - no data was loaded.'
        return
    endif else begin
    ; warn user if only partial data was loaded
    if time_values[0] GT time_double(trange[0]) OR time_values[n_elements(time_values)-1] LT time_double(trange[1]) then $
      dprint, dlevel = 1, 'Warning, not all data in the requested time frame was loaded.'
    endelse
    
    data_att = {coord_sys:'', st_type:'none', units:'deg'}
    dl = {filenames:filenames, data_att:data_att, ysubtitle:'[deg]'}
    if where(datatypes EQ 'spinras') NE -1 then begin
      spinras_name =  prefix + '_' + level + 'att_spinras'
      str_element,dl,'vname',spinras_name, /add
      store_data, spinras_name, data={x: time_values, y: att_data_ras}, dlimits=dl, l=0
      append_array, tplotnames, [spinras_name]
      dprint, dlevel = 1, 'Tplot variable created: '+ spinras_name
    endif
    if where(datatypes EQ 'spindec') NE -1 then begin
      spindec_name =  prefix + '_' + level + 'att_spindec'
      str_element,dl,'vname',spindec_name, /add_replace
      store_data, spindec_name, data={x: time_values, y: att_data_dec}, dlimits=dl, l=0
      append_array, tplotnames, [spindec_name]
      dprint, dlevel = 1, 'Tplot variable created: '+ spindec_name
    endif

end

pro mms_load_eph_tplot, filenames, tplotnames = tplotnames, prefix = prefix, level = level, $
  probe=probe, datatypes = datatypes, trange = trange
  
  ; print a warning about how long this takes so user's do not
  ; assume the process is frozen after a few seconds
  ;dprint, dlevel = 1, 'Loading ephemeris files can take some time; please be patient...'
  if undefined(prefix) then prefix = 'mms'
  if undefined(datatype) then datatype = 'def'

  for file_idx = 0, n_elements(filenames)-1 do begin
    ; load the data from the ASCII file
    new_eph_data = mms_read_eph_file(filenames[file_idx])
;    this_start = new_eph_data.time[0]
;    this_end = new_eph_data.time[n_elements(new_eph_data.time)-1]
    if is_struct(new_eph_data) then begin
      ; note on time format in this file:
      ; date/time values are stored in the format: YYYY-DOYThh:mm:ss.fff
      ; so to convert the first time value to a time_double,
      ;    time_values = time_double(new__att_data.time, tformat='YYYY-DOYThh:mm:ss.fff')
      append_array, time_values, time_double(new_eph_data.time[0:n_elements(new_eph_data.time)-2], tformat='YYYY-DOY/hh:mm:ss.fff')
      if where(datatypes EQ 'pos') NE -1 then append_array, eph_data_pos, new_eph_data.pos[0:n_elements(new_eph_data.time)-2,*]
      if where(datatypes EQ 'vel') NE -1 then append_array, eph_data_vel, new_eph_data.vel[0:n_elements(new_eph_data.time)-2,*]
    endif
  endfor
  
  ; sort and find uniq time_values since predicted files overlap each other
  idx=[uniq(time_values, sort(time_values))]
  time_values = time_values[idx]
  if ~undefined(eph_data_pos) then eph_data_pos = eph_data_pos[idx,*]
  if ~undefined(eph_data_vel) then eph_data_vel = eph_data_vel[idx,*]

  ; check that some data was actually loaded in
  if undefined(time_values) then begin
    dprint, dlevel = 0, 'Error loading ephemeris data - no data was loaded.'
    return
  endif else begin
    ; warn user if only partial data was loaded
    if time_values[0] GT time_double(trange[0]) OR time_values[n_elements(time_values)-1] LT time_double(trange[1]) then $
       dprint, dlevel = 1, 'Warning, not all data in the requested time frame was loaded.' 
  endelse
    
  default_colors = [2, 4, 6]
  data_att = {coord_sys:'', st_type:'', units:''}
  dl = {filenames:filenames, colors:default_colors, data_att:data_att}
  ; Populate dlimits.colors to match tplot defaults
  ; for pos and vel variables.
  ;add labels indicating whether data is pos, vel, or neither
  if where(datatypes EQ 'pos') NE -1 then begin
    pos_name =  prefix + '_' + level + 'eph_pos'
    str_element,dl,'data_att.st_type','pos',/add_replace
    str_element,dl,'data_att.coord_sys','unknown', /add_replace
    str_element,dl,'data_att.units','km', /add_replace
    str_element,dl,'labels',['x','y','z'], /add
    str_element,dl,'vname',pos_name, /add
    str_element,dl,'ysubtitle','[km]', /add
    store_data, pos_name, data={x: time_values, y: eph_data_pos}, dlimits=dl, l=0
    append_array, tplotnames, [pos_name]
    dprint, dlevel = 1, 'Tplot variable created: ' + pos_name
  endif 
  dl = {filenames:filenames, colors:default_colors, data_att:data_att}
  if where(datatypes EQ 'vel') NE -1 then begin
    vel_name =  prefix + '_' + level + 'eph_vel'
    str_element,dl,'data_att.st_type','vel',/add_replace
    str_element,dl,'data_att.coord_sys','unknown', /add_replace
    str_element,dl,'data_att.units','km/s', /add_replace
    str_element,dl,'labels',['vx','vy','vz'], /add
    str_element,dl,'vname',vel_name, /add
    str_element,dl,'ysubtitle','[km/s]', /add
    store_data, vel_name, data={x: time_values, y: eph_data_vel}, dlimits=dl, l=0
    append_array, tplotnames, [vel_name]
    dprint, dlevel = 1, 'Tplot variable created: '+ vel_name
  endif

end

; data product:
;   defatt - definitive attitude data; currently loads RAs, decl of L vector
;   defeph - definitive ephemeris data; should load position, velocity
;   predatt - predicted attitude data
;   predeph - predicted ephemeris data
pro mms_get_state_data, probe = probe, trange = trange, tplotnames = tplotnames, $
  login_info = login_info, datatypes = datatypes, level = level, $
  local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
  no_download=no_download, pred_or_def=pred_or_def

    probe = strcompress(string(probe), /rem)
    start_time = time_double(trange[0])-60*60*24.
    ;end_time = time_double(trange[1])+60*60*24.
    end_time = time_double(trange[1])
    
    ; check if end date is anything other than 00:00:00, if so
    ; add a day to the end time to ensure that all data is downloaded
    end_struct = time_struct(end_time)
    if (end_struct.hour GT 0) or (end_struct.min GT 0) then add_day = 60*60*24. else add_day = 0. 

    start_time_str = time_string(start_time, tformat='YYYY-MM-DD') 
    end_time_str = time_string(end_time+add_day, tformat= 'YYYY-MM-DD')    

    file_dir = local_data_dir + 'mms' + probe + '/state/' + level + '/' 

    idx=where(datatypes EQ 'pos' OR datatypes EQ 'vel',ephcnt)
    if ephcnt gt 0 then filetype = ['eph']
    idx=where(datatypes EQ 'spinras' OR datatypes EQ 'spindec',attcnt)
    if attcnt gt 0 then begin
      if undefined(filetype) then filetype = ['att'] else filetype = [filetype, 'att']
    endif
    
    for i = 0, n_elements(filetype)-1 do begin
        
        product = level + filetype[i]
        ;keep last iteration's file list from being appended to
        undefine, daily_names
        ;get file info from remote server
        ;if the server is contacted then a string array or empty string will be returned
        ;depending on whether files were found, if there is a connection error the
        ;neturl response code is returned instead
        if ~keyword_set(no_download) then begin
          
          if level EQ 'def' then begin
             ancillary_file_info = mms_get_ancillary_file_info(sc_id='mms'+probe, $
                   product=product, start_date=start_time_str, end_date=end_time_str) 
                   
             ; if pred_or_def flag was set check that files were found and/or the time frame
             ; covers the entire time requestd 
             if pred_or_def then begin
                switch_to_pred = 0    ; assume files found and start/end covers time span
                if ~is_array(ancillary_file_info) or ancillary_file_info[0] eq '' then begin
                   switch_to_pred = 1     ; no files found 
                endif else begin
                   remote_file_info = mms_parse_json(ancillary_file_info)
                   file_start = min(time_double(remote_file_info.startdate))
                   file_end = max(time_double(remote_file_info.enddate))
                   if file_start gt start_time or file_end lt end_time then switch_to_pred = 1   ; time range not covered            
                endelse
                
                if switch_to_pred then begin
                   dprint, 'Definitive state data not found for this time period. Looking for predicted state data'
                   level = 'pred'
                   product = level + filetype[i]
                   ancillary_file_info = mms_get_state_pred_info(sc_id='mms'+probe, $
                           product=product, start_date=start_time_str, end_date=end_time_str)  
                endif
             endif

          endif else begin
            ancillary_file_info = mms_get_state_pred_info(sc_id='mms'+probe, $
                product=product, start_date=start_time_str, end_date=end_time_str) 
          endelse
        endif
        
        if is_array(ancillary_file_info) && ancillary_file_info[0] ne '' then begin    
            remote_file_info = mms_parse_json(ancillary_file_info)    
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

        ; if no remote list was found then search locally
        endif else begin
            local_files = mms_get_local_state_files(probe='mms'+probe, level= level, filetype=filetype[i], trange=[start_time, end_time]) 
            if is_string(local_files) then begin
              append_array, daily_names, local_files
            endif else begin
              dprint, dlevel = 0, 'No MMS ' + product + ' files found for this time period.'
              return
            endelse
                   
        endelse
        
        ; figure out the type of data and read and load the data
        if filetype[i] EQ 'eph' then $
           mms_load_eph_tplot, daily_names, tplotnames = tplotnames, prefix = 'mms'+probe, level = level, $
                probe=probe, datatypes = datatypes, trange = trange 
        if filetype[i] EQ 'att' then $    
           mms_load_att_tplot, daily_names, tplotnames = tplotnames, prefix = 'mms'+probe, level = level, $
                probe=probe, datatypes = datatypes, trange = trange

     endfor

end

pro mms_load_state, trange = trange, probes = probes, datatypes = datatypes, $
    level = level, local_data_dir = local_data_dir, source = source, $
    remote_data_dir = remote_data_dir, attitude_only=attitude_only, $
    ephemeris_only = ephemeris_only, no_download=no_download, login_info=login_info, $
    tplotnames = tplotnames, pred_or_def=pred_or_def, no_color_setup = no_color_setup

    ; define probe, product, type, coordinate, and unit names
    p_names = ['1', '2', '3', '4']
    t_names = ['pos', 'vel', 'spinras', 'spindec']
    l_names = ['def', 'pred']    
    
    if undefined(trange) then begin
      dprint, dlevel = 0, 'Error loading MMS attitude data - no time range given.'
      return
    endif

    ; set up system variable for MMS if not already set    
    defsysv, '!mms', exists=exists
    if not(exists) then mms_init, no_color_setup = no_color_setup

    response_code = spd_check_internet_connection()

    ;combine these flags for now, if we're not downloading files then there is
    ;no reason to contact the server unless mms_get_local_files is unreliable
    if undefined(no_download) then no_download = !mms.no_download or !mms.no_server or (response_code ne 200)

    ; only prompt the user if they're going to download data
    if no_download eq 0 then begin
        status = mms_login_lasp(login_info=login_info)
        if status ne 1 then no_download = 1
    endif
    
    ; initialize undefined values
    if undefined(probes) then probes = p_names
    if undefined(level) then level = 'def'
    if undefined(datatypes) then datatypes = '*' ; default to definitive 
    if undefined(local_data_dir) then local_data_dir = !mms.local_data_dir
    if undefined(remote_data_dir) then remote_data_dir = !mms.remote_data_dir
    if undefined(pred_or_def) then pred_or_def=1 else pred_or_def=pred_or_def
    if not keyword_set(source) then source = !mms
    
    ; check for wild cards
    if probes[0] EQ '*' then probes = p_names
    if datatypes[0] EQ '*' then datatypes = t_names  
    if keyword_set(ephemeris_only) then datatypes = ['pos', 'vel']
    if keyword_set(attitude_only) then datatypes = ['spinras', 'spindec']
    
    ; allow users to pass probes as a list of ints
    probes = strcompress(string(probes), /rem)

    ; check for valid names
    for i = 0, n_elements(datatypes)-1 do begin
        idx = where(t_names eq datatypes[i], ncnt)
        if ncnt EQ 0 then begin
           dprint, 'mms_load_state error, found unrecognized datatypes: ' + datatypes[i]
           return
        endif
    endfor
    for i = 0, n_elements(level)-1 do begin
      idx = where(l_names eq level[i], ncnt)
      if ncnt EQ 0 then begin
        dprint, 'mms_load_state error, found unrecognized level: ' + level[i]
        return
      endif
    endfor
    for i = 0, n_elements(probes)-1 do begin
      idx = where(p_names eq probes[i], ncnt)
      if ncnt EQ 0 then begin
        dprint, 'mms_load_state error, found unrecognized probes: ' + probes[i]
        return
      endif
    endfor

    ; get state data for each probe and data type (def or pred) 
    for i = 0, n_elements(probes)-1 do begin      
       for j = 0, n_elements(level)-1 do begin
              mms_get_state_data, probe = probes[i], trange = trange, tplotnames = tplotnames, $
                   login_info = login_info, datatypes = datatypes, level = level[j], $
                   local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
                   no_download=no_download, pred_or_def=pred_or_def
       endfor
    endfor

    ; time clip the data
    if ~undefined(tplotnames) then begin
        if (tplotnames[0] ne '') then begin
            time_clip, tplotnames, time_double(trange[0]), time_double(trange[1]), replace=1, error=error
        endif
    endif
end