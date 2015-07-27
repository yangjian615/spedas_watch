;+
; NAME: sitl_bakstr_stat
;
; PURPOSE: to show statistics of back-structure segments
;
; KEYWORD:
;   t1 : start time (STRING or DOUBLE) e.g. '2015-06-22'
;   dt : duration in DAYS
;   isPending: set this keyword to analyze pending segments only.
;   
; CREATED BY: Mitsuo Oka   July 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-07-26 02:45:11 -0700 (Sun, 26 Jul 2015) $
; $LastChangedRevision: 18265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_bakstr_stat.pro $
;
PRO sitl_bakstr_stat,t1=t1, dt=dt, isPending=isPending
  compile_opt idl2

  mms_init

  if n_elements(t1) eq 0 then begin
    t1 = systime(1,/utc)-60.d0*86400.d0
  endif else begin
    if size(t1,/type) eq 7 then t1 = time_double(t1)
  endelse

  if n_elements(dt) eq 0 then dt = 60. ; DAYS
  tspan = [t1,t1+dt*86400.d0]

  ;------------------
  ; GET BACK-STRUCT
  ;------------------
  tn = tnames('mms_stlm_bakstr')
  if strlen(tn[0]) eq 0 then begin
    ;print, 'EVA: bakstr is not loaded as a tplot variable'
    ;return, 0
    mms_get_back_structure, tspan[0], tspan[1], BAKStr, pw_flag, pw_message; START,STOP are ULONG
    if pw_flag then begin
      print,'pw_flag = 1'
      print, pw_message
      return
    endif else begin
      unix_BAKStr_mod = BAKStr
      str_element,/add,unix_BAKStr_mod,'START', mms_tai2unix(BAKStr.START); START,STOP are LONG
      str_element,/add,unix_BAKStr_mod,'STOP',  mms_tai2unix(BAKStr.STOP)
      D = eva_sitl_strct_read(unix_BAKStr_mod,tspan[0],/quiet); Do not put the isPending keyword here
      store_data,'mms_stlm_bakstr',data=D
      options,'mms_stlm_bakstr','ytitle','BAK'
      options,'mms_stlm_bakstr','ysubtitle','(SOC)'
      options,'mms_stlm_bakstr','colors',85; 179
      options,'mms_stlm_bakstr','unix_BAKStr_mod',unix_BAKStr_mod
    endelse
  endif
  
  ;------------------
  ; PLOT BACK-STRUCT
  ;------------------
  get_data,'mms_stlm_bakstr',data=D,dl=dl,lim=lim
  D = eva_sitl_strct_read(lim.unix_BAKStr_mod,tspan[0],isPending=isPending,/quiet); Use isPending here
  store_data,'mms_stlm_bakstr',data=D,dl=dl,lim=lim
  tplot,'mms_stlm_bakstr'
  
  ;------------------
  ; STAT BACK-STRUCT
  ;------------------
  c = sitl_bakstr_stat_table(isPending=isPending)

  nmax = n_elements(c)
  ttlNsegs = 0
  ttlNbuffs = 0
  ttlTmin = 0.
  for n=0,nmax-2 do begin
    ttlNsegs += c[n].Nsegs
    ttlNbuffs += c[n].Nbuffs
    ttlTmin += c[n].Tminutes
  endfor

  print,'-----------------------------------------'
  print,'Category  ,  Nsegs, Nbuffs,  [min],     %'
  print,'-----------------------------------------'
  for n=0,nmax-1 do begin

    str = string(c[n].Nsegs,format='(I8)')
    str+= string(c[n].Nbuffs,format='(I8)')
    str+= string(c[n].Tminutes,format='(I8)')
    str+= string(100.d0*double(c[n].Tminutes)/double(ttlTmin),format='(F6.1)')
    print, c[n].strlbl+str
  endfor
  
  
END