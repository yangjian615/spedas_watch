; PROCEDURE: mms_sitl_get_dcb
;
; PURPOSE: Fetch DC magnetic field SITL products from the SDC for display using tplot.
;          The routine creates tplot variables based on the names in the mms CDF files.
;          The routine also provides predicted ephemeris data in tplot form.
;          Data files are cached locally in !mms.local_data_dir.
;
; INPUT:
;   afg_status       - Variable name for afg status flag. Returns 1 if 
;                      there is an error in retrieving AFG data. 0 if 
;                      data either downloaded successfully or available
;                      locally.
;                      
;   dfg_status       - Variable name for dfg status flag. Returns 1 if 
;                      there is an error in retrieving AFG data. 0 if 
;                      data either downloaded successfully or available
;                      locally.
; KEYWORDS:
;
;   sc_id            - OPTIONAL. (String) Array of strings containing spacecraft
;                      ids for http query (e.g. 'mms1' or ['mms1', 'mms3']).
;                      If not used, or set to invalid sc_id, the routine defaults'
;                      to 'mms1'
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
; INITIAL VERSION: FDW 2015-04-14
; MODIFICATION HISTORY:
;
; LASP, University of Colorado
;
;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-04-27 11:47:59 -0700 (Mon, 27 Apr 2015) $
;  $LastChangedRevision: 17434 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_dcb.pro $





pro mms_sitl_get_dcb, afg_status, dfg_status, sc_id=sc_id, no_update = no_update, reload = reload

t = timerange(/current)
st = time_string(t)
start_date = strmid(st[0],0,10)
end_date = strmatch(strmid(st[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(st[1],0,10)

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

afg_status = intarr(n_elements(sc_id))
dfg_status = intarr(n_elements(sc_id))


;----------------------------------------------------------------------------------------------------------
; Check for AFG data first
;----------------------------------------------------------------------------------------------------------

for j = 0, n_elements(sc_id)-1 do begin

if keyword_set(no_update) then begin
  mms_data_fetch, local_flist, start_date, end_date, login_flag, download_fail, sc_id=sc_id(j), $
    instrument_id='afg', mode=mode, $
    level=level, /no_update
endif else begin
  if keyword_set(reload) then begin
    mms_data_fetch, local_flist, start_date, end_date, login_flag, download_fail, sc_id=sc_id(j), $
      instrument_id='afg', mode=mode, $
      level=level, /reload
  endif else begin
    mms_data_fetch, local_flist, start_date, end_date, login_flag, download_fail, sc_id=sc_id(j), $
      instrument_id='afg', mode=mode, $
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
    mms_check_local_cache, local_flist, start_date, end_date, file_flag, $
                           mode, 'afg', level, sc_id(j)                           
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
    etimes = mag_struct.ephemx
    pos_vect = mag_struct.ephemy
    evarname = mag_struct.ephem_varname
    
    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        temp_struct = mms_sitl_open_afg_cdf(files_open(i))
        times = [times, temp_struct.x]
        etimes = [times, temp_struct.ephemx]
        pos_vect = [pos_vect, temp_struct.ephemy]
        b_field = [b_field, temp_struct.y]
      endfor
    endif
    
    store_data, varname, data = {x: times, y:b_field}    
    store_data, evarname, data = {x: etimes, y:pos_vect}
    
  ;
  
endif else begin
  afg_status(j) = 1
  print, 'No AFG data available locally or at SDC or invalid query!'
endelse

;----------------------------------------------------------------------------------------------------------
; Check for DFG data next
;----------------------------------------------------------------------------------------------------------

if keyword_set(no_update) then begin
  mms_data_fetch, local_flist2, start_date, end_date, login_flag, download_fail, sc_id=sc_id(j), $
    instrument_id='dfg', mode=mode, $
    level=level, /no_update
endif else begin
  if keyword_set(reload) then begin
    mms_data_fetch, local_flist2, start_date, end_date, login_flag, download_fail,  sc_id=sc_id(j), $
      instrument_id='dfg', mode=mode, $
      level=level, /reload
  endif else begin
    mms_data_fetch, local_flist2, start_date, end_date, login_flag, download_fail, sc_id=sc_id(j), $
      instrument_id='dfg', mode=mode, $
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
  mms_check_local_cache, local_flist2, start_date, end_date, file_flag, $
    mode, 'dfg', level, sc_id(j)
endif

if login_flag eq 0 or file_flag eq 0 then begin
  ; We can safely verify that there is some data file to open, so lets do it
  
  ; FOR NOW - SDC is not applying a version filter to the HTTP services, so I'll need to clear out the version string.
  ; Get cut_filenames. DELETE THIS SECTION ONCE VERSION FILTERING GOES UP!!!!!!!!
        
    if n_elements(local_flist2) gt 1 then begin
      files_open = mms_sort_filenames_by_date(local_flist2)
    endif else begin
      files_open = local_flist2
    endelse

    
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
  dfg_status(j) = 1
  print, 'No DFG data available locally or at SDC or invalid query!'
endelse

endfor

end
                        