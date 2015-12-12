;+
;Procedure:
;  mms_pgs_map_azimuth
;
;Purpose:
;  Map any range of azimuth values in [-inf,inf] to [0,360]
;
;Calling Sequence:
;  new_angles = thm_pgs_map_azimuth(angles)
;
;Input:
;  phi: Array of azimuth values in degrees
;
;Output:
;  return value: Input values mapped to [0,360]
;
;Notes:
;  This routine is a copy of thm_pgs_map_azimuth,  We might want to abstract so both missions use the same routine
;
;  -values of 360 will not be wrapped to zero
;   (otherwise a [0,360] range is mapped to [0,0])
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-12-11 14:25:49 -0800 (Fri, 11 Dec 2015) $
;$LastChangedRevision: 19614 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_pgs_map_azimuth.pro $
;
;-
function mms_pgs_map_azimuth, phi

    compile_opt idl2, hidden


  p = float(phi)
      
  ;map limits to +-[0,360]
  ;do not wrap multiples of 360
  pmod = p mod 360
  gtz = where(pmod ne 0, ngtz)
  if ngtz gt 0 then p[gtz] = pmod[gtz]
  
  ;wrap negative values
  ltz = where(p lt 0, nltz)
  if nltz gt 0 then p[ltz] += 360.

  return, p

end
