; NAME: eva_sitl_strct_read
; PURPOSE: Read a FOM or BAK structure and generate a tplot data stucture, i.e. D = {x:fom_x, y:fom_y}
; INPUT: 
;   s: stucture (either FOMstr or BAKstr)
;   tstart: the start time
;   
; $LastChangedBy: moka $
; $LastChangedDate: 2015-03-25 22:36:45 -0700 (Wed, 25 Mar 2015) $
; $LastChangedRevision: 17189 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_strct_read.pro $
Function eva_sitl_strct_read, s, tstart, $
  isPending=isPending, inPlaylist=inPlaylist, status=status, exclude_deleted=exclude_deleted
  
  if n_elements(exclude_deleted) eq 0 then exclude_deleted=1
  if n_elements(status) eq 0 then status = '' else status = strlowcase(status)
  
  
  ; determine FOMStr or BAKStr
  tn = tag_names(s)
  idx = where(strpos(tn,'FOMSLOPE') ge 0, ct); ct > 0 if FOMStr
  typeFOM = (ct gt 0)  
  if typeFOM then NSegs = s.Nsegs else Nsegs = n_elements(s.FOM)
  
  fom_x = [tstart]
  fom_y = 0.0
  if typeFOM then begin
    ; The last cycle (buffer) number of the last segment should not be equal to NUMCYCLES
    if s.STOP[Nsegs-1] ge s.NUMCYCLES then message,'Something is wrong'
    for N=0,Nsegs-1 do begin
      ss = s.TIMESTAMPS[s.START[N]]; segment start time
      se = s.TIMESTAMPS[s.STOP[N]+1]; segment stop time
      fv = s.FOM[N]; segment FOM value
      fom_x = [fom_x, ss, ss, se, se]
      fom_y = [fom_y, 0., fv, fv, 0.]
    endfor 
  endif else begin
    for N=0,Nsegs-1 do begin
      OK = 1
      if keyword_set(isPending) then OK *= s.ISPENDING[N]
      if keyword_set(inPlaylist)then OK *= s.INPLAYLIST[N]
      if strlen(status) gt 1    then OK *= strmatch(strlowcase(s.STATUS[N]),status)
      if keyword_set(exclude_deleted) then OK *= ~(strpos(strlowcase(s.STATUS[N]),'deleted') ge 0)
      if OK then begin
        ss = double(s.START[N])
        se = double(s.STOP[N])
        fv = s.FOM[N]
        fom_x = [fom_x, ss, ss, se, se]
        fom_y = [fom_y, 0., fv, fv, 0.]
      endif
    endfor
  endelse
  
  D = {x:fom_x, y:fom_y}
  
  return, D
End
