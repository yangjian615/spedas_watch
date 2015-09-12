;+
;Procedure:
;  spd_slice2d_get_ebounds
;
;
;Purpose:
;  Returns an array of gapless energy boundaries.  The number of 
;  elements returned will always be N+1 for N energy levels.
;
;
;Input:
;  dist: 3D particle data structure
;
;
;Output:
;  return value: Array of energy bin boundaries (# energy bins + 1)
;
;
;Notes:
;  Energy levels may be ordered differently between instruments
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-10 18:59:05 -0700 (Thu, 10 Sep 2015) $
;$LastChangedRevision: 18767 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_get_ebounds.pro $
;-
function spd_slice2d_get_ebounds, dist

    compile_opt idl2, hidden

  n = dimen1(dist.energy)

  energies = fltarr(size(dist.energy,/dim)+[1,0])
  
  ; use midpoints
  energies[1:n-1,*] = (dist.energy[0:n-2,*] + dist.energy[1:n-1,*]) / 2.
  
  ; top/bottom energies
  energies[0,*] = dist.energy[0,*] + (dist.energy[0,*] - energies[1,*])
  energies[n,*] = dist.energy[n-1,*] + (dist.energy[n-1,*] - energies[n-1,*])
  
  return, energies
  
end
