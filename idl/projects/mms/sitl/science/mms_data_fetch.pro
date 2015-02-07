; This is the program which will get MMS data files. It operates in three steps:
; 
; 1. It checks the SDC filename list to see what files in the query are available.
; 
; 2. It then parses the filenames to determine if they already exist locally.
; 
; 3. It then downloads the files that don't exist, and caches them
;
; Eventually I will add a feature where you can not specify a "level," and it will download the most recent,
;
; or 
;
; You can specify multiple levels and it will download all. THIS IS NOT YET DONE.

pro mms_data_fetch, local_flist, local_dir, start_date, end_date, login_flag, file_base, sc_id=sc_id, $
  instrument_id=instrument_id, mode=mode, optional_descriptor=optional_descriptor, $
  level=level,  no_update=no_update

login_flag = 0

lastpos = strlen(local_dir)

if strmid(local_dir, lastpos-1, lastpos) eq '/' then begin
  data_dir = local_dir + 'data/mms/'
endif else begin
  data_dir = local_dir + '/data/mms/'
endelse

; Get list of available file names consistent with query. This will let us check whether file exists
; This will be replaced by the actual SDC wrapper when available
;mms_get_dummy_files, filenames, status

;filenames = mms_get_science_file_names(sc_id=sc_id, $
;                                       instrument_id=instrument_id, data_rate_mode=mode, $
;                                       data_level=level, start_date=start_date, end_date=end_date)

;type_string = typename(filenames)

; Get file info (e.g. sizes)


if keyword_set(optional_descriptor) then begin
  file_data = mms_get_science_file_info(sc_id=sc_id, $
    instrument_id=instrument_id, data_rate_mode=mode, $
    data_level=level, start_date=start_date, end_date=end_date, descriptor = optional_descriptor)
endif else begin
  file_data = mms_get_science_file_info(sc_id=sc_id, $
    instrument_id=instrument_id, data_rate_mode=mode, $
    data_level=level, start_date=start_date, end_date=end_date)
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
  
;  
;  ;Old way - uses the file_names data
;  for i = 0, n_elements(filenames)-1 do begin
;    first_slash = strpos(filenames(i), '/', /reverse_search)
;    cut_filenames(i) = strmid(filenames(i), first_slash+1, strlen(filenames(i))) 
;  endfor
    
  ; Now parse the file names
  mms_parse_file_name, cut_filenames, sc_ids, inst_ids, modes, levels, $
    optional_descriptors, version_strings, start_strings, years
    
  ; Loop through and see if each file exists. If not, download it
  for i = 0, n_elements(cut_filenames)-1 do begin
    
    if strlen(optional_descriptors(i)) eq 0 then begin
      file_dir(i) = data_dir + sc_ids(i) + '/' + levels(i) + '/' + $
                    modes(i) + '/' + inst_ids(i) + '/' + years(i) + '/'
    endif else begin
      file_dir(i) = data_dir + sc_ids(i) + '/' + levels(i) + '/' + $
                    modes(i) + '/' + inst_ids(i) + '/' + optional_descriptors(i) $
                    + '/' + years(i) + '/'
    endelse
        
    full_filename = file_dir(i) + cut_filenames(i)
    local_flist(i) = full_filename
    
    ; We also need the file name without the version number for later
    first_space = strpos(cut_filenames(i), '_', /reverse_search)
    file_base(i) = strmid(cut_filenames(i), 0, first_space)
    
    ; Do a file search for the file without the version number
    search_string = file_dir(i) + file_base(i) + '*'
    search_results = file_search(search_string)    
    
    if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
      download_flags(i) = 1 ; No existing files, so download from SDC
    endif else begin
      
      ; Now we see if existing files have same or different versions
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
      if count_version gt 1 then download_flags(i) = 0
      
      ; Matching file doesn't exist - update as long as keyword 'no_update'
      ; isn't set.
      if count_version eq 0 and not(keyword_set(no_update)) then begin
        for j = 0, n_elements(search_results)-1 do begin
          file_delete, search_results(j)
        endfor
        download_flags(i) = 1
        
        ; If no_update keyword is set, make sure the file is in the local
        ; flist instead of the version not downloaded from the SDC
      endif else if count_version eq 0 and keyword_set(no_update) then begin
        maxversion = max(version_score, maxidx)
        local_flist(i) = search_results(maxidx)
        download_flags(i) = 0
      endif
    endelse
  endfor
  
  ; Now, lets download the files which need downloading
  loc_download = where(download_flags eq 1, count_download)
    
  if count_download gt 0 then begin
    download_filenames = cut_filenames(loc_download)
    download_dirs = file_dir(loc_download)
    
    download_size = total(file_sizes)/1e6
    
    str_size = 'Downloading ' + strtrim(string(count_download),2) + $
               ' files, total size = ' + string(strtrim(download_size,2)) + ' MB'
    
    print, str_size
    
    for j = 0, n_elements(download_filenames)-1 do begin
      file_mkdir, download_dirs(j)
      disp_string = 'Downloaded File ('  + strtrim(string(j+1),2) + ' of ' + $
        strtrim(string(count_download),2) + '): ' + download_filenames(j)
      status = get_mms_science_file(filename = download_filenames(j), $
                                    local_dir = download_dirs(j))
      print, disp_string
    endfor

    ; Try a while loop to allow keyboard interrupts
;    
;    j = 0
;    junk = 1
;    while j lt n_elements(download_filenames) and byte(junk) ne 27 do begin
;            file_mkdir, download_dirs(j)
;            disp_string = 'Downloaded File ('  + strtrim(string(j+1),2) + ' of ' + $
;              strtrim(string(count_download),2) + '): ' + download_filenames(j)
;            status = get_mms_science_file(filename = download_filenames(j), $
;                                          local_dir = download_dirs(j))
;            print, disp_string
;            j += 1
;            junk = get_kbrd(0)
;    endwhile
    
  endif
  
endif else begin
  local_flist = ''
  login_flag = 1
endelse


;status = get_mms_science_File(sc_id=sc_id, instrument_id = instrument_id, $
;  data_rate_mode = mode, data_level = level, $
;  start_date = start_date, end_date = end_date, $
;  local_dir = temp)

  
end