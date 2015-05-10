; PROCEDURE: MMS_DATA_FETCH
;
; PURPOSE: Execute an SDC HTTP query with local caching possibilities.
;
; INPUT:
;   local_flist      - REQUIRED. Name for an array of strings. This will have
;                    - names of all of the files consistent with the query.
;                                           
;   start_date       - REQUIRED. (String) Start date in the format for SDC 
;                      HTTP queries (YYYY-MM-DD).
;                      
;   end_date         - REQUIRED. (String) End date in the format for SDC
;                      HTTP queries (YYYY-MM-DD). If the same as start_date,
;                      procedure will only query for that day.
;                      
;   login_flag       - REQUIRED. (Integer) Flag which determines if connection
;                      to SDC was successful. If connection fails, will need to
;                      call "mms_check_local_cache" to see if data already exists
;                      locally.
;                      
;   download_fail    - REQUIRED. (Integer) Flag which determines whether each download
;                      succeeded. It is an integer array that corresponds to local_flist.
;                      Flag is 1 if download fails, flag is 0 is download is successful.
;                      So if you define "success = where(download_fails eq 0, count),"
;                      then files that successfully downloaded are local_flist(success).
;                      This flag array is for the rare cases where the file exists on the
;                      SDC, but for some reason the download fails (e.g. connection times out).
;                      
;   
; KEYWORDS:
;
;   sc_id            - OPTIONAL. (String) Array of strings containing spacecraft
;                      ids for http query (e.g. 'mms1' or ['mms1', 'mms3']. 
;                      If not used, query defaults to all four spacecraft.
;
;   instrument_id    - OPTIONAL. (String) Instrument ID for http query (see CDF
;                      format guide for possible values). If not set, query defaults
;                      to all instruments (NOT RECOMMENDED).
;
;   mode             - OPTIONAL. (String) Data collection mode for http query 
;                      (e.g. 'slow','srvy','fast','brst'). If not set, query defaults
;                      to all modes (NOT RECOMMENDED).
;
;   level            - OPTIONAL. (String) Data level for http query (e.g. 'l0', 'l1a',
;                      'l1b','ql','sitl','l2'). If not set, query defaults to 'l2.'
;                      
;   optional_descriptor
;                    - OPTIONAL. (String) Descriptor for data product (e.g. 'bpsd' for
;                      the instrument 'dsp' provides search coil data). If not set,
;                      all descriptors are queried if they exist (e.g. 'afg' does not
;                      have an optional descriptor).
;                      
;   no_update        - OPTIONAL. Set if you don't wish to replace earlier file versions
;                      with the latest version. If not set, earlier versions are deleted
;                      and replaced.
;                      
;   reload           - OPTIONAL. Set if you wish to download all files in query, regardless
;                      of whether file exists locally. Useful if obtaining recent data files
;                      that may not have been full when you last cached them.
;                      
;                      NOTE: no_update and reload should NEVER be simultaneously set. Will
;                      give an error if it happens.
;
;
; HISTORY:
; 
; 2015-03-17, FDW, wrapper for SDC routine get_mms_science_file that includes local caching.
; LASP, University of Colorado

; MODIFICATION HISTORY:
;
;-

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-05-08 12:14:47 -0700 (Fri, 08 May 2015) $
;  $LastChangedRevision: 17531 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_data_fetch/mms_data_fetch.pro $


pro mms_data_fetch, local_flist, start_date, end_date, login_flag, download_fail, sc_id=sc_id, $
  instrument_id=instrument_id, mode=mode, level=level, optional_descriptor=optional_descriptor, $
  no_update=no_update, reload=reload

mms_init

login_flag = 0

on_error, 2

if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
  'conflicting and should never be used simultaneously.'
;
;lastpos = strlen(local_dir)
;if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;  data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;endif else begin
;  data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;endelse

; Due to a problem the SDC downloader has with '~', we need to unwrap the directory
temp_dir = !MMS.LOCAL_DATA_DIR
spawnstring = 'echo ' + temp_dir
spawn, spawnstring, data_dir

;HACK - delete following line
;
;data_dir = local_dir + path_sep() + 'mms' + path_sep()

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
  download_fail=0
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
      file_dir(i) = filepath('', root_dir=data_dir, $
         subdirectory = [sc_ids(i), levels(i), modes(i),inst_ids(i),years(i)])
      
;      file_dir(i) = data_dir + sc_ids(i) + '/' + levels(i) + '/' + $
;                    modes(i) + '/' + inst_ids(i) + '/' + years(i) + '/'
    endif else begin
      file_dir(i) = filepath('', root_dir=data_dir, $
        subdirectory = [sc_ids(i), levels(i), modes(i),inst_ids(i), optional_descriptors(i), years(i)])
      
;      file_dir(i) = data_dir + sc_ids(i) + '/' + levels(i) + '/' + $
;                    modes(i) + '/' + inst_ids(i) + '/' + optional_descriptors(i) $
;                    + '/' + years(i) + '/'
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
      
      loc_version = where(search_versions eq version_strings(i), count_version)
      
      ; Matching file exists
      
      if count_version ge 1 then begin 
        download_flags(i) = 0
        local_file_info = file_info(search_results(loc_version(0)))
        local_file_size = local_file_info.size
        
        if local_file_size lt file_sizes(i) and ~keyword_set(no_update) then begin
          outstring = 'The following local file is smaller than file at SDC, re-downloading: ' + $
                      cut_filenames(i)
          print, outstring
          download_flags(i) = 1
        endif
        
        if keyword_set(reload) then begin
          download_flags(i) = 1
        endif
        
      endif
      
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
  
  download_fail = replicate(0l, n_elements(local_flist))

  
  if count_download gt 0 then begin
    download_filenames = cut_filenames(loc_download)
    download_dirs = file_dir(loc_download)
    download_errors = intarr(count_download)
    
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
      download_errors(j) = status*(-1)
      print, disp_string
    endfor
    
    ; Need to find a handle on how to fix download fails/SDC timeouts
    downloads = download_dirs + download_filenames
    fail_loc = where(download_errors eq 1, count_fail)
        
    if count_fail gt 0 then begin
      failed_downloads = downloads(fail_loc)
      
      for k = 0l, n_elements(local_flist)-1 do begin
        ; Compare filename with failed downloads
        loc_bad = where(failed_downloads eq local_flist(k), count_bad)
        if count_bad gt 0 then begin
          download_fail(k) = 1
        endif
      endfor
    endif
    
  endif
  
endif else begin
  local_flist = ''
  login_flag = 1
  download_fail=0
endelse


;status = get_mms_science_File(sc_id=sc_id, instrument_id = instrument_id, $
;  data_rate_mode = mode, data_level = level, $
;  start_date = start_date, end_date = end_date, $
;  local_dir = temp)

  
end