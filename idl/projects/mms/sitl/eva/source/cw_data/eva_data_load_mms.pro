FUNCTION eva_data_load_mms, state
  compile_opt idl2
  @moka_logger_com

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status, msg='filename= '
    catch, /cancel
    return, -1
  endif

  ;--- INITIALIZE ---
  cache_dir = state.PREF.cache_data_dir
  ;duration  = (str2time(state.end_time)-str2time(state.start_time))/86400.d0; duration in unit of days.
  ;eventdate = state.eventdate
  paramlist = strlowcase(state.paramlist_mms); list of parameters read from parameterSet file
  imax = n_elements(paramlist)
  sc_id = state.probelist_mms
  if (size(sc_id[0],/type) ne 7) then return, 'No'; STRING=7
  pmax = n_elements(sc_id)
  if pmax eq 1 then sc = sc_id[0] else sc = sc_id
  start_date = strmid(state.start_time,0,10)
  end_date = strmid(state.end_time,0,10)
  
  ;--- Count Number of Parameters ---
  cparam = imax*pmax
  if cparam ge 17 then begin
    rst = dialog_message('Total of '+strtrim(string(cparam),2)+' MMS parameters. Still plot?',/question,/center)
  endif else rst = 'Yes'
  if rst eq 'No' then return, 'No'
  
  ;---- LOAD ----
  for i=0,imax-1 do begin; for each requested parameter

    if (strmatch(paramlist[i],'*_afg*') or strmatch(paramlist[i],'*_dfg*')) then begin
      mms_sitl_get_dcb,  start_date, end_date, cache_dir, afg_status, dfg_status, sc_id=sc
      print,'afg_status=',afg_status
      print,'dfg_status=',dfg_status
    endif
    
    if strmatch(paramlist[i],'*_epsd*') then begin
      mms_sitl_get_espec,start_date, end_date, cache_dir, edat_status, sc_id=sc
    endif
    
    if strmatch(paramlist[i],'*_bpsd*') then begin
      mms_sitl_get_bspec,start_date, end_date, cache_dir, bdat_status, sc_id=sc;, no_update = no_update
    endif
    
    if strmatch(paramlist[i],'*_dce*') then begin
      mms_sitl_get_dce,  start_date, end_date, cache_dir, sdp_status, sc_id=sc;, coord=coord, no_update = no_update
      print,'spd_status=',sdp_status
    endif
    
  endfor
  answer = 'Yes'
  return, answer
END
