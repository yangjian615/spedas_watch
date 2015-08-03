;+
; NAME: sitl_bakstr_stat
;
; PURPOSE: to show statistics of back-structure segments
;
; USAGE:
;   By default, this program analyzes all segments since the beginning of the mission. 
; 
; KEYWORD:
;   TRANGE: specify a desired time-range.
;   FOMT: set this keyword for a FOM-time plot
;   
; CREATED BY: Mitsuo Oka   July 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-02 01:39:42 -0700 (Sun, 02 Aug 2015) $
; $LastChangedRevision: 18357 $
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
  ;print,'-------------------------------------------------------------------'
  print,'time period: '+time_string(tr[0])+' - '+time_string(tr[1])
  
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

  print,'-------------------------------------------------------------------'
  print,'          ,   Nsegs,  Nbuffs,   [min],      %,  Oldest segment'
  print,'-------------------------------------------------------------------'
  
  Tmin  = sitl_bakstr_stat_table(s,isPending=isPending,/quiet)
  Tmin0 = sitl_bakstr_stat_table(s,cat=0,title='Category 0',isPending=isPending,ttl=Tmin)
  Tmin1 = sitl_bakstr_stat_table(s,cat=1,title='Category 1',isPending=isPending,ttl=Tmin)
  Tmin2 = sitl_bakstr_stat_table(s,cat=2,title='Category 2',isPending=isPending,ttl=Tmin)
  Tmin3 = sitl_bakstr_stat_table(s,cat=3,title='Category 3',isPending=isPending,ttl=Tmin)
  Tmin4 = sitl_bakstr_stat_table(s,cat=4,title='Category 4',isPending=isPending,ttl=Tmin)
  TminT = sitl_bakstr_stat_table(s,title='Total     ',isPending=isPending,ttl=Tmin)

  ;------------
  ; PLOT 
  ;------------
  if keyword_set(fomt) then begin
    A = FINDGEN(17) * (!PI*2/16.); Make a vector of 16 points, A[i] = 2pi/16:
    USERSYM, COS(A), SIN(A), /FILL; Define the symbol, unit circle, filled
    charsize = 1.2
    
    plot,[0,30],[0,250],/nodata,xtitle='Number of days to FINISH',ytitle='FOM', color=0
    
    complete = sitl_bakstr_stat_fomt(s,status1='COMPLETE')
    oplot, complete.x, complete.y, psym=8,color=4
    xyouts, 20,200, 'TRANSMITTED: '+string(complete.NSEGS,format='(I8)'), charsize=charsize, color=4,/data
    
    pending = sitl_bakstr_stat_fomt(s,isPending=1)
    oplot, pending.x, pending.y, psym=8, color=0
    xyouts, 20,190, 'PENDING:     '+string(pending.NSEGS,format='(I8)'), charsize=charsize, color=0,/data
    
    
    demoted = sitl_bakstr_stat_fomt(s,status1='DEMOTED')
    if demoted.NMAX gt 0 then begin
      oplot, demoted.x, demoted.y, psym=8, color=6
      for n=0,demoted.NMAX-1 do begin
        print, 'n=',n,',',s.STATUS[demoted.IDX[n]]
      endfor
    endif
    xyouts, 20,180, 'OVERWRITTEN: '+string(demoted.NSEGS,format='(I8)'), charsize=charsize, color=6,/data
    
  endif
END