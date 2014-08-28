


;+
; Determined whether data is ion or electron from name.
; This is probably not the best way
;-
function thm_part_slice1d_type, dname

    compile_opt idl2, hidden
  
  type = 'unknown'
  
  if stregex(dname, 'sst', /fold_case, /bool) then begin
  
    ;keep "distribution" from being matched 
    if stregex(dname, ' ion ', /fold_case, /bool) then begin
      type = 'i'
    endif else if stregex(dname, 'electron', /fold_case, /bool) then begin
      type = 'e'
    endif
  
  endif else if stregex(dname, 'eesa', /fold_case, /bool) then begin
     type = 'e'
  endif else if stregex(dname, 'iesa', /fold_case, /bool) then begin
     type = 'i'
  endif

  return, type

end


;+
; Produce set of points to interpolate at for linear cuts
;
;-
pro thm_part_slice1d_xy, slice, $
                         xin=x0, yin=y0, angle=angle, $
                         xout=x, yout=y, $
                         xaxis=xaxis, xtitle=xtitle, $
                         error=error

    compile_opt idl2, hidden

  
  error = 1b
  
  
  n = n_elements(slice.xgrid)
  
  
  ;Get values at which to interpolate data
  ;---------------------------------------
  
  ;get coordinates and for  vertical cuts
  if ~undefined(x0) then begin

    x = x0
    y = interpol( minmax(slice.ygrid), 3*n)

  ;get coordinates and for horizontal cuts
  endif else begin
    
    if undefined(y0) then y0 = 0
    
    x = interpol( minmax(slice.xgrid), 3*n)
    y = y0
    
  endelse
  

  ;rotate indices to get off-axis cuts
  if keyword_set(angle) then begin
    
    ;pad indices to cover entire plot area after rotating
    if n_elements(x) gt 1 then begin

      ;create array with equal spacing
      pad = median(x - shift(x,1)) * (findgen(n/2.) + 1)
      x = [ min(x) - reverse(pad), x, max(x) + pad ]

    endif else begin

      ;create array with equal spacing
      pad = median(y - shift(y,1)) * (findgen(n/2.) + 1)
      y = [ min(y) - reverse(pad), y, max(y) + pad ]

    endelse
    
    ;convert to polar
    r = sqrt(x^2 + y^2)
    theta = atan(y,x)
    
    ;rotate by specified angle
    theta += angle * !pi/180.
    
    ;convert to cartesian
    x = cos(theta) * r
    y = sin(theta) * r
    
  endif
  

  ;Get plot axis and annotations
  ;--------------------

  ;check if x or y was requested
  if ~undefined(x0) then begin
    alignment = 'x=' + strtrim(x0,2)
    axis = 'y'
    xaxis = y
  endif else begin
    alignment = 'y=' + strtrim(y0,2)
    axis = 'x'
    xaxis = x
  endelse

  ;adjust annotations and xaxis if the cut was rotated
  if keyword_set(angle) then begin
    alignment += ', ' + ((angle gt 0) ? '+':'') + strtrim(angle,2)
    axis = ''
    
    ;keep sign of original axis
    if ~undefined(x0) then begin
      sign = -1 * (y lt 0) + (y ge 0)
    endif else begin
      sign = -1 * (x lt 0) + (x ge 0)
    endelse
    
    xaxis = sqrt(x^2 + y^2) * sign
    
  endif
  
  xtitle = 'V' + axis + ' (' + alignment + ')' + $
           '  (' + strupcase(slice.rot) + ', ' + $
           strupcase(slice.coord) + ')' + $
           ' (km/s)'

  
  error = 0b
  
end


;+
; Produce set of points to interpolate at for radial cuts
;
;-
pro thm_part_slice1d_v, slice, $
                        vin=v0, ein=e0, $
                        xout=x, yout=y, $
                        xaxis=xaxis, xtitle=xtitle, $
                        error=error

    compile_opt idl2, hidden


  error = 1b


  ;Get values at which to interpolate data
  ;---------------------------------------

  thm_part_slice2d_const, c=c

  ;cuts specified by velocity
  if ~undefined(v0) then begin

    v = v0

  ;cuts specified by energy
  endif else if ~undefined(e0) then begin
    
    if ~finite(slice.mass) then begin
      dprint, dlevel=0, 'Invalid mass in slice structure, cannot convert energy to velocity.  '+ $
                        '2D slice input may have had variable mass.'
      return
    endif
    
    er = slice.mass * c^2 / 1e6 ;  eV/(km/s)^2 -> eV/c^2
    v = float( c * sqrt( 1 - 1/((e0/er + 1)^2) ) )
    v = v / 1000. ; m/s -> km/s
    
  endif else begin
    
    ;TODO: have default cut?
    return
    
  endelse


  ;number of points
  nv = 3*n_elements(slice.xgrid)

  ;theta values
  t = 2 * !pi * findgen(nv)/nv

  ;cartesian values
  x = v * cos(t)
  y = v * sin(t)


  ;Get plot axis and annotations
  ;--------------------
  
  ;get plot's x axis
  xaxis = 180/!pi * t
  
  ;x axis title
  xtitle = ' V=' + strtrim(v,2) + $
           '  (' + strupcase(slice.rot) + $
           ', ' + strupcase(slice.coord) + ') (km/s)'
  

  error = 0b

