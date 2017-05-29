;+
;FUNCTION:   mvn_frame_name
;PURPOSE:
;  Expands a MAVEN frame name shortcut to the full frame name
;  recognized by SPICE.
;
;  Simply returns the input if the frame shortcut is not recognized.
;
;USAGE:
;  fname_full = mvn_frame_name(frame)
;
;INPUTS:
;       frame:    MAVEN frame name shortcut.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-05-28 12:37:00 -0700 (Sun, 28 May 2017) $
; $LastChangedRevision: 23359 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_frame_name.pro $
;
;CREATED BY:    David L. Mitchell
;-
function mvn_frame_name, frame
  
  if (size(frame,/type) ne 7) then return, frame
  
  for i=0,(n_elements(frame)-1) do begin
    case strupcase(frame[i]) of
      'MARS'       : frame[i] = 'IAU_MARS'
      'SPACECRAFT' : frame[i] = 'MAVEN_SPACECRAFT'
      'APP'        : frame[i] = 'MAVEN_APP'
      'STATIC'     : frame[i] = 'MAVEN_STATIC'
      'SWIA'       : frame[i] = 'MAVEN_SWIA'
      'SWEA'       : frame[i] = 'MAVEN_SWEA'
      'MAG1'       : frame[i] = 'MAVEN_MAG_PY'
      'MAG2'       : frame[i] = 'MAVEN_MAG_MY'
      'EUV'        : frame[i] = 'MAVEN_EUV'
      'SEP1'       : frame[i] = 'MAVEN_SEP1'
      'SEP2'       : frame[i] = 'MAVEN_SEP2'
      'IUVS_LIMB'  : frame[i] = 'MAVEN_IUVS_LIMB'
      'IUVS_NADIR' : frame[i] = 'MAVEN_IUVS_NADIR'
      'NGIMS'      : frame[i] = 'MAVEN_NGIMS'
      else         : ; do nothing
    endcase
  endfor
 
  return, frame

end
