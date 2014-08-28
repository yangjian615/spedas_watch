; + 
;FUNCTION array_concat
;PURPOSE:
;  Performs array concatenation in a way that handles an empty list.
;  Simple code that gets duplicated everywhere.
;
;Inputs:
;  arg: The argument to be concatenated
;  array: The array to which it should be concatenated, or nothing
;  
;Output:
;  array + arg
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2013-10-21 15:49:38 -0700 (Mon, 21 Oct 2013) $
;$LastChangedRevision: 13358 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/array_concat.pro $
;
; -

function array_concat,arg,array

  compile_opt idl2
  
  if undefined(array) then begin ;trying a *hopefully*, more reliable and more legible test-pcruce 2013-01-30
 ; if ~is_array(array) && ~keyword_set(array) then begin
    return,[arg]
  endif else begin
    return,[array,arg]
  endelse

end

