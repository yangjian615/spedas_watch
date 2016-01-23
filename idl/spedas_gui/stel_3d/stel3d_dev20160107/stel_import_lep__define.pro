;+
; <B>File Name :</B>stel_import_lep__deffine.pro<P>
; <B>Class Name :</B>stel_import_lep<P>
;
;@file_comments
; <B>Purpose :</B>
; <P>import ION 3D distribution dataP>
;
; <B>Members :</B>
; <P>stel_import_lep    ハッシュ格納用のメンバー<P>
;
;@history
; Who      Date        version  Description<P>
; ----------------------------------------------------------------------------<P>
; Exelis VIS KK 2014/05/20  1.0.0.0  Original Version<P>
;-

;
; ION 3D distribution data import
;
function stel_import_lep::init, infile
  @stel3d_common

  self.stel_import_lep = hash()
  if n_elements(infile) eq 1 then begin
    res = self.read_lep(infile)
    if ~res then return, 0 else return, res
  endif
  
  return, obj_valid(self.stel_import_lep)

end
;
;
;
function stel_import_lep::checkTimeFormat, strtime
  
  cnt = 0
  foreach elem, strtime do begin
    res = strmatch(elem, '????-??-??/??:??:??')
    if (res eq 0) then begin
      pos = strpos(elem, ' ')
      if pos ne -1 then begin 
        strtime_arr = strsplit(elem, ' ', /EXTRACT)
        if ~strmatch(strtime_arr[0], '????-??-??') then begin
          year = strmid(strtime_arr[0], 0, 4)
          mon = strmid(strtime_arr[0], 4, 2)
          day = strmid(strtime_arr[0], 6, 2)
          strday = strjoin([year, mon, day], '-')
        endif else strday = strtime_arr[0]
        if ~strmatch(strtime_arr[1], '??:??:??') then begin
          hour = strmid(strtime_arr[1], 0, 2)
          min = strmid(strtime_arr[1], 2, 2)
          sec = strmid(strtime_arr[1], 4, 2)
          strhour = strjoin([hour, min, sec], ':')
        endif else strhour = strtime_arr[1]
      endif
      strtime[cnt] = strday+'/'+strhour
    endif
    
    cnt ++
  endforeach
  
  return, strtime

end
;
;
;
function stel_import_lep::read_lep, infile, DATA=data, TRANGE=trange, sat=sat 

  ;check 
  ;Kuni   if ~file_test(infile) then begin
  ;Kuni     message, 'input file does not exist'
  ;Kuni     return, 0
  ;Kuni   endif
  
  if keyword_set(trange) then begin 
    str_start_time = trange[0]
    str_end_time = trange[1]
;    start_time = self.convertJulday(str_start_time)
;    end_time = self.convertJulday(str_end_time)
    start_time = self.convertUnixTime(str_start_time)
    end_time = self.convertUnixTime(str_end_time)
  endif
  ; 
  ;Kuni 
  ;goto, lab1
  if not keyword_set(sat) then begin  
  ; - - - - READ GEOTAIL TEXT DATA - - - - 
  ; 
  ; - - - - - - - - - - - - - - - - - - - - 
  ;
  ; define data size for one observation of 3D distributions. 
  ;
  ;Todo: need to modify  
  ; - - - - - - - - - - - - - - - - - - - - 
  num_elems = 32*16*7 
