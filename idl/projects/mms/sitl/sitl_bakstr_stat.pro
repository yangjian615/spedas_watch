;+
; NAME: sitl_bakstr_stat
;
; PURPOSE: to show statistics of back-structure segments
;
; USAGE:
;   By default, this program analyzes all segments since the beginning of the mission. 
;   Use the keyword 'trange' to specify a desired time-range.
;   
; CREATED BY: Mitsuo Oka   July 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-01 00:14:26 -0700 (Sat, 01 Aug 2015) $
; $LastChangedRevision: 18352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_bakstr_stat.pro $
;
PRO sitl_bakstr_stat, isPending=isPending,trange=trange,fomt=fomt
  compile_opt idl2

  mms_init

  if n_elements(trange) eq 2 then begin
    tr = (size(trange,/type) eq 5) ? trange: time_double(trange)
  endif else begin
    t0 = time_double('2015-3-12/22:44'); MMS launch date
    tnow = systime(/utc,/seconds)
    tr = [t0, tnow]
  endelse
  print, time_string(tr)
  
;  tr = timerange(/current)
;  print, time_string(tr)
  
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

;  nmax= n_elements(s.FOM)
;  for n=0,nmax-1 do begin
;    if s.SEGLENGTHS[n] gt 1000 then begin
;    print, n,' ',time_string(s.START[n]), ' ', s.STATUS[n],' ',s.SEGLENGTHS[n]
;    endif
;  endfor
;  
;  stop

  print,'--------------------------------------------'
  print,'          ,   Nsegs,  Nbuffs,   [min],     %'
  print,'--------------------------------------------'
  
  T = sitl_bakstr_stat_table(s,isPending=isPending,/quiet)
  T0 = sitl_bakstr_stat_table(s,cat=0,title='Category 0',isPending=isPending,ttl=T.Tmin)
  T1 = sitl_bakstr_stat_table(s,cat=1,title='Category 1',isPending=isPending,ttl=T.Tmin)
  T2 = sitl_bakstr_stat_table(s,cat=2,title='Category 2',isPending=isPending,ttl=T.Tmin)
  T3 = sitl_bakstr_stat_table(s,cat=3,title='Category 3',isPending=isPending,ttl=T.Tmin)
  T4 = sitl_bakstr_stat_table(s,cat=4,title='Category 4',isPending=isPending,ttl=T.Tmin)
  TT = sitl_bakstr_stat_table(s,title='Total     ',isPending=isPending,ttl=T.Tmin)

  ;------------
  ; PLOT 
  ;------------
  if keyword_set(fomt) then begin
    TT = sitl_bakstr_stat_table(s,title='Cmplt+Fnsd',ttl=T.Tmin,$
      status1='COMPLETE',status2='FINISHED')
    if n_elements(TT.wx) gt 1 then begin
      plot, TT.wx, TT.wy,psym=2,xtitle='Number of Days',ytitle='FOM'
    endif
  endif
END