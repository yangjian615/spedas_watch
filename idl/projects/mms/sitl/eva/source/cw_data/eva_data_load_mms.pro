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
  duration  = (str2time(state.end_time)-str2time(state.start_time))/86400.d0; duration in unit of days.
  eventdate = state.eventdate
  paramlist = strlowcase(state.paramlist_mms); list of parameters read from parameterSet file
  sc_id = state.probelist_mms
  if (size(sc_id[0],/type) ne 7) then return, 'No'; STRING=7

  ;--- Count Number of Parameters ---
  cparam = n_elements(paramlist)*n_elements(sc_id)
  if cparam ge 17 then begin
    rst = dialog_message('Total of '+strtrim(string(cparam),2)+' MMS parameters. Still plot?',/question,/center)
  endif else rst = 'Yes'
  if rst eq 'No' then return, 'No'



  if n_elements(sc_id) eq 1 then sc = sc_id[0] else sc = sc_id
  mms_sitl_get_dcb,  state.start_time, state.end_time, cache_dir, afg_status, dfg_status, sc_id=sc
  mms_sitl_get_espec,state.start_time, state.end_time, cache_dir, edat_status, sc_id=sc
  mms_sitl_get_bspec,state.start_time, state.end_time, cache_dir, bdat_status, sc_id=sc;, no_update = no_update


  answer = 'Yes'
  if afg_status then answer = 'No'
  if dfg_status then answer = 'No'
  if edat_status then answer = 'No'
  if bdat_status then answer = 'No'

  return, answer
END