;  num_elems = 32*32*16 
  tmp = ''
  data = hash()
  
  ; 
  openR, lun, infile, /GET_LUN
  while ~eof(lun) do begin
    readf, lun, tmp
    if tmp eq '' then continue
    pos = strpos(tmp, ' ') 
    if (pos[0] ne 0) then begin
      if keyword_set(trange) then begin
        ;ob_time = self.convertJulday(tmp)
        ob_time = self.convertUnixTime(tmp)
        if ob_time lt start_time then continue
        if ob_time gt end_time then break
      endif
      print, 'reading: [', tmp, '] data ....'
      energy = fltarr(num_elems)
      v = intarr(num_elems)
      azim = fltarr(num_elems)
      elev = fltarr(num_elems)
      count = fltarr(num_elems)
      psd = dblarr(num_elems)
      
      tmp2 =''
      for i=0, num_elems-1 do begin
         readf, lun, tmp2
         tmp2_arr = strsplit(tmp2, /EXTRACT)
         energy[i] = tmp2_arr[0]
         v[i] = tmp2_arr[1]
         azim[i] = tmp2_arr[2]
         elev[i] = tmp2_arr[3]
         count[i] = tmp2_arr[4]
         psd[i] = tmp2_arr[5]
      endfor
       data[tmp] = hash('energy', energy, 'v', v, 'azim', azim, 'elev', elev, 'count', count, 'psd', psd)
      ;print, 'complete: ', tmp
    endif
    
  endwhile

  free_lun,lun

  endif else begin 
  ; Kuni 
  ; - - - - READ MMS FPI DIST DATA - - - - 
  pdf = get3d_mms_fpi_dist(trange=trange) 
  data = hash()
  for i=0,n_elements(pdf)-1 do begin 
     data[pdf[i].tstring] = hash('energy',pdf[i].energy, $ 
                 'v', pdf[i].velocity, $ 
                 'azim', pdf[i].phi, $ 
                 'elev', pdf[i].theta, $ 
                 'count', pdf[i].dist, $ 
                 'psd', pdf[i].dist) 
  endfor 
  ; - - - - - - - - - - - - - - - - - - - 
  endelse 

  
  if data.IsEmpty() then return, 0
 
  (self.stel_import_lep)['data'] = data
  tmp_keys = (data.keys()).ToArray()
  keys = tmp_keys[sort(tmp_keys)]
  (self.stel_import_lep)['keys'] = keys
  
  return, 1 ;success

end
;
;
;
function stel_import_lep::getXYZCoord, indata, ALL=all,   $
    VELOCITY=velocity, ENERGY=energy
    
  if keyword_set(velocity) and keyword_set(energy) then begin
    message, 'cannot set both VELOCITY and ENERGY keywords', /CONTINUE
    return, 0
  endif
  
  if ~keyword_set(energy) and ~keyword_set(velocity) then velocity = 1
  
  if keyword_set(all) then begin
    alldata = (self.stel_import_lep)['data']
  endif else begin
    if ~isa(indata, 'hash') or (indata.IsEmpty() eq 1 )then begin
      message, 'invalide input data', /CONTINUE
      return, 0
    endif
    ;
    ;extract data for conversion
    azim = transpose(indata['azim'])
    elev = 90-transpose(indata['elev'])
     
    if keyword_set(velocity) then begin
      v = transpose(indata['v'])
      rect_coord = cv_coord(FROM_SPHERE=[azim, elev, v], /TO_RECT, /DEGREES)
    endif
    if keyword_set(energy) then begin
      energy = transpose(indata['energy'])
      rect_coord = cv_coord(FROM_SPHERE=[azim, elev, energy], /TO_RECT, /DEGREES)
    endif
    indata['xyz'] = rect_coord
  endelse
  
  return, 1
  
end
;
; Get magnetic filed and/or velocity vector
;
function stel_import_lep::getVector, cTime, VEL=vel
@stel3d_common

;Kuni 
 goto, lab_vec
; 
   tplot_restore, FILE=in_slice
   if cTime eq !null then begin
    tmpkeys=(self.stel_import_lep)['keys']
    cTime=tmpkeys[0]
   endif
   cTime = self.checkTimeFormat(cTime)
   dTrange = time_double(self.getTrange())
   dtime = time_double(cTime)
   if dtime lt dTrange[0] or dtime gt dTrange[1] then begin
    message, 'specified time is out of range '
    return, !null
   endif
   
   if keyword_set(vel) then begin ; Velocity
;     print, 'Velocity vector'
     get_data, 'velocity', data=vel
     vel_time=vel.x
     !null= min(abs(vel_time-(time_double(cTime))[0]), pos)
     vect = (vel.y)[pos, *]
   endif else begin ; Magnetic
;     print, 'Magnetic field vector'
     get_data, 'Btotal', data=btotal
     get_data, 'Btheta', data=btheta
     get_data, 'Bphi', data=bphi
     !null= min(abs((btotal.x)-(time_double(cTime))[0]), pos)
     vect = [[(btheta.y)[pos]], [(bphi.y)[pos]], [(btotal.y)[pos]]]
   endelse
   ;
   ; convert Polar to XYX coordinate
   ;
   ;print, 'before conversion', vect
   vect =  cv_coord(FROM_SPHERE=[vect[0], vect[1], vect[2]], /TO_RECT, /DEGREES)
