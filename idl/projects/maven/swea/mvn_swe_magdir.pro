;+
;PROCEDURE:   mvn_swe_magdir
;PURPOSE:
;  Converts magnetic field azimuth and elevation bytes from PAD packets
;  (A2 and A3) into azimuth and elevation in radians.
;
;USAGE:
;  mvn_swe_magdir, iBaz, jBel, Baz, Bel
;
;INPUTS:
;       time:     Packet time.  Used to correct for MICD error when needed.
;
;       iBaz:     Azimuth byte in PAD packet.
;
;       jBel:     Elevation byte in PAD packet.
;
;OUTPUTS:
;       Baz:      Magnetic field azimuth in radians.  SWEA coordinates.
;
;       Bel:      Magnetic field azimuth in radians.  SWEA coordinates.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-07-10 18:09:44 -0700 (Thu, 10 Jul 2014) $
; $LastChangedRevision: 15557 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_magdir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_magdir, time, iBaz, jBel, Baz, Bel

  @mvn_swe_com

  iBaz_c = byte(iBaz)
  jBel_c = byte(jBel)

; Correct for MICD error before FSW fix
  
  indx = where(time lt t_mtx2, count)
  if (count gt 0L) then iBaz_c[indx] = iBaz_c[indx] - 64B

; Convert to radians, SWEA coordinates

  Baz = (double(iBaz_c) + 0.5D)*(!dpi/128D)  ; 1.4-deg resolution
  Bel = (double(jBel_c) - 19.5D)*(!dpi/40D)  ; 4.5-deg resolution

  return

end
