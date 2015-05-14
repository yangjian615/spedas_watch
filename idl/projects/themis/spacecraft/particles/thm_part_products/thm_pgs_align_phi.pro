;+
;Procedure:
;  thm_pgs_align_phi
;
;Purpose:
;  Align phi bins with respect to energy in order to reduce 
;  fringing artifacts on field aligned spectrograms.
;
;
;Input:
;  data: single sanitized data structure
;  
;
;Output:
;  -Phi values in DATA will be averaged across energy.
;  -If the inter-energy phi difference is too large for an
;   accurate average over energy then an error will be thrown.
;   (Hopefully this will never happen, if it does a more
;    sofisticated algorithm will be needed)
;  
;
;Notes:
;  -sigh
;   
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 11:46:39 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17589 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_align_phi.pro $
;-

pro thm_pgs_align_phi, data

    compile_opt idl2, hidden


  dr = !pi/180.

  ;convert phi values to complex #s
  a = cos(data.phi*dr)
  b = sin(data.phi*dr)
  cphi = complex(a,b)

  ;average in complex space to avoid 0=360 discontinuity
  cmean = mean(cphi, dimension=1)
  cmean = cmean ## replicate(1,dimen1(data.phi))
 
  ;normalize complex mean so we can compare angular distances
  cr = sqrt( real_part(cmean)^2 + imaginary(cmean)^2)
  c =  real_part(cmean)/cr
  d = imaginary(cmean)/cr

  ;calculate angular distances between mean and original values with dot product
  ;this asumes a + bi and c + di are unit vectors in complex space 
  dphi = acos( a*c + b*d ) / dr
  
  ;convert complex averages to degrees
  mean = atan( d, c ) / dr

  ;recalc original angles (for testing only)
;  phi = atan( b, a) / dr

  ;Warn if the separation between the mean bin center and any original 
  ;center exceeds the size of the bin.  If so then this algorithm will 
  ;need to be modified to adjust the data accordingly; probably via
  ;spherical interpolation.
  if total( dphi gt 0.5*data.dphi ) gt 0 then begin
  
    message, 'Difference in phi values between energies is too large '+ $
             'to allow accurate averaging.
  
  endif else begin
  
    ;replace orginal values with averages for each energy
    data.phi = mean
  
  endelse
  
  
end