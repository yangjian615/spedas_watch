;+
;FUNCTION:   mvn_swe_padsum
;PURPOSE:
;  Sums multiple PAD data structures.  This is done by summing raw counts
;  corrected by deadtime and then setting dtc to unity.  Also, note that 
;  summed PAD's can be "blurred" by a changing magnetic field direction, 
;  so summing only makes sense for short intervals.  The theta, phi, and 
;  omega tags can be hopelessly confused if the MAG direction changes much.
;
;USAGE:
;  padsum = mvn_swe_padsum(pad)
;
;INPUTS:
;       pad:           An array of PAD structures to sum.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-02-05 15:58:38 -0800 (Thu, 05 Feb 2015) $
; $LastChangedRevision: 16890 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padsum.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_padsum.pro
;-
function mvn_swe_padsum, pad

  if (size(pad,/type) ne 8) then return, 0
  if (n_elements(pad) eq 1) then return, pad

  old_units = pad[0].units_name  
  mvn_swe_convert_units, pad, 'counts'     ; convert to raw counts
  padsum = pad[0]
  npts = n_elements(pad)

  padsum.met = mean(pad.met)
  padsum.time = mean(pad.time)
  padsum.end_time = max(pad.end_time)
  tmin = min(pad.time, max=tmax)
  padsum.delta_t = (tmax - tmin) > pad[0].delta_t
  padsum.dt_arr = total(pad.dt_arr,3)      ; normalization for the sum
    
  padsum.pa = total(pad.pa,3)/float(npts)         ; pitch angles can be blurred
  padsum.dpa = total(pad.dpa,3)/float(npts)
    
  padsum.sc_pot = mean(pad.sc_pot)
  padsum.Baz = mean(pad.Baz)
  padsum.Bel = mean(pad.Bel)
    
  padsum.magf = total(pad.magf,2)/float(npts)
  padsum.v_flow = total(pad.v_flow,2)/float(npts)
  padsum.bkg = mean(pad.bkg)

  padsum.data = total(pad.data/pad.dtc,3)  ; corrected counts
  padsum.var = total(pad.var/pad.dtc,3)    ; variance
  padsum.dtc = 1.         ; summing corrected counts is not reversible
  
  mvn_swe_convert_units, pad, old_units
  mvn_swe_convert_units, padsum, old_units

  return, padsum

end
