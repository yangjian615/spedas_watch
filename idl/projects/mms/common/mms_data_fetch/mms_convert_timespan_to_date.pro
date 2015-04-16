; Function: MMS_CONVERT_TIMESPAN_TO_DATE
;
; PURPOSE: Call after calling 'timespan' procedure in TDAS to get 
; start and end date strings (YYYY-MM-DD) that MMS SDC expects
;
; KEYWORDS:
;
;   hour            - OPTIONAL. Call '/hour' to output dates in the
;                     form YYYY-MM-DD-HH. Useful for burst data and
;                     sitl files.
;
; HISTORY:
;
; 2015-04-14, FDW, useful for interfacing TDAS with SDC.
; 
; LASP, University of Colorado

; MODIFICATION HISTORY:
;
;
;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-04-14 13:27:13 -0700 (Tue, 14 Apr 2015) $
;  $LastChangedRevision: 17312 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_data_fetch/mms_convert_timespan_to_date.pro $

;


function mms_convert_timespan_to_date, hour=hour

t = timerange(/current)
st = time_string(t)
start_date = strmid(st[0],0,10)
end_date = strmatch(strmid(st[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(st[1],0,10)

if keyword_set(hour) then begin
  start_hour = strmid(st[0], 11, 2)
  end_hour = strmid(st[1], 11, 2)
  start_date += '-'
  start_date += start_hour
  end_date += '-'
  end_date += end_hour
endif

outstruct = {start_date: start_date, $
              end_date: end_date}
              
return, outstruct

end