end




;+
;Procedure:
;  thm_part_slice1d.pro
;
;Purpose:
;  Produce line plots from particle velocity slices along various orientations.
;  
;Calling Sequence:
;  thm_part_slice1d, slice, [,xcut=xcut | ,ycut=ycut | ,vcut=vcut | ,ecut=ecut ]
;                           [,angle=angle] [,/overplot] [,data=data]
;
;Input:
;     slice: slice structure from thm_part_slice2d
;         x: value at which to align cut along the x axis (km/s)
;         y: value at which to align cut along the y axis (km/s)
;            (defaults to y=0 if x, y, v, e not set)
;         v: value at which to align a radial cut (km/s)
;         e: value at which to align a radial cut (eV)
;     angle: value (degrees) to rotate the cut by if using x or y
;  overplot: flag to add trace to the previous plot
;  
;  *IDL graphics keywords may also be used; see IDL documentation for usage.
;   (e.g. color, psym, linestyle)
;
;Output:
;  data: set this keyword to a named variable to return a structure
;        containing the data for the specified cut
;
;Notes:
;  Crib coming soon.
;   
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-10-24 13:15:54 -0700 (Thu, 24 Oct 2013) $
;$LastChangedRevision: 13391 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice1d.pro $
;
;-

pro thm_part_slice1d, slice, $
                      ; output type keywords
                      xcut=x0, ycut=y0, angle=angle, $
                      vcut=v0, ecut=e0, $
                      ; plotting keywords
                      xrange=xrange0, $
                      yrange=yrange0, $
                      overplot=overplot, $
                      ; other
                      data=data, $
                      error=error, $
                      _extra=_extra

    compile_opt idl2, hidden


  error = 1b
  
  
  if ~is_struct(slice) then begin
    dprint, dlevel=1, 'Input must be slice structure from thm_part_slice2d'
    return
  endif
  

  ;Construct the set of points the data will be interpolated to.
  if ~undefined(v0) or ~undefined(e0) then begin

    ;Get values & labels for radial cuts
    thm_part_slice1d_v, slice, vin=v0, ein=e0, $
                        xout=x, yout=y, xaxis=xaxis, xtitle=xtitle, $
                        error=sub_error
  
  endif else begin
    
    ;Get values & labels for linear cuts
    thm_part_slice1d_xy, slice, xin=x0, yin=y0, angle=angle, $
                         xout=x, yout=y, xaxis=xaxis, xtitle=xtitle, $
                         error=sub_error
  endelse
  
  ;handle error from helper routine
  if keyword_set(sub_error) then return


  ;Get indices to the slice data corresponding to the points determined above
  n = n_elements(slice.xgrid)
  xi = interpol( findgen(n), slice.xgrid, x )
  yi = interpol( findgen(n), slice.ygrid, y ) 


  ;Ensure equal elements in x and y arrays
  ; -important for linear cuts, 
  if n_elements(xi) eq 1 then xi = replicate(xi,n_elements(y))
  if n_elements(yi) eq 1 then yi = replicate(yi,n_elements(x))
  if n_elements(xi) ne n_elements(yi) then begin
    dprint, dlevel=0, 'Error generating coordinates for 1D cut.'
    return
  endif
  

  ;Remove indices outside the plot's range
  ; -primarily here to remove excess points for rotated linear cuts
  idx = where( xi ge 0 and xi le n and $
               yi ge 0 and yi le n ,c )
  if c gt 0 then begin
    xi = xi[idx]
    yi = yi[idx]
    xaxis = xaxis[idx]
  endif else begin
    dprint, dlevel=1, 'The requested cut does not intersect plot."
    return
  endelse


  ;Interpolate at the calculated set of indicies
  ; (this is the data that will be plotted)
  line = reform(  interpolate(slice.data, xi, yi)  )


  ;Annotations for plotting
  title = 'th'+strlowcase(slice.probe)+' ' + $
          strjoin(slice.dist,'/') + $
          ' ('+strupcase(slice.rot)+') ' + $
          time_string(slice.trange[0]) + $
          ' -> '+strmid(time_string(slice.trange[1]),11,8)
  xtitle = xtitle ;determined above
  ytitle = units_string(strlowcase(slice.units))
  
  
  xrange = keyword_set(xrange0) ? xrange0:minmax(xaxis)
  yrange = keyword_set(yrange0) ? yrange0:slice.range
  

  ;Plot
  ; -graphics keywords are passed through _extra
  ;  keyword to plot/oplot
  ; -keywords passed through _extra will supercede
  ;  keywords explicitly named in a call (IDL feature)
  thm_part_slice1d_plot, xaxis, line, $
                         overplot=overplot, $
                         title=title, $
                         xtitle=xtitle, $
                         ytitle=ytitle, $
                         xrange=xrange, $
                         yrange=yrange, $
                         _extra=_extra


  ;Return data if requested
  if arg_present(data) then begin
    data = {x:xaxis, $
            y:line, $
            xrange: xrange, $
            yrange: yrange, $
            xtitle: xtitle, $ 
            ytitle: units_string(strlowcase(slice.units)), $
            title: title}
  endif


  error = 0b


  return
  
end


