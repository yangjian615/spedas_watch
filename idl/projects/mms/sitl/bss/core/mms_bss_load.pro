FUNCTION mms_bss_load, trange=trange
  compile_opt idl2

  mms_init

  ;----------------
  ; TIME RANGE
  ;----------------
  tnow = systime(/utc,/seconds)
  tr = (n_elements(trange) eq 2) ? timerange(trange) : [time_double('2015-03-12/22:44'),tnow]
  print,' Executing query: '
  print,' timerange = '+time_string(tr[0])+' - '+time_string(tr[1])

  ;------------------
  ; GET BACK-STRUCT
  ;------------------
  mms_get_back_structure, tr[0], tr[1], BAKStr, pw_flag, pw_message; START,STOP are ULONG
  if pw_flag then begin
    print,'pw_flag = 1'
    print, pw_message
    return, -1
  endif
  s = BAKStr
  str_element,/add,s,'START', mms_tai2unix(BAKStr.START); START,STOP are LONG
  str_element,/add,s,'STOP',  mms_tai2unix(BAKStr.STOP)

  ;-----------------------
  ; CREATE & FINISH TIME
  ;-----------------------
  ; If pending, FINISHTIME will be a null string and will cause some inconvenience later.
  ; Here, such null FINISHTIMEs are replaced with the current time.
  cretime = time_double(s.CREATETIME)
  fintime = time_double(s.FINISHTIME)
  idx = where(strlen(s.FINISHTIME) eq 0, ct)
  if ct gt 0 then begin
    fintime[idx] = tnow
  endif
  str_element,/add,s,'UNIX_FINISHTIME',fintime
  str_element,/add,s,'UNIX_CREATETIME',cretime
  
  return, s
END
