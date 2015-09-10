;+
;Procedure:
;  spd_slice2d_custom_rotation
;
;
;Purpose:
;  Retrieve a user-provided rotation matrix and apply to data as needed.
;
;
;Input:
;  custom_rotation:  3x3 rotation matrix or name to tplot variable containing such matrix
;  trange:  time range of the slice, tplot vars will be averaged over this range
;
;
;Output:
;  matrix:  the transformation matrix
;
;
;Input/Output (transformed if present):
;  vectors:  array of particle 3 vectors
;  bfield: b field vector 
;  vbulk: bulk velocity vector
;  sunvec: sun position vector
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_custom_rotation.pro $
;-
pro spd_slice2d_custom_rotation, $ 
                      custom_rotation=custom_rotation, $
                      trange=trange, $
              
                      vectors=vectors, $
                      
                      bfield=bfield, $
                      vbulk=vbulk, $
                      sunvec=sunvec, $
                      
                      matrix=matrix, $

                      fail=fail
    

    compile_opt idl2, hidden


  if undefined(custom_rotation) then begin
    matrix = [ [1.,0,0], [0,1,0], [0,0,1] ]
    return
  endif

  spd_slice2d_get_support, custom_rotation, trange, /matrix, output=matrix
  
  ; Check that the matrix is valid
  if total( finite(matrix,/nan) ) gt 0 then begin
    fail = 'Invalid custom rotation matrix.'
    dprint, dlevel=1, fail
    return
  endif

  ; Prevent data from being mutated to doubles
  matrix = float(matrix)

  dprint, dlevel=4, 'Applying custom rotation'

  ; Transform data and support vectors 
  if keyword_set(vectors) then vectors = matrix ## temporary(vectors)
  if keyword_set(vbulk) then vbulk = matrix ## vbulk
  if keyword_set(bfield) then bfield = matrix ## bfield
  if keyword_set(sunvec) then sunvec = matrix ## sunvec

end