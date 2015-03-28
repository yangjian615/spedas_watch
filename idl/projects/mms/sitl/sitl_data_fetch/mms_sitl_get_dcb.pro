; This will fetch DC magnetic field SITL products from the SDC for display.
; 
; sc_id may be a single string (e.g. 'mms1') or an array of strings, ['mms1','mms2','mms4']
; For now you must specify a data level. 
; TO DO: I'll think of an optimum way to get the "highest" level of data.
; 
; The DC B-field products for SITL include the Quicklook Survey data for both the AFG and DFG.
;
; Note date format is YYYY-MM-DD.

pro mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status, dfg_status, sc_id=sc_id, no_update = no_update, reload = reload

;on_error, 2
if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
  'conflicting and should never be used simultaneously.'

afg_status = 0
dfg_status = 0

level = 'ql'
mode = 'srvy'

; See if spacecraft id is set
if ~keyword_set(sc_id) then begin
  print, 'Spacecraft ID not set, defaulting to mms1'
  sc_id = 'mms1'
endif else begin
  sc_id=strlowcase(sc_id) ; this turns any data type to a string
  if sc_id ne 'mms1' and sc_id ne 'mms2' and sc_id ne 'mms3' and sc_id ne 'mms4' then begin
    message,"Invalid spacecraft id. Using default spacecraft mms1",/continue
    sc_id='mms1'
  endif
endelse

;----------------------------------------------------------------------------------------------------------
; Check for AFG data first
;----------------------------------------------------------------------------------------------------------

if keyword_set(no_update) then begin
  mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
    instrument_id='afg', mode=mode, $
    level=level, /no_update
endif else begin
  if keyword_set(reload) then begin
    mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
      instrument_id='afg', mode=mode, $
      level=level, /reload
  endif else begin
    mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
      instrument_id='afg', mode=mode, $
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
                           mode, 'afg', level, sc_id                           
endif

if login_flag eq 0 or file_flag eq 0 then begin
  ; We can safely verify that there is some data file to open, so lets do it
  
    if n_elements(local_flist) gt 1 then begin
      files_open = mms_sort_filenames_by_date(local_flist)
    endif else begin
      files_open = local_flist
    endelse
    ; Now we can open the files and create tplot variables
    ; First, we open the initial file
    
    mag_struct = mms_sitl_open_afg_cdf(files_open(0))
    times = mag_struct.x
    b_field = mag_struct.y
    varname = mag_struct.varname
    
    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        temp_struct = mms_sitl_open_afg_cdf(files_open(i))
        times = [times, temp_struct.x]
        b_field = [b_field, temp_struct.y]
      endfor
    endif
    
    afgvarname = varname
    store_data, varname, data = {x: times, y:b_field}    
    
  ;
  
endif else begin
  afg_status = 1
  print, 'No AFG data available locally or at SDC or invalid query!'
endelse

;----------------------------------------------------------------------------------------------------------
; Check for DFG data next
;----------------------------------------------------------------------------------------------------------

if keyword_set(no_update) then begin
  mms_data_fetch, local_flist2, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
    instrument_id='dfg', mode=mode, $
    level=level, /no_update
endif else begin
  if keyword_set(reload) then begin
    mms_data_fetch, local_flist2, cache_dir, start_date, end_date, login_flag,  sc_id=sc_id, $
      instrument_id='dfg', mode=mode, $
      level=level, /reload
  endif else begin
    mms_data_fetch, local_flist2, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
      instrument_id='dfg', mode=mode, $
      level=level
  endelse
endelse
  
;  if n_elements(local_flist2) eq 1 and strlen(local_flist2(0)) eq 0 then begin
;    login_flag = 1
;  endif

  
; Now we need to do one of two things:
; If the communication to the server fails, we need to check for local data
; If the communication worked, we need to open the flist

; First lets handle failure of the server


file_flag = 0
if login_flag eq 1 then begin
  print, 'Unable to locate dfg files on the SDC server, checking local cache...'
  mms_check_local_cache, local_flist2, cache_dir, start_date, end_date, file_flag, $
    mode, 'dfg', level, sc_id
endif

if login_flag eq 0 or file_flag eq 0 then begin
  ; We can safely verify that there is some data file to open, so lets do it
  
  ; FOR NOW - SDC is not applying a version filter to the HTTP services, so I'll need to clear out the version string.
  ; Get cut_filenames. DELETE THIS SECTION ONCE VERSION FILTERING GOES UP!!!!!!!!
  
      files_open = local_flist2
    
    ; Now we can open the files and create tplot variables
    ; First, we open the initial file
    
    mag_struct = mms_sitl_open_dfg_cdf(files_open(0))
    times = mag_struct.x
    b_field = mag_struct.y
    varname = mag_struct.varname

    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        temp_struct = mms_sitl_open_dfg_cdf(files_open(i))
        times = [times, temp_struct.x]
        b_field = [b_field, temp_struct.y]
      endfor
    endif
    
    ; Create tplot variable
    dfgvarname = varname
    store_data, dfgvarname, data = {x: times, y:b_field}    
  
  
endif else begin
  dfg_status = 1
  print, 'No DFG data available locally or at SDC or invalid query!'
endelse



end
                        