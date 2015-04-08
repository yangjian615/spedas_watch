; This is a program to fetch a SINGLE mms data file.
; While mms_data_fetch is good for GENERAL use, this file 
; will be useful if we want to make data_level more flexible.
; 
; The program will handle the level in the following way:
; -If not specified, we will search for the file with the highest level.
; -If specified, we will grab that files' level.
; 
; We will also do 
; - One spacecraft at a time (defaults to mms1).
; - One instrument at a time (required input).
; - One data rate at a time (defaults to 'fast')
; - Optional descriptors are still optional (we'll have to be careful)
; - Start and end date must not be more than a day's boundary (error)
; 

pro mms_get_single_data_file, local_filename, local_dir, start_date, end_date, login_flag, instrument_id, sc_id=sc_id, $
  mode=mode, optional_descriptor=optional_descriptor, $
  level=level,  no_update=no_update


login_flag = 0
download_flag = 0

lastpos = strlen(local_dir)

if strmid(local_dir, lastpos-1, lastpos) eq '/' then begin
  data_dir = local_dir + 'data/mms/'
endif else begin
  data_dir = local_dir + '/data/mms/'
endelse


; See if spacecraft id is set
if ~keyword_set(sc_id) then begin
  print, 'Spacecraft ID not set, defaulting to mms1.'
  sc_id = 'mms1'
endif else begin
  sc_id=strlowcase(sc_id) ; this turns any data type to a string
  if sc_id ne 'mms1' and sc_id ne 'mms2' and sc_id ne 'mms3' and sc_id ne 'mms4' then begin
    message,"Invalid spacecraft id. Using default spacecraft mms1.",/continue
    sc_id='mms1'
  endif
endelse

if ~keyword_set(mode) then begin
  print, 'Data mode not set, defaulting to fast survey.'
  mode = 'fast'
endif else begin
  mode=strlowcase(mode) ; this turns any data type to a string
  if mode ne 'fast' and mode ne 'brst' and mode ne 'slow' and mode ne 'srvy' then begin
    message,"Invalid data mode. Using default mode fast survey.",/continue
    mode='fast'
  endif
endelse

; Now we can query the database and see if we can find data at the appropriate level
; start with level not set

if ~keyword_set(level) then begin
  ; First thing we're doing - if no level keyword is set, just grab everything 
  
  if keyword_set(optional_descriptor) then begin
    file_data = mms_get_science_file_info(sc_id=sc_id, $
      instrument_id=instrument_id, data_rate_mode=mode, $
      start_date=start_date, end_date=end_date, descriptor = optional_descriptor)
  endif else begin
    file_data = mms_get_science_file_info(sc_id=sc_id, $
      instrument_id=instrument_id, data_rate_mode=mode, $
      start_date=start_date, end_date=end_date)
  endelse
  type_string = typename(file_data)

  if type_string ne 'STRING' then begin
    login_flag = 1
    local_flist = ''
  endif else if n_elements(file_data) gt 0 and file_data(0) ne '' then begin

    cut_filenames = strarr(n_elements(file_data)/2) ; Filename without the directory
    file_sizes = lonarr(n_elements(file_data)/2) ; Size of each file in bytes
    download_flags = intarr(n_elements(file_data)/2) ; Determines whether to download file
    file_dir = strarr(n_elements(file_data)/2) ; Directory in local cache for file
    file_base = strarr(n_elements(file_data)/2) ; Filename without directory or version number
    local_flist = strarr(n_elements(file_data)/2) ; List of local filenames consistent with query

    ; New way - obtains both file names and file sizes

    j = 0
    for i = 0, n_elements(file_data)-2, 2 do begin
      name_dump = file_data(i)
      size_dump = file_data(i+1)

      colon1 = strpos(name_dump, ':')
      cut_filenames(j) = strmid(name_dump, colon1+3, strlen(name_dump)-colon1-4)

      colon1 = strpos(size_dump, ':')
      file_sizes(j) = long(strmid(size_dump, colon1+2, strlen(size_dump)-colon1-3))
      j += 1
      ;    print, i, j
    endfor

    ; Now we have cut filenames - parse the filename and find the highest level.
    mms_parse_file_name, cut_filenames, sc_ids, inst_ids, modes, levels, $
      optional_descriptors, version_strings, start_strings, years
      
    ; Determine highest level by ranking levels by download priority
    ; L2 is the highest, L0 is the lowest.
    
    rank = intarr(n_elements(levels))

    possible_levels = ['l0', 'l1a','ql','sitl','l1b','l2']

    for i = 0, n_elements(levels)-1 do begin
      loc_match = where(levels(i) eq possible_levels, count_match)
      rank(i) = loc_match
    endfor

    max_rank = max(rank, loc_best)
    
    ; Now we can identify the best file, we can try to download it
    
    best_file_cut = cut_filenames(loc_best)
    
    if strlen(optional_descriptors(loc_best)) eq 0 then begin
      file_dir = data_dir + sc_ids(loc_best) + '/' + levels(loc_best) + '/' + $
        modes(loc_best) + '/' + inst_ids(loc_best) + '/' + years(loc_best) + '/'
    endif else begin
      file_dir = data_dir + sc_ids(loc_best) + '/' + levels(loc_best) + '/' + $
        modes(loc_best) + '/' + inst_ids(loc_best) + '/' + optional_descriptors(loc_best) $
        + '/' + years(loc_best) + '/'
    endelse

    full_filename = file_dir + cut_filenames(loc_best)
    
    first_space = strpos(cut_filenames(loc_best), '_', /reverse_search)
    file_base = strmid(cut_filenames(loc_best), 0, first_space)

    ; Do a file search for the file without the version number
    search_string = file_dir + file_base + '*'
    search_results = file_search(search_string)
    
    if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
      download_flag = 1 ; No existing files, so download from SDC
      
    endif else begin
      ; Here we check the local file and see what version it is and whether to replace
      search_versions = strarr(n_elements(search_results))
      version_score = intarr(n_elements(search_results))
      
      for j = 0, n_elements(search_results)-1 do begin
        first_search_space = strpos(search_results(j), '_', /reverse_search)
        first_dot = strpos(search_results(j), '.', /reverse_search)
        search_versions(j) = strmid(search_results(j), first_search_space+1, first_dot-first_search_space-1)
        version1 = fix(strmid(search_results(j), first_search_space+2, 0))
        version2 = fix(strmid(search_results(j), first_search_space+4, 0))
        version3 = fix(strmid(search_results(j), first_search_space+6, 0))
        version_score(j) = 100*version1 + 10*version2 + version3
      endfor
      
      loc_version = where(search_versions eq version_strings, count_version)
      
      
      ; Matching file exists
      if count_version ge 1 then begin 
        download_flag = 0
        local_filename = search_results
      endif
      
      ; Matching file doesn't exist - update as long as keyword 'no_update'
      ; isn't set.
      if count_version eq 0 and not(keyword_set(no_update)) then begin
        for j = 0, n_elements(search_results)-1 do begin
          file_delete, search_results(j)
        endfor
        download_flag = 1
        
        ; If no_update keyword is set, make sure the file is in the local
        ; flist instead of the version not downloaded from the SDC
      endif else if count_version eq 0 and keyword_set(no_update) then begin
        maxversion = max(version_score, maxidx)
        local_filename = search_results(maxidx)
        download_flag = 0
      endif
      
    endelse
    
    ; Now download the file
    if download_flag eq 1 then begin
      download_filename = cut_filenames(loc_best)
      download_dir = file_dir
        
      download_size = total(file_sizes(loc_best))/1e6

      str_size = 'Downloading ' + strtrim(string(1),2) + $
          ' files, total size = ' + string(strtrim(download_size,2)) + ' MB'

      print, str_size
        
      file_mkdir, download_dir
      disp_string = 'Downloaded File ('  + strtrim(string(1),2) + ' of ' + $
          strtrim(string(1),2) + '): ' + download_filename
      status = get_mms_science_file(filename = download_filename, $
          local_dir = download_dir)
      print, disp_string
      
      local_filename = download_filename
     endif
endif

endif

stop

if keyword_set(level) then begin
  ; Now we do the download for a set level.
  if keyword_set(optional_descriptor) then begin
    file_data = mms_get_science_file_info(sc_id=sc_id, $
    instrument_id=instrument_id, data_rate_mode=mode, $
    start_date=start_date, end_date=end_date, descriptor = optional_descriptor)
  endif else begin
    file_data = mms_get_science_file_info(sc_id=sc_id, $
    instrument_id=instrument_id, data_rate_mode=mode, $
    start_date=start_date, end_date=end_date)
  endelse

  type_string = typename(file_data)

  if type_string ne 'STRING' then begin
    login_flag = 1
    local_flist = ''
  endif else if n_elements(file_data) gt 0 and file_data(0) ne '' then begin
    cut_filenames = strarr(n_elements(file_data)/2) ; Filename without the directory
    file_sizes = lonarr(n_elements(file_data)/2) ; Size of each file in bytes
    download_flags = intarr(n_elements(file_data)/2) ; Determines whether to download file
    file_dir = strarr(n_elements(file_data)/2) ; Directory in local cache for file
    file_base = strarr(n_elements(file_data)/2) ; Filename without directory or version number
    local_flist = strarr(n_elements(file_data)/2) ; List of local filenames consistent with query

    ; New way - obtains both file names and file sizes

    j = 0
    for i = 0, n_elements(file_data)-2, 2 do begin
      name_dump = file_data(i)
      size_dump = file_data(i+1)

      colon1 = strpos(name_dump, ':')
      cut_filenames(j) = strmid(name_dump, colon1+3, strlen(name_dump)-colon1-4)

      colon1 = strpos(size_dump, ':')
      file_sizes(j) = long(strmid(size_dump, colon1+2, strlen(size_dump)-colon1-3))
      j += 1
      ;    print, i, j
    endfor

    ; Now we have cut filenames - parse the filename and find the highest level.
    mms_parse_file_name, cut_filenames(0), sc_ids, inst_ids, modes, levels, $
      optional_descriptors, version_strings, start_strings, years

    if strlen(optional_descriptors) eq 0 then begin
      file_dir = data_dir + sc_ids + '/' + levels + '/' + $
        modes + '/' + inst_ids + '/' + years + '/'
    endif else begin
      file_dir = data_dir + sc_ids + '/' + levels + '/' + $
        modes+ '/' + inst_ids + '/' + optional_descriptors $
        + '/' + years + '/'
    endelse
    
    full_filename = file_dir + cut_filenames(0)

    first_space = strpos(cut_filenames(0), '_', /reverse_search)
    file_base = strmid(cut_filenames(0), 0, first_space)

    ; Do a file search for the file without the version number
    search_string = file_dir + file_base + '*'
    search_results = file_search(search_string)

    if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
      download_flag = 1 ; No existing files, so download from SDC

    endif else begin
      ; Here we check the local file and see what version it is and whether to replace
      search_versions = strarr(n_elements(search_results))
      version_score = intarr(n_elements(search_results))

      for j = 0, n_elements(search_results)-1 do begin
        first_search_space = strpos(search_results(j), '_', /reverse_search)
        first_dot = strpos(search_results(j), '.', /reverse_search)
        search_versions(j) = strmid(search_results(j), first_search_space+1, first_dot-first_search_space-1)
        version1 = fix(strmid(search_results(j), first_search_space+2, 0))
        version2 = fix(strmid(search_results(j), first_search_space+4, 0))
        version3 = fix(strmid(search_results(j), first_search_space+6, 0))
        version_score(j) = 100*version1 + 10*version2 + version3
      endfor

      loc_version = where(search_versions eq version_strings, count_version)


      ; Matching file exists
      if count_version ge 1 then begin
        download_flag = 0
        local_filename = search_results
      endif

      ; Matching file doesn't exist - update as long as keyword 'no_update'
      ; isn't set.
      if count_version eq 0 and not(keyword_set(no_update)) then begin
        for j = 0, n_elements(search_results)-1 do begin
          file_delete, search_results(j)
        endfor
        download_flag = 1

        ; If no_update keyword is set, make sure the file is in the local
        ; flist instead of the version not downloaded from the SDC
      endif else if count_version eq 0 and keyword_set(no_update) then begin
        maxversion = max(version_score, maxidx)
        local_filename = search_results(maxidx)
        download_flag = 0
      endif

    endelse
    
    ; Now download the file
    if download_flag eq 1 then begin
      download_filename = cut_filenames(0)
      download_dir = file_dir

      download_size = total(file_sizes(0))/1e6

      str_size = 'Downloading ' + strtrim(string(1),2) + $
        ' files, total size = ' + string(strtrim(download_size,2)) + ' MB'

      print, str_size

      file_mkdir, download_dir
      disp_string = 'Downloaded File ('  + strtrim(string(1),2) + ' of ' + $
        strtrim(string(1),2) + '): ' + download_filename
      status = get_mms_science_file(filename = download_filename, $
        local_dir = download_dir)
      print, disp_string

      local_filename = download_filename
    endif

  endif
  
endif

end