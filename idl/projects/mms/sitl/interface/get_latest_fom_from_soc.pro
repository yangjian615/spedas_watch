pro get_latest_fom_from_soc, local_dir, fom_file, error_flag, error_message

  ; For now, lets ignore start and end time, and just grab the most recent file
  
  error_flag = 0
  pw_message = 'ERROR: Either no FOM structure exists for the time specified, or login failed.'
  
  current_leap = 35
  
  status = get_mms_abs_selections(local_dir = local_dir)
  
  if status eq 0 then begin
  
    ; Find most recent file by finding largest time_tag
    search_string = local_dir + 'abs_selections_*.sav'
    flist = file_search(search_string)
    dir_length = strlen(local_dir)
    
    fjul = dblarr(n_elements(flist))
    
    for i = 0, n_elements(flist)-1 do begin
      fyear = fix(strmid(flist(i), dir_length+15, 4))
      fmonth = fix(strmid(flist(i), dir_length+20, 2))
      fday = fix(strmid(flist(i), dir_length+23, 2))
      fhour = fix(strmid(flist(i), dir_length+26, 2))
      fmin = fix(strmid(flist(i), dir_length+29, 2))
      fsec = fix(strmid(flist(i), dir_length+32, 2))
      fjul(i) = julday(fmonth, fday, fyear, fhour, fmin, fsec)
    endfor
    
    fjulmax = max(fjul, maxidx)
    
    fom_file = flist(maxidx)
  endif else begin
  
    ; Error message for non-existant file
    error_flag = 1
    fom_file = ''
  endelse

end