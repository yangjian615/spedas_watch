;+
; NAME: mms_bss_history
;
; PURPOSE: To create a time-profile of the number of PENDING segments.
;
; USAGE:
;   With no keyword, this program diplays the plot in an IDL window.
;   Use the keywords for outputs.
;   
; KEYWORDS:
;   BSS: back-structure created by mms_bss_query
;   TRANGE: narrow the time range. It can be in either string or double.
;   ASCII: 'tplot_ascii' commands will be used to export the results
;   CVS: to be implemented
;   JSON: to be implemented
;   
; CREATED BY: Mitsuo Oka  Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-26 18:01:27 -0700 (Wed, 26 Aug 2015) $
; $LastChangedRevision: 18636 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_bss_history.pro $
;-
FUNCTION mms_bss_history_cat, bsh, category, wt
  compile_opt idl2
  wcat = lonarr(n_elements(wt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    ndx = where( (s.UNIX_CREATETIME[i] le wt) and (wt le s.UNIX_FINISHTIME[i]), ct); extract pending period
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, wcat
END

FUNCTION mms_bss_history_overwritten, bsh, category, wt
  compile_opt idl2
  wcat = lonarr(n_elements(wt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    result=min(wt-s.UNIX_FINISHTIME[i],ndx, /absolute)
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, (-1L)*wcat
END

PRO mms_bss_history, bss=bss, trange=trange, ascii=ascii
  compile_opt idl2
  
  mms_init

  ;----------------
  ; TIME
  ;----------------
  tnow = systime(/utc,/seconds)
  tlaunch = time_double('2015-03-12/22:44')
  t3m = tnow - 90.d0*86400.d0; 90 days
  if n_elements(trange) eq 2 then begin
    tr = timerange(trange)
  endif else begin
    ;tr = [t3m,tnow]
    tr = [tlaunch,tnow]
    trange = time_string(tr)
  endelse
  ; time grid
  mmax = 4320L ; extra data point for display grey-shaded region
  dt = 600.d0;10min
  nmax = (tr[1]-tr[0])/dt + mmax
  wt = tr[0]+ dindgen(nmax)*dt
  wDs = time_double(time_string(tr[0],prec=-3))
  wDe = time_double(time_string(tr[1],prec=-3))+86400.d0
  qmax = floor((wDe-wDs)/86400.d0); number of days
  wDt = wDs + 86400.d0*dindgen(qmax)
  wDi = lonarr(qmax)
  wDd = lonarr(qmax)

  ;----------------
  ; LOAD DATA
  ;----------------
  if n_elements(bss) eq 0 then bss = mms_bss_query(trange=trange)

  ;------------------
  ; ANALYSIS
  ;------------------
  
  wcatT = lonarr(nmax); All segmentes
  wcatT2= lonarr(nmax); Segments being HELD for more than 3 days
  imax = n_elements(bss.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    ndx = where( (bss.UNIX_CREATETIME[i] le wt) and (wt le bss.UNIX_FINISHTIME[i]), ct); extract pending period
    wcatT[ndx] += bss.SEGLENGTHS[i]; count segment size
    ndx = where( (bss.START[i]+3.d0*86400.d0 le wt) and (wt le bss.UNIX_FINISHTIME[i]), ct)
    wcatT2[ndx] += bss.SEGLENGTHS[i]
  endfor
  wcatT2[nmax-mmax:nmax-1] = !VALUES.F_NAN

  ; Newly held buffers and newly transmitted buffers
  wInc = lonarr(nmax); increase --> mostly selected buffers by SITL
  wDec = lonarr(nmax); decrease --> mostly transmitted buffers by SDC
  for n=1,nmax-1 do begin; for each time step
    this_wDt = time_double(time_string(wt[n],prec=-3))
    result = min(wDt-this_wDt,q,/abs); determine the date
    if wcatT[n]-wcatT[n-1] ge 0 then begin; if increased
      wInc[n] = wcatT[n] - wcatT[n-1]
      wDi[q] += wInc[n]
    endif else begin
      wDec[n] = wcatT[n-1] - wcatT[n]
      wDd[q] += wDec[n]
    endelse
    
  endfor
  
  ; All segments (except bad segments and DELETED segments)
  wcat0  = mms_bss_history_cat(bss, 0, wt)
  wcat1  = mms_bss_history_cat(bss, 1, wt)
  wcat2  = mms_bss_history_cat(bss, 2, wt)
  wcat3  = mms_bss_history_cat(bss, 3, wt)
  wcat4  = mms_bss_history_cat(bss, 4, wt)
  
  ; Overwritten segments
  bsA = mms_bss_query(bss=bss,exclude='INCOMPLETE'); exclude INCOMPLETE segments
  bsB = mms_bss_query(bss=bsA,status='DERELICT DEMOTED'); include DERELICT and/or DEMOTED segments
  
  wcat0m = mms_bss_history_overwritten(bsB, 0, wt)
  wcat1m = mms_bss_history_overwritten(bsB, 1, wt)
  wcat2m = mms_bss_history_overwritten(bsB, 2, wt)
  wcat3m = mms_bss_history_overwritten(bsB, 3, wt)
  wcat4m = mms_bss_history_overwritten(bsB, 4, wt)
  
  ;------------------
  ; TPLOT_ASCII
  ;------------------
  if keyword_set(ascii) then begin
    ; tplot variables
    store_data,'wcatT',data={x:wt, y:wcatT} & options,'wcatT','ytitle','Total'
    store_data,'wcatT2',data={x:wt,y:wcatT2}& options,'wcatT2','ytitle','HELD >3days'
    store_data,'wcat0',data={x:wt, y:wcat0} & options,'wcat0','ytitle','Cat 0'
    store_data,'wcat1',data={x:wt, y:wcat1} & options,'wcat1','ytitle','Cat 1'
    store_data,'wcat2',data={x:wt, y:wcat2} & options,'wcat2','ytitle','Cat 2'
    store_data,'wcat3',data={x:wt, y:wcat3} & options,'wcat3','ytitle','Cat 3'
    store_data,'wcat4',data={x:wt, y:wcat4} & options,'wcat4','ytitle','Cat 4'
    store_data,'wcat0m',data={x:wt, y:wcat0m} & options,'wcat0m','ytitle','Cat 0'
    store_data,'wcat1m',data={x:wt, y:wcat1m} & options,'wcat1m','ytitle','Cat 1'
    store_data,'wcat2m',data={x:wt, y:wcat2m} & options,'wcat2m','ytitle','Cat 2'
    store_data,'wcat3m',data={x:wt, y:wcat3m} & options,'wcat3m','ytitle','Cat 3'
    store_data,'wcat4m',data={x:wt, y:wcat4m} & options,'wcat4m','ytitle','Cat 4'
    tpv = ['wcatT','wcatT2','wcat0','wcat1','wcat2','wcat3','wcat4',$
      'wcat0m','wcat1m','wcat2m','wcat3m','wcat4m']
    tplot_ascii,/header, tpv,fname='sitl_stat',ext='.txt';,dir=!MMS.LOCAL_DATA_DIR
  endif
  
  ;------------------
  ; TPLOT (HELD seg)
  ;------------------
  wcat  = lonarr(nmax,10)
  wcat[*,4] = wcat4
  wcat[*,3] = wcat[*,4] + wcat3
  wcat[*,2] = wcat[*,3] + wcat2
  wcat[*,1] = wcat[*,2] + wcat1
  wcat[*,0] = wcat[*,1] + wcat0
  wcat[*,5] = wcat4m
  wcat[*,6] = wcat[*,5] + wcat3m
  wcat[*,7] = wcat[*,6] + wcat2m
  wcat[*,8] = wcat[*,7] + wcat1m
  wcat[*,9] = wcat[*,8] + wcat0m

  v = [0,1,2,3,4,4,3,2,1,0]
  store_data,'wcatS',data={x:wt, y:wcat, v:v}
  options,'wcatS','colors',[0,6,5,4,2,2,4,5,6,0]
  options,'wcatS','ytitle','Number of HELD Buffers'
  options,'wcatS','title','MMS Burst Memory Management'
  tplot,['wcatS']
  
  store_data,'wInc',data={x:wt,y:wInc}
  store_data,'wDec',data={x:wt,y:wDec}
  store_data,'wDi',data={x:wDt,y:wDi}
  store_data,'wDd',data={x:wDt,y:wDd}
END
