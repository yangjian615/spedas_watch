PRO eva_sitl_fom2bak
  compile_opt idl2
  
  ;--------------
  ; PICK A FILE
  ;--------------
  
  fname = dialog_pickfile(/READ,filter=['*.txt;*.sav'])
  if strlen(fname) eq 0 then begin
    answer = dialog_message('Cancelled',/center,/info)
    return
  endif
  found = file_test(fname)
  if ~found then begin
    answer = dialog_message('File not found!',/center,/error)
    return
  endif
  slen = strlen(fname)
  ext = strmid(fname,slen-4,1000)
  print,ext
   
  ;-----------------
  ; RESTORE
  ;-----------------
  if ext eq '.txt' then begin
    unix_fomstr = eva_sitl_fom2bak_from_txt(fname)
  endif else begin
    unix_fomstr = eva_sitl_fom2bak_from_sav(fname)
  endelse
  if n_tags(unix_fomstr) eq 0 then return

  tfom = eva_sitl_tfom(unix_fomstr)
  dtlast = unix_fomstr.TIMESTAMPS[unix_fomstr.NUMCYCLES-1]-unix_fomstr.TIMESTAMPS[unix_fomstr.NUMCYCLES-2]
  
  ;----------------------------------------------------------
  ; DELETE EXISTING SEGMENTS WITHIN THE FOMstr TIMERANGE
  ;----------------------------------------------------------
  BAK = 1L
  get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
  s = lim.UNIX_BAKSTR_MOD
  nmax = n_elements(s.FOM)
  for n=0,nmax-1 do begin
    if (tfom[0] le s.START[n]) and (s.STOP[n] le tfom[1]-dtlast) then begin
      segSelect = {ts:s.START[n],te:s.STOP[n]+dtlast,fom:0.,BAK:BAK,discussion:'', var:''}
      eva_sitl_strct_update, segSelect, BAK=BAK
    endif
  endfor
  
  ;--------------------
  ; ADD NEW SEGMENTS
  ;--------------------
  nmax = unix_fomstr.NSEGS
  for n=0,nmax-1 do begin
    segSelect = {$
      ts:unix_fomstr.TIMESTAMPS[unix_fomstr.START[n]], $
      te:unix_fomstr.TIMESTAMPS[unix_fomstr.STOP[n]],$;+dtlast,$
      fom:unix_fomstr.FOM[n], $
      BAK: BAK, $
      discussion:unix_fomstr.DISCUSSION[n], $
      var:''}
    eva_sitl_strct_update, segSelect, BAK=BAK
  endfor
  
  ;--------------------
  ; UPDATE DISPLAY
  ;--------------------
  tplot
END


