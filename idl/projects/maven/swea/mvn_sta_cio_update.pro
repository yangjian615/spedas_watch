;+
;PROCEDURE:   mvn_sta_cio_update
;PURPOSE:
;  Updates STATIC cold ion outflow results in save/restore files.
;
;USAGE:
;  mvn_sta_cio_update, trange [, ndays]
;
;INPUTS:
;       trange:        Start time or time range for making save files, in any 
;                      format accepted by time_double().  If only one time is 
;                      specified, it is taken as the start time and NDAYS is 
;                      used to get the end time.  If two or more times are 
;                      specified, then the earliest and latest times are used.
;                      Fractional days (hh:mm:ss) are ignored.
;
;       ndays:         Number of dates to process.  Only used if TRANGE has
;                      only one element.  Default = 1.
;
;       noguff:        Force update of the shape parameter elements.
;
;       parng:         Pitch angle range for shape parameter elements.
;                        1 = 0-30 deg (default); 2 = 0-45 deg ; 3 = 0-60 deg
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-10-06 09:36:43 -0700 (Fri, 06 Oct 2017) $
; $LastChangedRevision: 24120 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_update.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_update.pro
;-
pro mvn_sta_cio_update, trange, ndays, noguff=noguff, parng=parng

  dpath = root_data_dir() + 'maven/data/sci/sta/l3/cio/'
  froot = 'mvn_sta_cio_'
  dt = 86400D  ; process one day at a time
  noguff = keyword_set(noguff)
  if not keyword_set(parng) then parng = 1

  case n_elements(trange) of
     0  :  begin
             print,'You must specify a start time or time range.'
             return
           end
     1  :  begin
             tstart = time_double(time_string(trange,prec=-3))
             if (size(ndays,/type) eq 0) then ndays = 1
           end
    else : begin
             tmin = min(time_double(trange), max=tmax)
             tstart = time_double(time_string(tmin,prec=-3))
             tstop = time_double(time_string((tmax + dt - 1D),prec=-3))
             ndays = (tstop - tstart)/dt
           end
  endcase

; Process the data one calendar day at a time

  for i=0L,(ndays - 1L) do begin
    timer_start = systime(/sec)

    time = tstart + double(i)*dt
    timespan, time, 1

    tstring = time_string(time)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    opath = dpath + yyyy + '/' + mm + '/'
    file_mkdir2, opath, mode='0774'o  ; create directory structure, if needed
    ofile = opath + froot + yyyy + mm + dd + '.sav'

    finfo = file_info(ofile)
    if (finfo.exists) then begin
      restore, filename=ofile
      str_element, cio_h, 'flux40', success=already_done
      if (noguff or ~already_done) then begin
        dt = cio_h[1].time - cio_h[0].time
        mvn_swe_shape_restore, parng=parng, result=shape
        if (size(shape,/type) eq 8) then begin

          shp = smooth_in_time(transpose(shape.shape[0:1,parng]), shape.t, dt)
          cio_h.shape[0] = interpol(shp[*,0], shape.t, cio_h.time)
          cio_h.shape[1] = interpol(shp[*,1], shape.t, cio_h.time)
          cio_o1.shape = cio_h.shape
          cio_o2.shape = cio_h.shape

          f40 = smooth_in_time(shape.f40, shape.t, dt)
          flux40 = interpol(f40, shape.t, cio_h.time)/1.e5
          str_element, cio_h, 'flux40', flux40, /add
          str_element, cio_o1, 'flux40', flux40, /add
          str_element, cio_o2, 'flux40', flux40, /add

          frat40 = smooth_in_time(shape.fratio_a2t[0,parng], shape.t, dt)
          ratio = interpol(frat40, shape.t, cio_h.time)
          str_element, cio_h, 'ratio', ratio, /add
          str_element, cio_o1, 'ratio', ratio, /add
          str_element, cio_o2, 'ratio', ratio, /add

          save, cio_h, cio_o1, cio_o2, filename=ofile
        endif else print,'Could not restore shape parameter.'
      endif else print,'Save file already up to date: ',ofile

    endif else print,'Save file does not exist: ',ofile
  endfor

  return

end

