;+
;PROCEDURE:   mvn_sta_cio_save
;PURPOSE:
;  Saves STATIC cold ion outflow results in save/restore files.
;  See mvn_sta_coldion.pro for details.
;
;USAGE:
;  mvn_sta_cio_save, start_day, interval, ndays
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       start_day:     Start date for making save files.
;
;       interval:      If start_day is defined and ndays > 1, then this is the number 
;                      of days to skip before loading the next date.  (Only useful
;                      for poor-man's parallel processing.)  Default = 1
;
;       ndays:         Number of dates to process, each separated by interval.
;                      Default = 1
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-09-06 18:06:57 -0700 (Wed, 06 Sep 2017) $
; $LastChangedRevision: 23901 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_save.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_save.pro
;-
pro mvn_sta_cio_save, start_day=start_day, interval=interval, ndays=ndays

  dpath = root_data_dir() + 'maven/data/sci/sta/l3/cio/'
  froot = 'mvn_sta_cio_'
  oneday = 86400D

  if (size(start_day,/type) eq 0) then begin
    print,'You must specify a start date.'
    return
  endif
  start_day = time_double(time_string(start_day,prec=-3))

  if (size(interval,/type) eq 0) then interval = 1
  if (size(ndays,/type) eq 0) then ndays = 1
  dt = double(interval)*oneday

; Process the data one calendar day at a time

  for i=0L,(ndays - 1L) do begin
    tstart = start_day + double(i)*dt
    timespan, tstart, 1

    tstring = time_string(tstart)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    opath = dpath + yyyy + '/' + mm + '/'
    file_mkdir2, opath, mode='0774'o  ; create directory structure, if needed
    ofile = opath + froot + yyyy + mm + dd + '.sav'

    mvn_swe_load_l0, /spiceinit
    mvn_swe_stat, npkt=npkt, /silent
    if (npkt[2] gt 0L) then begin
      maven_orbit_tplot, /shadow, /loadonly
      mvn_swe_sciplot, padsmo=16, /loadonly
      mvn_scpot
      mvn_sundir, frame='swe', /polar

      mvn_sta_coldion, apid='d1', density=1, temperature=1, velocity=[1,1,1], $
            result_h=cio_h, result_o1=cio_o1, result_o2=cio_o2, /reset, tavg=16, $
            success=ok

      if (ok) then save, cio_h, cio_o1, cio_o2, file=ofile $
              else print,'CIO pipeline failed: ',tstring
    endif
  endfor

  return

end

