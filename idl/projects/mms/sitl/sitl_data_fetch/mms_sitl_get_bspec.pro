; This program will fetch the power spectral density from the mms E-field booms

pro mms_sitl_get_bspec, start_date, end_date, cache_dir, data_status, sc_id=sc_id, no_update = no_update, reload = reload


  on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'

  data_status = 0
  
  level = 'l1b'
  mode = 'srvy'
  
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
  
  ;----------------------------------------------------------------------------------------------------------
  ; Check for espec data
  ;----------------------------------------------------------------------------------------------------------
  
  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
      instrument_id='dsp', mode=mode, $
      level=level, optional_descriptor = 'bpsd', /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
        instrument_id='dsp', optional_descriptor = 'bpsd', mode=mode, $
        level=level, /reload
    endif else begin
      mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
        instrument_id='dsp', optional_descriptor = 'bpsd', mode=mode, $
        level=level
    endelse
  endelse
  
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
    mms_check_local_cache, local_flist, cache_dir, start_date, end_date, file_flag, $
      mode, 'dsp', level, sc_id, optional_descriptor = 'bpsd'
  endif
  
  if login_flag eq 0 or file_flag eq 0 then begin
    ; We can safely verify that there is some data file to open, so lets do it
    
    
    files_open = local_flist
    
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
    data_status = 1
    print, 'No BPSD data available locally or at SDC or invalid query!'
  endelse
  
  
  
end
