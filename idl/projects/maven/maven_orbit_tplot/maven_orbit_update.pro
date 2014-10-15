;+
;PROCEDURE:   maven_orbit_update
;PURPOSE:
;  Updates the "current" spacecraft ephemeris using SPICE. 
;
;USAGE:
;  maven_orbit_update
;
;INPUTS:
;
;KEYWORDS:
;       TSTEP:    Ephemeris time step (sec).  Default = 60 sec.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-13 12:29:59 -0700 (Mon, 13 Oct 2014) $
; $LastChangedRevision: 15983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_update.pro $
;
;CREATED BY:	David L. Mitchell  2014-10-13
;-
pro maven_orbit_update, tstep=tstep

  if not keyword_set(tstep) then tstep = 60D
  path = root_data_dir() + 'maven/anc/spice/sav/'
  mname = path + 'maven_orb_mso_current.sav'
  gname = path + 'maven_orb_geo_current.sav'

  maven_orbit_makeeph, tstep=tstep, frame='mso', eph=maven, /current, /reset
  save, maven, file=mname

  maven_orbit_makeeph, tstep=tstep, frame='geo', eph=maven_g, /current, /unload
  save, maven_g, file=gname

end
