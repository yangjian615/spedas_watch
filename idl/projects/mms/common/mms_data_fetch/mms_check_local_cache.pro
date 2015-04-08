; This program will check the local cache to see if files have been downloaded.
; If they have - it will generate a "file list" of files consistent with the search.
; If not - it will produce an error flag which signifies no data is available.
;
; Lets keep this simple: assume one s/c, one instrument_id, one mode, one level, 
; and one, if any, optional descriptor

pro mms_check_local_cache, local_flist, local_dir, start_date, end_date, file_flag, $
    mode, instrument_id, level, sc_id, optional_descriptor=optional_descriptor
  
file_flag = 0  

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
start_month = fix(strmid(start_date, 5, 2))
start_day = fix(strmid(start_date, 8, 2))
start_jul = julday(start_month, start_day, start_year, 0, 0, 0)

; Convert end date
end_year = fix(strmid(end_date, 0, 4))
end_month = fix(strmid(end_date, 5, 2))
end_day = fix(strmid(end_date, 8, 2))
end_jul = julday(end_month, end_day, end_year, 0, 0, 0)

if start_year ne end_year then file_flag = 1

; Check only over a day boundary
if end_jul-start_jul gt 86400 then file_flag = 1

lastpos = strlen(local_dir)

if strmid(local_dir, lastpos-1, lastpos) eq '/' then begin
  data_dir = local_dir + 'data/mms/'
endif else begin
  data_dir = local_dir + '/data/mms/'
endelse

if file_flag eq 0 then begin
      ; First, get the directory to search
  if strlen(optional_descriptor) eq 0 then begin
    file_dir = data_dir + sc_id + '/' + level + '/' + $
      mode + '/' + instrument_id + '/' + start_year_str + '/'
  endif else begin
    file_dir = data_dir + sc_id + '/' + level + '/' + $
      mode + '/' + instrument_id + '/' + optional_descriptor $
      + '/' + start_year_str + '/'
    endelse
    
  search_string = file_dir + '*.cdf'
  search_results = file_search(search_string)
    
  if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
    local_flist = ''
    file_base = ''
    file_flag = 1
  endif else begin
    ; Parse search results to extract times
    
    cut_filenames = strarr(n_elements(search_results))
    file_bases = cut_filenames
    for i = 0, n_elements(search_results)-1 do begin
      slash = strpos(search_results(i), '/', /reverse_search)
      cut_filenames(i) = strmid(search_results(i), slash+1, strlen(search_results(i))-slash-1)
      first_space = strpos(cut_filenames(i), '_', /reverse_search)
      file_bases(i) = strmid(cut_filenames(i), 0, first_space)
    endfor
    
    mms_parse_file_name, cut_filenames, fsc_ids, finst_ids, fmodes, flevels, $
                         foptional_descriptors, fversion_strings, fstart_strings, fyears   
                                            
    ; Now parse the start string
    mms_parse_start_string, fstart_strings, fmonths, fdays, fyears, fhours, fminutes, fseconds
    
    ; Convert to julian days
    fstart_juls = julday(fmonths, fdays, fyears, fhours, fminutes, fseconds)
    
    ; Identify files within start and end time
    loc_match = where(fstart_juls ge start_jul and fstart_juls le end_jul, count_match)
        
    if count_match gt 0 then begin
      local_flist = search_results(loc_match)
      match_cuts = cut_filenames(loc_match)
      file_base = file_bases(loc_match)      
      
    endif else begin
      local_flist = ''
      file_base = ''
      file_flag = 1
    endelse
    
  endelse
    
  
endif else begin
  local_flist = ''
  file_base = ''
  file_flag = 1
endelse






end