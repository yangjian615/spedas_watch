
;+
;Procedure:
;  thm_part_checkbins
;
;Purpose:
;  Checks for changes compatability between distributions and returns boolean. 
;
;
;Input:
;  dist1: 3D particle data structure
;  dist2: 3D particle data structure
;  
;
;Output:
;  return value: (bool) 1 if all fields match, 0 otherwise
;  msg: string describing which fields differed
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-11-12 16:55:16 -0800 (Tue, 12 Nov 2013) $
;$LastChangedRevision: 13529 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_checkbins.pro $
;
;-
function thm_part_checkbins, dist1, dist2, msg=msg

    compile_opt idl2, hidden

  diff = ''
  
  if ~array_equal(dist1.theta, dist2.theta) then diff += 'THETA '
  if ~array_equal(dist1.phi, dist2.phi) then diff += 'THETA '
  if ~array_equal(dist1.energy, dist2.energy) then diff += 'ENERGY '
  if dist1.mass ne dist2.mass then diff += 'MASS '
  
  if diff ne '' then begin
    diff = strjoin(strsplit(diff,/extract),', ')
    msg = diff+' values differ between distributions at '+ $
           time_string(dist1.time)+' and '+time_string(dist2.time)
    return, 0b
  endif

  return, 1b

end
