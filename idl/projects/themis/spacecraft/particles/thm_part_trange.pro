
;+
;Procedure:
;  thm_part_trange
;
;Purpose:
;  Store/retrive the last requested time range for a particle data type. 
;  This routine should only be called internally by the particle load routines.
;
;Calling Sequence:
;  thm_part_set_trange, probe, datatype, trange [,sst_cal=sst_cal]
;
;Input:
;  probe: (string) scalar containing probe designation
;  datatype: (string) scalar containing particle data type
;  set: (double) two element array specifying a time range
;  sst_cal: (bool/int) flag to use time range for data loaded with thm_load_sst2  
;
;Output:
;  get: (double) two element array containing the last loaded time range
;       for the specified data, [0,0] if no data has been loaded
;
;See Also:
;  thm_part_check_trange
;  thm_load_esa_pkt
;  thm_load_sst
;  thm_load_sst2
;
;Notes:
;  Get operation performed before set. 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-24 18:01:17 -0800 (Mon, 24 Feb 2014) $
;$LastChangedRevision: 14422 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_trange.pro $
;
;-
pro thm_part_trange, probe_in, datatype_in, get=get, set=set, sst_cal=sst_cal

    compile_opt idl2, hidden
    
  
  common thm_part_trange, times
    
  ;initialize timesure if needed
  if ~is_struct(times) then begin
    temp = { peif:[0,0d], $
             peir:[0,0d], $
             peib:[0,0d], $
             peef:[0,0d], $
             peer:[0,0d], $
             peeb:[0,0d], $
             psif:[0,0d], $
             psir:[0,0d], $
             psib:[0,0d], $ ;datatype not used
             psef:[0,0d], $
             pser:[0,0d], $
             pseb:[0,0d], $
             psif_cal:[0,0d], $
             psir_cal:[0,0d], $
             psib_cal:[0,0d], $ ;datatype not used
             psef_cal:[0,0d], $
             pser_cal:[0,0d], $
             pseb_cal:[0,0d]  $
              }
    times = {a:temp, b:temp, c:temp, d:temp, e:temp}
  endif

  
  ;check inputs
  ;----------------
  
  if ~is_string(probe_in) or ~is_string(datatype_in) then begin
    dprint, dlevel=0, 'Must specify probe and datatype'
    return
  endif
  
  datatype = strlowcase(datatype_in[0])
  probe = strlowcase(probe_in[0])

  if ~stregex(datatype,'p[es][ei][frb]',/bool) then begin
    dprint, dlevel=0, 'Invalid data type.'
    return
  endif
  
  if ~stregex(probe,'[abcde]',/bool) then begin
    dprint, dlevel=0, 'Invalid probe.'
    return
  endif
  
  if keyword_set(set) && (n_elements(set) ne 2 || size(/type,set) ne 5) then begin
    dprint, dlevel=0, 'Invalid time range input.'
    return
  endif


  ;set time range
  ;----------------

  valid_datatypes = strlowcase(tag_names(times.a))
  valid_probes = strlowcase(tag_names(times))

  ;use separate range for sst_cal
  if keyword_set(sst_cal) then begin
    if stregex(datatype, 'ps[ei][frb]', /bool) then begin
      datatype += '_cal'
    endif
  endif

  ;locate probe
  pidx = where(probe eq valid_probes, np)
  if np gt 0 then begin

    ;locate datatype
    didx = where(datatype eq valid_datatypes, nd)
    if nd gt 0 then begin

      ;get value
      if arg_present(get) then begin
        get = times.(pidx).(didx)
      endif
      
      ;set value
      if keyword_set(set) then begin
        times.(pidx).(didx) = set
      endif

    endif

  endif

end