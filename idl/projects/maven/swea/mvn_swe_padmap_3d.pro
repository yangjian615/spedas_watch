;+
;PROCEDURE: 
;	mvn_swe_padmap_3d
;
;PURPOSE:
;	Map pitch angle for 3D distributions.  Also works for PAD data structures.
;
;CALLING SEQUENCE: 
;	mvn_swe_padmap_3d, ddd
;
;INPUTS: 
;   An array of 3D structures.  The results are added as structure elements to
;   the input structure.
;
;KEYWORDS:
;   RESULT:    Returns more detailed results.
;
;CREATED BY:      D.L. Mitchell on 2014-09-24.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-07-15 11:45:34 -0700 (Wed, 15 Jul 2015) $
; $LastChangedRevision: 18137 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap_3d.pro $
;
;-
pro mvn_swe_padmap_3d, data, pam=pam

  @mvn_swe_com

  str_element, data, 'magf', magf, success=ok
  if (not ok) then begin
    print,"No magnetic field in structure!"
    return
  endif
  
  amp = sqrt(total(magf*magf,1))

  if (min(amp,/nan) lt 0.001) then begin
    print,"Magnetic field is zero!"
    return
  endif
  
  twopi = 2D*!dpi
  ddtor = !dpi/180D
  ddtors = replicate(ddtor, 64)
  n = 17  ; patch size - odd integer
  nbins = data[0].nbins

  nrec = n_elements(data)

  for m=0L,(nrec-1L) do begin
    magu = magf[*,m]/amp[m]  ; unit vector in direction of B
     
    group = data.group
    Baz = atan(magu[1], magu[0])
    if (Baz lt 0.) then Baz += twopi
    Bel = asin(magu[2])

    if (nbins eq 96) then begin
      k = indgen(96)
      i = k mod 16
      j = k / 16
    endif else begin
      k = data[m].k3d
      i = data[m].iaz
      j = data[m].jel
    endelse

    daz = double((indgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
    Saz = reform(replicate(1D,n*n) # double(swe_az[i]) + daz, n*n*nbins) # ddtors

    Sel = dblarr(n*n*nbins, 64)
    for l=0,63 do begin
      del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,l,group])
      Sel[*,l] = reform(replicate(1D,n*n) # double(swe_el[j,l,group]) + del, n*n*nbins)
    endfor
    Sel = Sel*ddtor

    Saz = reform(Saz, n*n, nbins, 64) ; nxn az-el patch, nbins pitch angle bins, 64 energies     
    Sel = reform(Sel, n*n, nbins, 64)
    pam = acos(cos(Saz - Baz)*cos(Sel)*cos(Bel) + sin(Sel)*sin(Bel))
     
    pa = average(pam, 1)      ; mean pitch angle
    pa_min = min(pam, dim=1)  ; minimum pitch angle
    pa_max = max(pam, dim=1)  ; maximum pitch angle
    dpa = pa_max - pa_min     ; pitch angle range
     
; Package the result

    pam = { pa     : FLOAT(pa)     , $ ; mean pitch angles (radians)
            dpa    : FLOAT(dpa)    , $ ; pitch angle widths (radians)
            pa_min : FLOAT(pa_min) , $ ; minimum pitch angle (radians)
            pa_max : FLOAT(pa_max) , $ ; maximum pitch angle (radians)
            iaz    : i             , $ ; anode bin (0-15)
            jel    : j             , $ ; deflector bin (0-5)
            k3d    : k             , $ ; 3D angle bin (0-95)
            Baz    : FLOAT(Baz)    , $ ; Baz in SWEA coord. (radians)
            Bel    : FLOAT(Bel)      } ; Bel in SWEA coord. (radians)
     
    str_element, data, 'pa', TRANSPOSE(FLOAT(pa)), /add
    str_element, data, 'dpa', TRANSPOSE(FLOAT(dpa)), /add
    str_element, data, 'pa_min', TRANSPOSE(FLOAT(pa_min)), /add
    str_element, data, 'pa_max', TRANSPOSE(FLOAT(pa_max)), /add
    str_element, data, 'iaz', i, /add
    str_element, data, 'jel', j, /add
    str_element, data, 'k3d', k, /add
    str_element, data, 'Baz', FLOAT(Baz), /add
    str_element, data, 'Bel', FLOAT(Bel), /add
  endfor
  
  return

end
