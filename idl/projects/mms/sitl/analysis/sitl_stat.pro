;+
; NAME: sitl_stat
;
; PURPOSE: to analyze and get statistics of the back-structure
;
; USASE:
;  By default, this routine analyzes the entire back-structure (i.e., all information since
;  the launch of MMS). 
;  
; KEYWORD:
;   trange: (STRING or DOULBE) specify a time range of analysis.
;
; CREATED BY: Mitsuo Oka   Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-05 12:50:18 -0700 (Wed, 05 Aug 2015) $
; $LastChangedRevision: 18403 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/analysis/sitl_stat.pro $
;-------------------------------
; s: BAKstr
; cat: which Category?
; fomrng: FOM range
; idc: index of clean semgents
FUNCTION sitl_stat_cat, s, cat, fomrng, idc, cretime, fintime, wt
  compile_opt idl2
  ; Filter out segments of the given category
  idx = where( (fomrng[cat,0] le s.FOM[idc]) and (s.FOM[idc] lt fomrng[cat,1]), ct, comp=nidx)
  idxCat0 = idc[idx];real indices of the original list of segments
  imax = n_elements(idxCat0); number of filtered out segments
  wcat0 = lonarr(n_elements(wt)); output
  for i=0,imax-1 do begin; For each clean segment
    j = idxCat0[i]; The real index of the valid segment
    ndx = where( (cretime[j] le wt) and (wt le fintime[j]), ct); extract pending period
    wcat0[ndx] += s.SEGLENGTHS[j]; count segment size
  endfor
  return, wcat0
END

;--------------------------------------
PRO sitl_stat, trange=trange
  compile_opt idl2

  ;----------------
  ; INITIALIZE
  ;----------------
  
  mms_init
  tnow = systime(/utc,/seconds)
  if n_elements(trange) eq 2 then begin
    tr = (size(trange,/type) eq 5) ? trange: time_double(trange)
  endif else begin
    t0 = time_double('2015-03-12/22:44'); MMS launch date
    t0 = time_double('2015-05-01/00:00'); MMS launch date
    tr = [t0, tnow]
  endelse
  print,'current time: '+time_string(systime(/utc,/seconds))
  print,'analyzed period: '+time_string(tr[0])+' - '+time_string(tr[1])
  timespan,tr[0],tr[1]-tr[0],/seconds
  fomrng = fltarr(6,2)
  fomrng[0,*] = [200,256]
  fomrng[1,*] = [100,200]
  fomrng[2,*] = [ 50,100]
  fomrng[3,*] = [ 25, 50]
  fomrng[4,*] = [  0, 25]
  fomrng[5,*] = [  0,256]; in case FOM=255
  
  ;----------------
  ; TIME GRID
  ;----------------
  
  dt = 600.d0;10min; 3600.d0; 1 hour
  nmax = (tr[1]-tr[0])/dt + 4320L
  wt = tr[0]+ dindgen(nmax)*dt

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
  
  ;-----------------------
  ; CREATE & FINISH TIME
  ;-----------------------

  cretime = time_double(s.CREATETIME)
  fintime = time_double(s.FINISHTIME)
  idx = where(strlen(s.FINISHTIME) eq 0, ct)
  if ct gt 0 then begin
    fintime[idx] = tnow
  endif

  ;------------------
  ; ANALYSIS
  ;------------------
  
  wcatT = lonarr(nmax); All segmentes
  wcatT2= lonarr(nmax); Segments being HELD for more than 3 days
  cat = 5
  idc = sitl_stat_cleanseg(s)
  idxCatT = idc
  imax = n_elements(idxCatT)
  for i=0,imax-1 do begin; For each clean segment
    j = idxCatT[i]; The real index of the valid segment
    ndx = where( (cretime[j] le wt) and (wt le fintime[j]), ct)
    wcatT[ndx] += s.SEGLENGTHS[j]
    ;ndx = where( (cretime[j]+3.d0*86400.d0 le wt) and (wt le fintime[j]), ct)
    ndx = where( (time_double(s.START[j])+3.d0*86400.d0 le wt) and (wt le fintime[j]), ct)
    wcatT2[ndx] += s.SEGLENGTHS[j]
  endfor
  
  ; For each category
  wcat0 = sitl_stat_cat(s, 0, fomrng,idc, cretime, fintime, wt)
  wcat1 = sitl_stat_cat(s, 1, fomrng,idc, cretime, fintime, wt)
  wcat2 = sitl_stat_cat(s, 2, fomrng,idc, cretime, fintime, wt)
  wcat3 = sitl_stat_cat(s, 3, fomrng,idc, cretime, fintime, wt)
  wcat4 = sitl_stat_cat(s, 4, fomrng,idc, cretime, fintime, wt)
  wcat  = lonarr(nmax,6)
  wcat[*,0] = wcat0
  wcat[*,1] = wcat1
  wcat[*,2] = wcat2
  wcat[*,3] = wcat3
  wcat[*,4] = wcat4
  wcat[*,5] = wcatT
  v = [0,1,2,3,4,5]
  
  ;------------------
  ; OUTPUT
  ;------------------
  
  ; tplot variables
  store_data,'wcatT',data={x:wt, y:wcatT} & options,'wcatT','ytitle','Total'
  store_data,'wcatT2',data={x:wt,y:wcatT2}& options,'wcatT2','ytitle','HELD >3days'
  store_data,'wcat0',data={x:wt, y:wcat0} & options,'wcat0','ytitle','Cat 0'
  store_data,'wcat1',data={x:wt, y:wcat1} & options,'wcat1','ytitle','Cat 1'
  store_data,'wcat2',data={x:wt, y:wcat2} & options,'wcat2','ytitle','Cat 2'
  store_data,'wcat3',data={x:wt, y:wcat3} & options,'wcat3','ytitle','Cat 3'
  store_data,'wcat4',data={x:wt, y:wcat4} & options,'wcat4','ytitle','Cat 4'
  store_data,'wcatS',data={x:wt,y:wcat,v:v} & options,'wcatS','ytitle','Combined'
  tpv = ['wcatS','wcatT','wcatT2','wcat0','wcat1','wcat2','wcat3','wcat4']
  tplot,tpv

  ; ASCII files  
  tplot_ascii,/header, tpv,fname='sitl_stat',ext='.txt';,dir=!MMS.LOCAL_DATA_DIR
END
