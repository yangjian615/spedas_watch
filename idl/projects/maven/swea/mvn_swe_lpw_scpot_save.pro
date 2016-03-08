;+
;PROCEDURE:   mvn_swe_lpw_scpot_save
;PURPOSE:
;
;USAGE:
;  mvn_swe_lpw_scpot_save, start_day=start_day, interval=interval, ndays=ndays
;
;INPUTS:
;       None
;
;KEYWORDS:
;       start_day:     Restore data over this time range.  If not specified, then
;                      timerange() will be called
;
;       interval:      If start_day is defined and ndays > 1, then this is the number 
;                      of days to skip before loading the next date.  (Only useful
;                      for poor-man's parallel processing.)  Default = 1
;
;       ndays:         Number of dates to process, each separated by interval.
;                      Default = 1
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-03-07 09:58:29 -0800 (Mon, 07 Mar 2016) $
; $LastChangedRevision: 20342 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_lpw_scpot_save.pro $
;
;CREATED BY:    Yuki Harada  03-04-16
;FILE: mvn_swe_lpw_scpot_save.pro
;-
pro mvn_swe_lpw_scpot_save, start_day=start_day, interval=interval, ndays=ndays, norbwin=norbwin, _extra=_extra

  dpath = root_data_dir() + 'maven/data/sci/swe/l3/swe_lpw_scpot/'
  froot = 'mvn_swe_lpw_scpot_'
  tname = ['mvn_lpw_swp1_dIV_smo','mvn_lpw_swp1_IV_vinfl', $
           'mvn_lpw_swp1_IV_vinfl_qflag', $
           'mvn_swe_lpw_scpot_lin_para','mvn_swe_lpw_scpot_pow_para', $
           'mvn_swe_lpw_scpot_Ndata', $
           'mvn_swe_lpw_scpot_lin','mvn_swe_lpw_scpot_pow']
  oneday = 86400D

  if (size(interval,/type) eq 0) then interval = 1
  if (size(ndays,/type) eq 0) then ndays = 1
  dt = double(interval)*oneday

  if size(start_day,/type) eq 0 then begin
     tr = timerange()
     start_day = tr[0]
     ndays = floor( (tr[1]-tr[0])/oneday )
  endif

; Load the data one calendar day at a time

  start_day = time_double(time_string(start_day,prec=-3))

  for i=0L,(ndays - 1L) do begin
    tstart = start_day + double(i)*dt

    ;;; need a longer span
    if keyword_set(norbwin) then nd = ceil(4.5*norbwin/24+2) $
    else nd = 9
    timespan,tstart-long(nd/2)*oneday, nd

    opath = dpath + time_string(tstart,tf='YYYY/MM/')
    file_mkdir2, opath, mode='0774'o  ; create directory structure, if needed
    ofile = opath + froot + time_string(tstart,tf='YYYYMMDD')


    ;;; load and process
    mvn_swe_lpw_scpot, norbwin=norbwin, _extra=_extra


    ;;; trim data and save
    for itn=0,n_elements(tname)-1 do begin
       get_data,tname[itn],data=d,dlim=dlim,dtype=dtype
       tplot_rename,tname[itn],tname[itn]+'_all'
       if dtype eq 0 then continue
       w = where( d.x ge tstart and d.x lt tstart+oneday , nw)
       if nw eq 0 then continue
       if tag_exist(d,'v') then begin
          if size(d.v,/n_dimen) eq 2 then newd = {x:d.x[w],y:d.y[w,*],v:d.v[w,*]} else newd = {x:d.x[w],y:d.y[w,*],v:d.v}
       endif else begin
          if size(d.y,/n_dimen) eq 2 then newd = {x:d.x[w],y:d.y[w,*]} else newd = {x:d.x[w],y:d.y[w]}
       endelse
       store_data,tname[itn],data=newd,dlim=dlim
    endfor
    validtname = tnames(tname,n)
    if n gt 0 then tplot_save,validtname,file=ofile,/compress

 endfor

  if size(tr,/type) ne 0 then timespan,tr else timespan, start_day, ndays

  return

end

