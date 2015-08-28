;+
; NAME: mms_bss_history
;
; PURPOSE: 
;   To create a time-profile of the number of PENDING segments.
;   'bss' stands for 'burst segment status' which is the official 
;   name of the back-structure.
;
; USAGE:
;   With no keyword, this program diplays the plot in an IDL window.
;   Use the keywords for outputs.
;   
; KEYWORDS:
;   BSS: back-structure created by mms_bss_query
;   TRANGE: narrow the time range. It can be in either string or double.
;   TPLOT: 0 = no plot; 1 = tplot (default)
;   ASCII: 'tplot_ascii' commands will be used to export the results
;   CSV: output into csv files
;   
; CREATED BY: Mitsuo Oka  Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-26 23:12:16 -0700 (Wed, 26 Aug 2015) $
; $LastChangedRevision: 18639 $
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

FUNCTION mms_bss_history_overwritten, bsh, category, wDt
  compile_opt idl2
  wcat = lonarr(n_elements(wDt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    day = time_double(time_string(s.UNIX_FINISHTIME[i],prec=-3))
    result = min(wDt-day, ndx,/abs)
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, wcat
END

FUNCTION mms_bss_history_overwritten2, bsh, category, wt
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

PRO mms_bss_history, bss=bss, trange=trange, ascii=ascii, tplot=tplot, csv=csv, dir=dir
  compile_opt idl2
  mms_init
  
  if undefined(tplot) then tplot=1
  if undefined(dir) then dir = '' else dir = thm_addslash(dir) 
  
  ;----------------
  ; TIME
  ;----------------
  tnow = systime(/utc,/seconds)
  tlaunch = time_double('2015-03-12/22:44')
  t3m = tnow - 90.d0*86400.d0; 90 days
  if n_elements(trange) eq 2 then begin
    tr = timerange(trange)
  endif else begin
    tr = [t3m,tnow]
    ;tr = [tlaunch,tnow]
    trange = time_string(tr)
  endelse
  
  ; time grid to be used for Pending buffer history
  mmax = 4320L ; extra data point for displaying grey-shaded region
  dt = 600.d0;10min
  nmax = (tr[1]-tr[0])/dt; + mmax
  wt = tr[0]+ dindgen(nmax)*dt
  
  ; time grid to be used for daily values of Increase and Decrease
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
  ;wcatT2[nmax-mmax:nmax-1] = !VALUES.F_NAN
  wcatT2[nmax-1] = wcatT2[nmax-2]

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
  bsB = mms_bss_query(bss=bsA,status='DERELICT DEMOTED'); include DERELICT or DEMOTED segments
  wcat0m = mms_bss_history_overwritten2(bsB, 0, wt)
  wcat1m = mms_bss_history_overwritten2(bsB, 1, wt)
  wcat2m = mms_bss_history_overwritten2(bsB, 2, wt)
  wcat3m = mms_bss_history_overwritten2(bsB, 3, wt)
  wcat4m = mms_bss_history_overwritten2(bsB, 4, wt)
  wcat0o = mms_bss_history_overwritten(bsB, 0, wDt)
  wcat1o = mms_bss_history_overwritten(bsB, 1, wDt)
  wcat2o = mms_bss_history_overwritten(bsB, 2, wDt)
  wcat3o = mms_bss_history_overwritten(bsB, 3, wDt)
  wcat4o = mms_bss_history_overwritten(bsB, 4, wDt)
  
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
  ; CSV
  ;------------------
  if keyword_set(csv) then begin
    
    ; PENDING SEGMENTS
    write_csv, dir+'mms_bss_history.txt', wt,wcatT,wcatT2,wcat0,wcat1,wcat2,wcat3,wcat4,$
      HEADER=['time','Total','HELD >3days','Category 0','Category 1','Category 2',$
      'Category 3','Category 4']
    
    ; OVERWRITTEN SEGMENTS
    write_csv, dir+'mms_bss_overwritten.txt', wDt,wcat0o,wcat1o,wcat2o,wcat3o,wcat4o,$
      HEADER=['time','Category 0','Category 1','Category 2','Category 3','Category 4']
    
    ; INCREASE/DECREASE
    write_csv, dir+'mms_bss_diff.txt', wt,wInc,wDec,$
      HEADER=['time','Increase','Decrease']
    write_csv, dir+'mms_bss_diff_per_day.txt', wDt,wDi,wDd,$
      HEADER=['time','Increase/day','Decrease/day']  
       
  endif
  
  ;------------------
  ; TPLOT
  ;------------------
  if keyword_set(tplot) then begin
    
    ; PENDING SEGMENTS
    wcat  = lonarr(nmax,6)
    wcat[*,5] = wcatT2; HELD > 3 days
    wcat[*,4] = wcat4; Category 4
    wcat[*,3] = wcat[*,4] + wcat3; Category 4 + 3
    wcat[*,2] = wcat[*,3] + wcat2; Category 4 + 3 + 2
    wcat[*,1] = wcat[*,2] + wcat1; Category 4 + 3 + 2 + 1
    wcat[*,0] = wcat[*,1] + wcat0; Category 4 + 3 + 2 + 1 + 0
    store_data,'mms_bss_history',data={x:wt, y:wcat, v:[0,1,2,3,4,5]}
    options,'mms_bss_history',colors=[1,6,5,4,2,0],ytitle='PENDING Buffers',$
      title='MMS Burst Memory Management',labels=['Category 0','Category 1','Category 2',$
      'Category 3','Category 4','HELD >3days'],labflag=-1
  
    ; OVERWRITTEN SEGMENTS
    wDt += 43200.d0; Psym=10 makes a bar centered around wDt. Here, we shift by 12 hours to correct this.
    wovr = lonarr(qmax,5)
    wovr[*,4] = wcat4o
    wovr[*,3] = wovr[*,4] + wcat3o
    wovr[*,2] = wovr[*,3] + wcat2o
    wovr[*,1] = wovr[*,2] + wcat1o
    wovr[*,0] = wovr[*,1] + wcat0o
    store_data,'mms_bss_overwritten',data={x:wDt, y:wovr, v:[0,1,2,3,4]}
    options,'mms_bss_overwritten',colors=[0,6,5,4,2],ytitle='Overwritten Buffers',$
      labels=['Category 0','Category 1','Category 2','Category 3','Category 4'],labflag=-1,$
      psym=10
    
    ; INCREASE/DECREASE
    store_data,'mms_bss_inc',data={x:wt,y:wInc}
    store_data,'mms_bss_dec',data={x:wt,y:wDec}
    store_data,'mms_bss_inc_per_day',data={x:wDt,y:wDi}
    store_data,'mms_bss_dec_per_day',data={x:wDt,y:wDd}
    options,'mms_bss_inc_per_day',psym=10,colors=0,labels=['increase']
    options,'mms_bss_dec_per_day',psym=10,colors=1,labels=['decrease']
    store_data,'mms_bss_diff_per_day',data=['mms_bss_inc_per_day','mms_bss_dec_per_day']
    options,'mms_bss_diff_per_day',ytitle='PENDING Buffers',labflag=-1
  
    ; PLOT  
    timespan,time_string(tr[0]),tr[1]-tr[0]+3.d0*86400.d0,/seconds
    tplot,['mms_bss_history','mms_bss_diff_per_day','mms_bss_overwritten']
  endif
END
