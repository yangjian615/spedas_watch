; $LastChangedBy: moka $
; $LastChangedDate: 2015-02-27 19:17:56 -0800 (Fri, 27 Feb 2015) $
; $LastChangedRevision: 17057 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/eva_flag2user.pro $
; 
; 1:SITL, 2:Super-SITL, 3:FPI-CAL
FUNCTION eva_flag2user, flag
  case flag of
    0: user = 'Guest user'; Not logged in to SOC
    1: user = 'MMS member'
    2: user = 'SITL'
    3: user = 'Super-SITL'
    4: user = 'FPI member'
    else: message,'wrong flag'
  endcase
  return, user
END
