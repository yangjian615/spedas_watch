;+
;FUNCTION:   mvn_swe_padmap
;PURPOSE:
;  Calculates the pitch angle map for a PAD.
;
;USAGE:
;  pam = mvn_swe_padmap(pkt)
;
;INPUTS:
;       pkt :          A raw PAD packet (APID A2 or A3).
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-07-10 18:10:32 -0700 (Thu, 10 Jul 2014) $
; $LastChangedRevision: 15558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap.pro $
;
;CREATED BY:    David L. Mitchell  03-18-14
;FILE: mvn_swe_padmap.pro
;-
function mvn_swe_padmap, pkt

  @mvn_swe_com

  str_element, pkt, 'Baz', success=ok        ; make sure it's a PAD packet

  if (ok) then begin

    aBaz = pkt.Baz
    aBel = pkt.Bel
    group = pkt.group

; Magnetic field azimuth and elevation in SWEA coordinates

    mvn_swe_magdir, pkt.time, aBaz, aBel, Baz, Bel

; Anode, deflector, and 3D bins for each PAD bin
    
    i = fix((indgen(16) + aBaz/16) mod 16)   ; 16 anode bins at each time
    j = swe_padlut[*,aBel]                   ; 16 deflector bins at each time
    k = j*16 + i                             ; 16 3D angle bins at each time

; nxn azimuth-elevation array for each of the 16 PAD bins
; Elevations are energy dependent above ~2 keV.

    ddtor = !dpi/180D
    ddtors = replicate(ddtor,64)
    n = 17                                   ; patch size - odd integer

    daz = double((indgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
    Saz = reform(replicate(1D,n*n) # double(swe_az[i]) + daz, n*n*16) # ddtors
    
    Sel = dblarr(n*n*16, 64)
    for m=0,63 do begin
      del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,m,group])
      Sel[*,m] = reform(replicate(1D,n*n) # double(swe_el[j,m,group]) + del, n*n*16)
    endfor
    Sel = Sel*ddtor
    
    Saz = reform(Saz,n*n,16,64)  ; nxn az-el patch, 16 pitch angle bins, 64 energies
    Sel = reform(Sel,n*n,16,64)

; Calculate the nominal (center) pitch angle for each bin
;   This is a function of energy because the deflector high voltage supply
;   tops out above ~2 keV, and it's function of time because the magnetic
;   field varies: pam -> 16 angles X 64 energies.

    pam = acos(cos(Saz - Baz)*cos(Sel)*cos(Bel) + sin(Sel)*sin(Bel))

    pa = total(pam,1)/float(n*n)    ; mean pitch angle
    pa_min = min(pam,dim=1)         ; minimum pitch angle
    pa_max = max(pam,dim=1)         ; maximum pitch angle
    dpa = pa_max - pa_min           ; pitch angle range

; Package the result

    pam = { pa     : float(pa)     , $    ; mean pitch angles (radians)
            dpa    : float(dpa)    , $    ; pitch angle widths (radians)
            pa_min : float(pa_min) , $    ; minimum pitch angle (radians)
            pa_max : float(pa_max) , $    ; maximum pitch angle (radians)
            iaz    : i             , $    ; anode bin (0-15)
            jel    : j             , $    ; deflector bin (0-5)
            k3d    : k             , $    ; 3D angle bin (0-95)
            Baz    : float(Baz)    , $    ; Baz in SWEA coord. (radians)
            Bel    : float(Bel)       }   ; Bel in SWEA coord. (radians)

  endif else pam = 0

  return, pam

end
