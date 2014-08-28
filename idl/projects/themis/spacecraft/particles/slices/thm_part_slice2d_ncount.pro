
;+
;Procedure:
;  thm_part_slice2d_ncount
;
;Purpose:
;  Helper function for thm_part_slice2d_getxyz
;  Converts one count value to requested units and returns converted data array.
;
;Input:
;  dat: 3d data structure to be used
;  units: string describing new units
;
;Output:
;  return value: array of data corresponding to the specified number of counts
;
;Notes:
;
;
;$LastChangedBy: aaflores1 $
;$LastChangedDate: 2014-01-31 18:35:43 -0800 (Fri, 31 Jan 2014) $
;$LastChangedRevision: 14112 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice2d_ncount.pro $
;
;-
function thm_part_slice2d_ncount, dat, units, threshold

    compile_opt idl2, hidden


  ;ensure data is in counts
  ;( 2013-02-25 This conversion seems unnecessary as the "data" tag 
  ;  is the only element of the structure altered by this conversion ) 
  if strlowcase(dat.units_name) ne 'counts' then begin
    cdat = conv_units(dat,'counts')
    if strlowcase(cdat.units_name) ne 'counts' then begin
      dprint, dlevel=0, 'WARNING: Error converting units, one-count level cannot be calculated for the current data.' 
      return, 0
    endif
  endif else begin
    cdat = dat
  endelse
  
  cdat.data[*,*] = threshold

  cdat = conv_units(temporary(cdat),strlowcase(units))
  
  if keyword_set(regrid) then begin
     thm_part_slice2d_regridxyz, cdat, 2, regrid=regrid, data=cnt, fail=fail
  endif
  
  return, cdat.data
      
end