;Kuni 
 lab_vec:vect=[0.,0.,0.]  
   return, vect
end
;
;
;
function stel_import_lep::getTimeKeys

  if (self.stel_import_lep).HasKey('keys') then begin   
    return, (self.stel_import_lep)['keys']
  endif else begin
    message, 'no keys exists', /CONTINUE
    return, !null
  endelse
  
end
;
;
;
function stel_import_lep::getTrange

  if (self.stel_import_lep).HasKey('keys') then begin
    tmpkeys = (self.stel_import_lep)['keys']
    dTime = time_double(tmpkeys)
    dTRange = [min(dtime), max(dtime)]
    return, time_string(dTrange)
  endif else begin
    message, 'no keys exists', /CONTINUE
    return, !null
  endelse

end
;
;
;
function stel_import_lep::getOneData, time, DATA=data, ToXYZ=toxyz, KEY=key ; Polar Coord to Rec Coord
on_error, 2
;ToDo: need to improve to find the closest time

  alldata = (self.stel_import_lep)['data']
  if alldata.IsEmpty() then begin
    message, 'data is not imported', /CONTINUE
    return, 0
  endif
  
  j_time = self.convertUnixTime(time)
  t_keys = self.getTimeKeys()
  ;print, t_keys, format='(1A)'
  ;help, t_keys
  j_t_keys = self.convertUnixTime(t_keys)
  
;  pos = value_locate(j_t_keys, j_time)
;  if pos eq -1 then begin
;    message, 'time is out of range', /CONTINUE
;    return, 0
;  endif
  !null = min(abs(j_t_keys - j_time[0]), pos)

  key = t_keys[pos]
  key = key[0]
  
  if keyword_set(toxyz) then begin
    
  endif else begin
    data = alldata[key]
  endelse
    
  return, 1
end
;
;
;
function stel_import_lep::convertUnixTime, datetime

  ;Check Time format
  datetime = self.checkTimeFormat(datetime)
  unixT = time_double(datetime)
  return, unixT

end
;
;
;
pro stel_import_lep::cleanup

  if obj_valid(self.stel_import_lep) then obj_destroy, self.stel_import_lep

end
;
;
;
pro stel_import_lep__define

  struct_hide, {stel_import_lep, $
    stel_import_lep:obj_new(),   $
    dummy:'' }
  
end
;
;　Test program for stel_import_lep
;
pro test_stel_import_lep

  thm_init

  infile = file_which('19971212_lep_psd_8532.txt')
  if ~file_test(infile) then begin
    infile = dialog_pickfile(FILTER='19971212_lep_psd_8532.txt')
    if infile eq '' then return
  endif
 
  olep = stel_import_lep()
  res = olep.read_lep(infile, DATA=data, TRANGE=['1997-12-12/13:47:00', '1997-12-12/13:51:00'])
;  if res then begin
;    print, 'import is successful'
;    help, data
;    print, data.keys()
;  endif
  ;
  ;print, olep.getTimeKeys(), FORMAT='(1A)'
  print, olep.getVector()
  print, olep.getVector(/VEL)
  print, olep.getTrange()
  ;
  res = olep.getOneData('1997-12-12/13:47:11', DATA=onedata)
;  if res then begin
;    print, '-------------------------------'
;    help, onedata
;    print, onedata.keys()
;  endif
  ;
  ;convert polar to rect
  res = olep.getXYZCoord(onedata, /VEL)
  rec_coord = onedata['xyz']
  count = onedata['count']
  ;count = onedata['psd']
;  print, min(rec_coord[0,*])
;  print, max(rec_coord[0,*])
  
  op = plot3d(reform(rec_coord[0,*]), reform(rec_coord[1,*]), reform(rec_coord[2,*]), $
     'o', XTITLE='X', YTITLE='Y', ZTITLE='Z',  $
    SYM_OBJECT=cube(), RGB_TABLE=34, VERT_COLORS=BYTSCL(count))
    
  oc = colorbar(TARGET=op, ORIENTATION=1,   $
    POSITION=[0.89, 0.15,0.92,0.85], $
    TEXTPOS=1, /BORDER, RANGE=[min(count), max(count)], TITLE='COUNT')

  obj_destroy, olep

end
