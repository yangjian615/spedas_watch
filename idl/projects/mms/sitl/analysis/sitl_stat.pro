;+
; NAME: sitl_stat
;
; PURPOSE: to analyze and get statistics of the back-structure
;
; USASE:
;  By default, this routine analyzes the entire back-structure (i.e., all information since
;  the launch of MMS) and then produce
;  (1) time profiles of number of HELD buffers (Use /nobuffplot to skip this feature)
;  (2) a table of pending (HELD) buffers (Use /nobufftable to skip this feature)
;  (3) FOM-time diagram (Use /nofomplot to skip this feature)
;  
; KEYWORD:
;   trange: (STRING or DOULBE) specify a time range of analysis.
;
; CREATED BY: Mitsuo Oka   Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-05 16:20:28 -0700 (Wed, 05 Aug 2015) $
; $LastChangedRevision: 18408 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/analysis/sitl_stat.pro $
;-
PRO sitl_stat, trange=trange, $
  nobuffplot=nobuffplot, nobufftable=nobufftable, nofomplot=nofomplot
  compile_opt idl2
  mms_init
  
  ;----------------
  ; TIME RANGE
  ;----------------
  tnow = systime(/utc,/seconds)
  if n_elements(trange) eq 2 then begin
    tr = (size(trange,/type) eq 5) ? trange: time_double(trange)
  endif else begin
    t0 = time_double('2015-03-12/22:44'); MMS launch date
    t0 = time_double('2015-05-01/00:00'); MMS launch date
    tr = [t0, tnow]
  endelse
  print,'current time: '+time_string(tnow)
  print,'analyzed period: '+time_string(tr[0])+' - '+time_string(tr[1])
  timespan,tr[0],tr[1]-tr[0],/seconds
  
  ;----------------------
  ; CATEGORY DEFINITION
  ;----------------------
  fomrng = fltarr(6,2)
  fomrng[0,*] = [200,256]
  fomrng[1,*] = [100,200]
  fomrng[2,*] = [ 50,100]
  fomrng[3,*] = [ 25, 50]
  fomrng[4,*] = [  0, 25]
  fomrng[5,*] = [  0,256]; in case FOM=255

  ;------------------
  ; GET BACK-STRUCT
  ;------------------
  mms_get_back_structure, tr[0], tr[1], BAKStr, pw_flag, pw_message; START,STOP are ULONG
  if pw_flag then begin
    print,'pw_flag = 1'
    print, pw_message
    return
  endif
  s = BAKStr
  str_element,/add,s,'START', mms_tai2unix(BAKStr.START); START,STOP are LONG
  str_element,/add,s,'STOP',  mms_tai2unix(BAKStr.STOP)
  
  ;------------------
  ; ANALYSIS
  ;------------------
  if ~keyword_set(nobuffplot)  then sitl_stat_buffplot, s, fomrng, tr
  if ~keyword_set(nobufftable) then sitl_stat_bufftable, s, fomrng,/isPending
  if ~keyword_set(nofomplot) then   sitl_stat_fomplot, s;, tr=tr
END
