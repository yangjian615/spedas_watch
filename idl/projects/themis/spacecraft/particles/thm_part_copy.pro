;+
;Procedure: thm_part_copy
;
;Purpose: Performs deep copy on particle data that is returned by thm_part_dist_array
;
;Arguments:  Old: A particle data structure to be copied
;            New: A variable name to which the particle data should be copied
;
;Keywords: error=error:  Set to named variable. Returns 0 if no error, nonzero otherwise.
;
;Usage: thm_part_copy,old,new
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2012-09-27 15:21:54 -0700 (Thu, 27 Sep 2012) $
;  $LastChangedRevision: 10956 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_copy.pro $
;-

pro thm_part_copy,old,new,error=error

  compile_opt idl2,hidden

  error = 1

  if size(old,/type) ne 10 then begin
    dprint,dlevel=1,"ERROR: old undefined or has wrong type"
    return
  endif
  
  new = ptrarr(n_elements(old))
  
  for i = 0,n_elements(old)-1l do begin
    new[i] = ptr_new(*old[i])
  endfor

  error=0


end