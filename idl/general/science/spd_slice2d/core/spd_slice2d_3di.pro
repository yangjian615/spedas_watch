;+
;Procedure:
;  spd_slice2d_3di.pro
; 
;Purpose:
;  Helper function for spd_slice2d.  Produces slice by interpolating the
;  entire data set in three dimensions then extracting a plane of values
;  using the nearest neighbor.
;           
;Input:
;  datapoints:  N elements array of data values
;  xyz:  Nx3 array of vectors
;  resolution:  Resolution (R) in points of each dimension of the output
;
;Output:
;  slice_data:  RxR array of interpolated data points
;  x/ygrid:  R element array s of x and y axis values corresponding to slice_data
;
;Notes 
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_3di.pro $
;-
pro spd_slice2d_3di, datapoints, xyz, resolution, drange=drange, $ 
                     slice=slice, xgrid=xgrid, ygrid=ygrid, $
                     fail=fail

    compile_opt idl2, hidden


  ;Error checks
  normal = [0,0,1.]
  xvec = [1.,0,0]

  ; Create cube grid
  mm = [ [minmax(xyz[*,0])], [minmax(xyz[*,1])], [minmax(xyz[*,1])] ]
  xgrid = interpol(mm[*,0], resolution)
  ygrid = interpol(mm[*,1], resolution)
  zgrid = interpol(mm[*,2], resolution)

  ; Get slice's center point
  displacement = 0.
  center = ( (normal * displacement)/(mm[1,*]-mm[0,*]) + 0.5) * resolution
  if in_set(center le 0 or center gt resolution, 1) then begin
    fail = 'Error: Slice displacement is outside the data range.'
    return
  endif  

  ; Must be copied to new variables for qhull
  x = xyz[*,0]
  y = xyz[*,1]
  z = temporary(xyz[*,2])
  
  qhull, x, y, z, th, /DELAUNAY
  
  ; Remove tetrahedra whose total velocity (centroid) is less than
  ; minimum velocity from distribution (prevents interpolation over
  ; lower energy limits)
  index = where( 1./16 * total(  x[th[0:3,*]] ,1 )^2 + $
                 1./16 * total(  y[th[0:3,*]] ,1 )^2 + $
                 1./16 * total(  z[th[0:3,*]] ,1 )^2  $
                  gt min(x^2+y^2+z^2), $
                  count, ncomplement=ncomp)
  if count gt 0 then begin
    if ncomp gt 0 then begin
      th=th[*,index]
    endif
  endif else begin
    fail = 'Unknown error in triangulation; cannot interpolate data.'
    return
  endelse 

  ; Interpolate data to regular 3D grid
  vol = qgrid3(x, y, z, datapoints, th, dimension=replicate(resolution,3))
  
  ; Remove erroneous data points (also helps prevent interpolation over gaps)
  derp = where(abs(vol) lt drange[0] or abs(vol) gt drange[1], nderp)
  if nderp gt 0 then begin
    vol[derp] = 0
  endif 

  ; Extract slice from regular grid
  slice = extract_slice(vol, resolution, resolution, $
                        center[0], center[1], center[2], $
                        normal, xvec, /sample)

end
