;+
;
;Name: is_num
;
;Purpose: determines if input string is a validly formatted number.  Does
;
;Inputs: s:  the string to be checked
;
;Outputs: 1: if it is validly formatted
;         0: if it is not
;         
;Keywords: sci_notation: add support for scientific notation (3*10^6)
;
;Notes:  Does not consider numbers in complex notation or numbers with trailing type codes to be valid.
;
;Examples:
;   print,is_numeric('1')
;   1
;   print,is_numeric('1.23e45')
;   1
;   print,is_numeric('1.2c34')
;   0
;   print,is_numeric('1B')
;   0
;   print,is_numeric('-1.23d-3')
;   1
;   print,is_numeric('5e+4')
;   1
;   print,is_numeric('5.e2')
;   1
;   print,is_numeric('5.e3.2')
;   0
;   
;   Examples using scientific notation:
;   print,is_numeric('4*10^2', /sci)
;   1
;   print,is_numeric('4*10^-6', /sci)
;   1
;   print,is_numeric('4*10^(-12)', /sci)
;   1
;   print,is_numeric('12.3*10^2', /sci)
;   1
;   print,is_numeric('10^-2.2', /sci)
;   1
;   print,is_numeric('10.^-2.2', /sci)
;   1
;   print,is_numeric('12.3*10^', /sci)
;   0
;   print,is_numeric('12.3*', /sci)
;   0
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2013-05-23 14:12:09 -0700 (Thu, 23 May 2013) $
; $LastChangedRevision: 12405 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/is_numeric.pro $
;-

function is_numeric,s, sci_notation=sci_notation
  if ~keyword_set(sci_notation) then begin
    ; old regex, before adding support for scientific notation (3*10^6)
    return,stregex(strtrim(s,2),'^[-+]?(([0-9]+\.?[0-9]*)|([0-9]*\.?[0-9]+))([EeDd][-+]?[0-9]+)?$') eq 0
  endif else begin
    if s eq '' then return, 0
    return,stregex(strtrim(s,2),'^[-+]?([0-9.]*\.?[0-9.]*|([0-9.]*\*?[0-9.]+)|([0-9]*\.?[0-9]+))(([EeDd][-+]?[0-9]+)|(\*?[0-9\.?]+(\^)?[(]*[+-]?[0-9\.?]+[)]*))?$') eq 0
  endelse
end
