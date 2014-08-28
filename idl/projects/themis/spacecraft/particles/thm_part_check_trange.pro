
; Checks if a list of times covers a time range
;
function thm_check_tr, tr, times, margin=margin

    compile_opt idl2, hidden
  
  if n_elements(times) lt 2 then return, 0
  
  if undefined(margin) then begin
    margin = median(  (times - shift(times,1))[1:n_elements(times)-1]  )
  endif
  
  return,  (min(times)-margin) le min(tr) && (max(times)+margin) ge max(tr) 

end


; Checks for presence of SST data within a given time range
;
function thm_check_sst_data, probe, datatype, trange, sst_cal=sst_cal, fail=fail

    compile_opt idl2, hidden


  r = 0
  
  
  if keyword_set(sst_cal) then begin
  
    times = thm_part_dist2('th'+probe+'_'+datatype, /times)
  
  endif else begin
  
    times = call_function('thm_sst_'+datatype, probe=probe, /time)
  
  endelse
  
  
  if times[0] ne 0 then begin
  
    r = thm_check_tr(trange, times)
    
  endif
  
  
  return, r
  
end


; Checks for presence of ESA data withing a given time range
;
function thm_check_esa_data, probe, datatype, trange, fail=fail

    compile_opt idl2, hidden


  r = 0

  times = call_function('get_th'+probe+'_'+datatype, /time)

  if size(times,/type) ne 8 && times[0] ne 0 then begin
  
    r = thm_check_tr(trange, times)
  
  endif

  return, r
  
end


;+
;NAME:
;  thm_part_check_trange
;
;PURPOSE:
;  This routine checks the time ranges of the current ESA and SST  
;  data stored in the common blocks to determine if it covers a
;  particular time range.
;
;CALLING SEQUENCE:
;  bool = thm_part_check_trange(probe, datatype, trange, [sst_cal=sst_cal], [fail=fail])
;
;KEYWORDS:
;  probe: String or string array specifying the probe
;  datatype: String or string array specifying the type of 
;        particle data requested (e.g. 'peif', 'pseb')
;  trange: Two element array specifying the numeric time range
;  sst_cal: Flag to check data from new SST calibrations
;  fail: Set to named variable to pass out error messages (string)
;
;OUTPUT:
;  1 if current data covers what is requested, 0 otherwise
;
;NOTES: 
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-09-10 17:23:36 -0700 (Tue, 10 Sep 2013) $
;$LastChangedRevision: 13018 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_check_trange.pro $
;-
function thm_part_check_trange, probe0, datatype0, trange, sst_cal=sst_cal, fail=fail

    compile_opt idl2, hidden


  r = 0

  if undefined(probe0) or undefined(datatype0) or undefined(trange) then begin
    fail = 'Missing required input; must specify probe, data type, and time range'
    return, 0
  endif

  probe = strlowcase(probe0)
  datatype = strlowcase(datatype0)
  
  ;check probe input
  valid = where( stregex(probe, '[abcde]', /bool), np)
  if np gt 0 then begin
    probe = probe[valid]
  endif else begin
    fail = 'No valid probe(s)'
    return, 0
  endelse
  
  ;check data type input
  valid = where( stregex(datatype, '^p[se][ei][rfb]$', /bool), nv)
  if nv gt 0 then begin
    datatype = datatype[valid]
  endif else begin
    fail = 'No valid data type(s)'
    return, 0
  endelse

  ;check trange input
  if n_elements(trange) lt 2 then begin
    fail = 'Time range must be two elements'
    return, 0
  endif  
  
  
  ;loop over probe and data type
  for j=0, n_elements(probe)-1 do begin
    for i=0, n_elements(datatype)-1 do begin
  
      if strmid(datatype[i],1,1) eq 'e' then begin
      
        r = thm_check_esa_data(probe[j], datatype[i], trange, fail=fail)
      
      endif else if strmid(datatype[i],1,1) eq 's' then begin
      
        r = thm_check_sst_data(probe[j], datatype[i], trange, sst_cal=sst_cal, fail=fail)
      
      endif
  
      if r eq 0 then return,0
  
    endfor
  endfor

  return, 1

end
