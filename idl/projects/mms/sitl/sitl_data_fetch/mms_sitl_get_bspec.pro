; This program will fetch the power spectral density from the mms E-field booms

pro mms_sitl_get_bspec, sc_id=sc_id, no_update = no_update, reload = reload


  on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'


  t = timerange(/current)
  st = time_string(t)
  start_date = strmid(st[0],0,10)
  end_date = strmatch(strmid(st[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(st[1],0,10)

  data_status = 0
  
  level = 'l1b'
  mode = 'srvy'
  
  
  
  ; See if spacecraft id is set
; See if spacecraft id is set
  if ~keyword_set(sc_id) then begin
    print, 'Spacecraft ID not set, defaulting to mms1'
    sc_id = 'mms1'
  endif else begin
    ivalid = intarr(n_elements(sc_id))
    for j = 0, n_elements(sc_id)-1 do begin
      sc_id(j)=strlowcase(sc_id(j)) ; this turns any data type to a string
      if sc_id(j) ne 'mms1' and sc_id(j) ne 'mms2' and sc_id(j) ne 'mms3' and sc_id(j) ne 'mms4' then begin
        ivalid(j) = 1
      endif
    endfor
    if min(ivalid) eq 1 then begin
      message,"Invalid spacecraft ids. Using default spacecraft mms1",/continue
      sc_id='mms1'
    endif else if max(ivalid) eq 1 then begin
      message,"Both valid and invalid entries in spacecraft id array. Neglecting invalid entries...",/continue
      print,"... using entries: ", sc_id(where(ivalid eq 0))
      sc_id=sc_id(where(ivalid eq 0))
    endif
  endelse

  data_status = intarr(n_elements(sc_id))

  
  ;----------------------------------------------------------------------------------------------------------
  ; Check for espec data
  ;----------------------------------------------------------------------------------------------------------
  
  for j = 0, n_elements(sc_id)-1 do begin
  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
      instrument_id='dsp', mode=mode, $
      level=level, optional_descriptor = 'bpsd', /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
        instrument_id='dsp', optional_descriptor = 'bpsd', mode=mode, $
        level=level, /reload
    endif else begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id(j), $
        instrument_id='dsp', optional_descriptor = 'bpsd', mode=mode, $
        level=level
    endelse
  endelse
  
  loc_fail = where(download_fail eq 1, count_fail)

  if count_fail gt 0 then begin
    loc_success = where(download_fail eq 0, count_success)
    print, 'Some of the downloads from the SDC timed out. Try again later if plot is missing data.'
    if count_success gt 0 then begin
      local_flist = local_flist(loc_success)
    endif else if count_success eq 0 then begin
      login_flag = 1
      local_flist = ''
    endif
  endif
  
  ;
  ;if n_elements(local_flist) eq 1 and strlen(local_flist(0)) eq 0 then begin
  ;  login_flag = 1
  ;endif
  
  ; Now we need to do one of two things:
  ; If the communication to the server fails, or no data on server, we need to check for local data
  ; If the communication worked, we need to open the flist
  
  ; First lets handle failure of the server
  
  
  file_flag = 0
  if login_flag eq 1 then begin
    print, 'Unable to locate files on the SDC server, checking local cache...'
    mms_check_local_cache, local_flist, file_flag, $
      mode, 'dsp', level, sc_id(j), optional_descriptor = 'bpsd'
  endif
  
  if login_flag eq 0 or file_flag eq 0 then begin
    ; We can safely verify that there is some data file to open, so lets do it
    
    ; SDC doesn't necessarily provide files in correct chronological order...
    if n_elements(local_flist) gt 1 then begin
      files_open = mms_sort_filenames_by_date(local_flist)
    endif else begin
      files_open = local_flist
    endelse
    
    ; Now we can open the files and create tplot variables
    ; First, we open the initial file
    
    cdf_struct = mms_sitl_open_dsp_acb_cdf(files_open(0))
    times = cdf_struct.x
    b1 = cdf_struct.b1
    b2 = cdf_struct.b2
    b3 = cdf_struct.b3
    freqs = cdf_struct.freq
    varnames = cdf_struct.varnames
    
    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        temp_struct = mms_sitl_open_dsp_acb_cdf(files_open(i))
        times = [times, temp_struct.x]
        b1 = [b1, temp_struct.b1]
        b2 = [b2, temp_struct.b2]
        b3 = [b3, temp_struct.b3]
      endfor
    endif
    
    sdpvarnamex = varnames(0)
    sdpvarnamey = varnames(1)
    sdpvarnamez = varnames(2)
    
    store_data, sdpvarnamex, data = {x: times, y:b1, v: freqs}
    store_data, sdpvarnamey, data = {x: times, y:b2, v: freqs}
    store_data, sdpvarnamez, data = {x: times, y:b3, v: freqs}
    
    ;
    
  endif else begin
    data_status(j) = 1
    print, 'No BPSD data available locally or at SDC or invalid query!'
  endelse
  endfor
  
  
end
