;+
;FUNCTION: time_parse
;PURPOSE:
;  Parse a string or array of strings into double precision seconds since 1970 using
;    user provided format code. 
;
;INPUTS:
;  s : the input string or array of strings
;  
;KEYWORDS:
;  tformat=tformat:  Format string such as "YYYY-MM-DD/hh:mm:ss" (Default)
;               the following tokens are recognized:
;                    YYYY  - 4 digit year
;                    yy    - 2 digit year (00-69 assumed to be 2000-2069, 70-99 assumed to be 1970-1999)
;                    MM    - 2 digit month
;                    DD    - 2 digit date
;                    hh    - 2 digit hour
;                    mm    - 2 digit minute
;                    ss    - 2 digit seconds
;                    .fff   - fractional seconds (can be repeated, e.g. .f,.ff,.fff,.ffff, etc... are all acceptable codes)
;                    MTH   - 3 character month
;                    DOY   - 3 character Day of Year
;                    TDIFF - 5 character, +hhmm or -hhmm different from UTC (sign required)
;               tformat is case sensitive!
;
; tdiff=tdiff: Offset in hours.  Array or scalar acceptable.
;              If your input times are not UTC and offset 
;              is not specified in the time string itself,
;              use this keyword.
;              
;Examples:
;
;NOTES:
;  #1 Some format combinations can conflict and may lead to unpredictable behavior. (e.g. "YYYY-MM-MTH") 
;  #2 Primarily intended as a helper routine for time_double and time_struct
;  #3 letter codes are case insensitive.
;  #4 Based heavily on str2time by Davin Larson.
; 
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-02-07 17:38:36 -0800 (Fri, 07 Feb 2014) $
;$LastChangedRevision: 14209 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/time_parse.pro $
;-

function time_parse,s, tformat=tformat,tdiff=tdiff

  compile_opt idl2
  
  months= ['JAN','FEB','MAR','APR', 'MAY', 'JUN', 'JUL', 'AUG','SEP','OCT','NOV','DEC']
  
  if undefined(tformat) then begin
    tformat = "YYYY-MM-DD/hh:mm:ss"
  endif

  ns = n_elements(s)
  str = replicate(time_struct(0d),ns)
  
  year = 0
  p = strpos(tformat,'yy')
  
  if p ge 0 then begin
    year = fix(strmid(s,p,2))
    year +=  1900*(year ge 70) +2000 *(year lt 70)
  endif
  
  p = strpos(tformat,'YYYY')
  if p ge 0 then begin
     year = fix(strmid(s,p,4))
  endif
  
  str.year = year
  
  p = strpos(tformat,'MM')
  if p ge 0 then begin
    str.month = fix(strmid(s,p,2))
  endif
  
  p = strpos(tformat,'MTH')
  
  for i = 0,11 do begin
    idx = where(months[i] eq strupcase(strmid(s,p,3)),c)
    if c gt 0 then begin
      str[idx].month = i+1
    endif
  endfor
  
  p = strpos(tformat,'DD')
  if p ge 0 then str.date = fix(strmid(s,p,2))
  
  p = strpos(tformat,'DOY')
  if p ge 0 then begin
    doy_to_month_date,str.year,fix(strmid(s,p,3)),month,date
    str.month = month
    str.date = date
  endif
  
  p = strpos(tformat,'hh')
  if p ge 0 then str.hour = fix(strmid(s,p,2))
  
  p = strpos(tformat,'mm')
  if p ge 0 then str.min = fix(strmid(s,p,2))
  
  p = strpos(tformat,'ss')
  if p ge 0 then str.sec = fix(strmid(s,p,2))
  
  token='.'
  repeat begin
    token = token +'f'
    p = strpos(tformat, token )
  endrep until strpos(tformat,token+'f') lt 0
  if p ge 0 then str.fsec = double(strmid(s,p,strlen(token)))
    
  if undefined(tdiff) then begin
    tdiff = 0
  endif
  
  tdiff_sec = tdiff * 60. * 60.
    
  p = strpos(tformat,'TDIFF')
  if p gt 0 then begin
    tdiff_hr = fix(strmid(s,p,3))
    tdiff_min = fix(strmid(s,p+3,2))
    tdiff_sec = tdiff_hr * 60. * 60. + tdiff_min * 60. 
  endif
    
  return,time_double(str) - tdiff_sec
    
end