; Only works over a day boundary

pro mms_check_local_cache_level_sort, local_filename, local_dir, start_date, end_date, file_flag, $
   instrument_id, level=level, sc_id=sc_id, mode=mode, optional_descriptor=optional_descriptor

; Some preliminary safety checks

file_flag = 0

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

num_optional = n_elements(optional_descriptor)

if num_optional eq 0 then optional_descriptor = ''

if num_optional gt 1 then file_flag = 1

;num_instruments = n_elements(instrument_id)
;if num_instruments eq 0 then file_flag = 1
;
;num_modes = n_elements(mode)
;if num_modes eq 0 then file_flag = 1
;
;if num_levels eq 0 then file_flag = 1
;num_levels = n_elements(level)

; Convert start date
start_year_str = strmid(start_date, 0, 4)
start_year = fix(start_year_str)
start_mo_str = strmid(start_date, 5, 2)
start_month = fix(start_mo_str)
start_day_str = strmid(start_date, 8, 2)
start_day = fix(start_day_str)
datestring = start_year_str + start_mo_str + start_day_str
start_jul = julday(start_month, start_day, start_year, 0, 0, 0)

; Convert end date
end_year = fix(strmid(end_date, 0, 4))
end_month = fix(strmid(end_date, 5, 2))
end_day = fix(strmid(end_date, 8, 2))
end_jul = julday(end_month, end_day, end_year, 0, 0, 0)

if start_year ne end_year then file_flag = 1

; Ensure no more than a day
if end_jul-start_jul gt 86400 then file_flag = 1

lastpos = strlen(local_dir)

if strmid(local_dir, lastpos-1, lastpos) eq '/' then begin
  data_dir = local_dir + 'data/mms/'
endif else begin
  data_dir = local_dir + '/data/mms/'
endelse

; Now we need to check all possible files

possible_levels = ['l0', 'l1a','ql','sitl','l1b','l2']

possible_file_bases = strarr(n_elements(possible_levels))

if file_flag eq 0 then begin
  ; First, get the directory to search
  if strlen(optional_descriptor) eq 0 then begin
    file_dirs = data_dir + sc_id + '/' + possible_levels + '/' + $
      mode + '/' + instrument_id + '/' + start_year_str + '/'
      
    possible_file_bases = sc_id + '_' + instrument_id + '_' + $
      mode + '_' + possible_levels + '_' + datestring + '_' + '*.cdf'
  endif else begin
    file_dirs = data_dir + sc_id + '/' + possible_levels + '/' + $
      mode + '/' + instrument_id + '/' + optional_descriptor $
      + '/' + start_year_str + '/'
      
    possible_file_bases = sc_id + '_' + instrument_id + '_' + $
      mode + '_' + possible_levels + '_' + datestring + '_' + '*.cdf'

  endelse
  
  possible_names = file_dirs + possible_file_bases
  
  exist_flags = intarr(n_elements(possible_names))
  
  for i = 0, n_elements(possible_names)-1 do begin
    search_results = file_search(possible_names(i))
    if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
      exist_flags(i) = 0
    endif else begin
      exist_flags(i) = 1
    endelse
  endfor
  
  loc_exists = where(exist_flags eq 1, count_exists)
  
  if count_exists eq 0 then begin
    local_filename = ''
    file_base = ''
    file_flag = 1
    
  endif else begin
    levels_check = possible_levels(loc_exists)
    files_check = possible_names(loc_exists)

    
    ; Now find highest level
    rank = intarr(n_elements(levels_check))
    
    for i = 0, n_elements(levels_check)-1 do begin
      loc_match = where(levels_check(i) eq possible_levels, count_match)
      rank(i) = loc_match
      
    endfor
    
    max_rank = max(rank, loc_best)

    new_search = files_check(loc_best)
    
    ; Now we search through the files and select based on most recent version
    
    search_results = file_search(new_search)
    
    if n_elements(search_results) eq 1 then begin
      local_filename = search_results
      
    endif else begin
      
      version_score = lonarr(n_elements(search_results))
      for j = 0, n_elements(search_results)-1 do begin
        first_search_space = strpos(search_results(j), '_', /reverse_search)
        first_dot = strpos(search_results(j), '.', /reverse_search)
        search_versions(j) = strmid(search_results(j), first_search_space+1, first_dot-first_search_space-1)
        version1 = fix(strmid(search_results(j), first_search_space+2, 0))
        version2 = fix(strmid(search_results(j), first_search_space+4, 0))
        version3 = fix(strmid(search_results(j), first_search_space+6, 0))
        version_score(j) = 100*version1 + 10*version2 + version3
      endfor
      
      latest_version = max(version_score, loc_version_max)
      
      local_filename = search_results(loc_version_max)
      
    endelse

    
  endelse
  
endif else begin
  local_flist = ''
  file_base = ''
  file_flag = 1
endelse
  
end