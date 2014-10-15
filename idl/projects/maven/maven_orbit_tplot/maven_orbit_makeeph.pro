;+
;PROCEDURE:   maven_orbit_makeeph
;PURPOSE:
;  Generates a MAVEN spacecraft ephemeris using the SPICE Icy toolkit.  The ephemeris 
;  is returned in a structure with the following tags:
;
;    T              Time (UTC): number of seconds since 1970-01-01
;    X              X position coordinate (km)
;    Y              Y position coordinate (km)
;    Z              Z position coordinate (km)
;    VX             X velocity component (km/s)
;    VY             Y velocity component (km/s)
;    VZ             Z velocity component (km/s)
;
; The available coordinate frames are:
;
;   IAU_MARS = body-fixed Mars geographic coordinates (non-inertial)
;
;              X ->  0 deg E longitude, 0 deg latitude
;              Y -> 90 deg E longitude, 0 deg latitude
;              Z -> 90 deg N latitude (= X x Y)
;              origin = center of Mars
;              units = kilometers
;
;   GEO = synonym (in this routine only) for IAU_MARS
;
;   MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;              X -> from center of Mars to center of Sun
;              Y -> opposite to Mars' orbital angular velocity vector
;              Z = X x Y
;              origin = center of Mars
;              units = kilometers
;
;   J2000 = Mean equator and equinox at J2000 epoch (inertial)
;
;              X -> aligned with mean (vernal) equinox
;              Z -> aligned with celestial north pole (Earth's rotation axis)
;              Y = Z x X
;              origin = center of Mars
;              units = kilometers
;
;USAGE:
;  maven_orbit_makeeph, frame=frame, eph=eph
;INPUTS:
;
;KEYWORDS:
;       TSTEP:     Time step (seconds).  Default = 60.
;
;       EPH:       Named variable to hold the ephemeris structure.
;
;       FRAME:     Coordiante frame.  Can be "J2000", "IAU_MARS", or "MSO".
;                  (Also accepts "GEO" as a synomym for "IAU_MARS".)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-13 12:29:59 -0700 (Mon, 13 Oct 2014) $
; $LastChangedRevision: 15983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_makeeph.pro $
;
;CREATED BY:	David L. Mitchell  2014-10-13
;-
pro maven_orbit_makeeph, tstep=tstep, eph=eph, frame=frame, tstart=tstart, tstop=tstop, $
                         current=current, unload=unload, reset=reset

  common mvn_orbit_makeeph, kernels, tstart1, tstop1

; Initialize SPICE

  if ((size(kernels,/type) eq 0) or keyword_set(reset)) then begin

    if keyword_set(current) then begin

      moi = time_double('2014-09-22/02:24:00')
      now = systime(/sec,/utc)
      twoweeks = 14D*86400D
      trange = [moi, (now + twoweeks)]

      kernels = mvn_spice_kernels(['STD','SCK','FRM','POS'], trange=trange, /valid, verbose=-1, /load)
      indx = where(kernels ne '', count)
      if (count gt 0) then kernels = kernels[indx] else return

      if not keyword_set(tstart) then tstart = trange[0]
      if not keyword_set(tstop) then tstop = trange[1]

    endif else begin

      homedir = '/Users/mitchell/Documents/Home/'
      kpath = homedir + 'Earth/THEMIS/TDAS/tdas_3_02/idl/personal/SPICE/kernels/'

      planet_spk  = kpath + 'spk/de421.bsp'                         ; JPL Planetary Ephemeris
      planet_pck  = kpath + 'pck/pck00009.tpc'                      ; Planet shape/orientation/rotation
      leapsec_lsk = kpath + 'lsk/naif0010.tls'                      ; Leap seconds
      maven_fk    = kpath + 'fk/maven_v01.tf'                       ; Spacecraft frame definitions
      mars_mso_fk = kpath + 'fk/mars_mso_v01.tf'                    ; MSO coordinate frame definition
      maven_spk   = kpath + 'spk/trj_orb_od029a_140708-151108_reference_v1.bsp' ; MAVEN spk ephemeris

;     maven_spk   = kpath + 'spk/spk_m_141028-151029_120412.bsp'    ; MAVEN spk ephemeris

      kernels = [planet_spk, planet_pck, leapsec_lsk, maven_fk, mars_mso_fk, maven_spk]

      indx = where(kernels ne '', count)
      if (count gt 0) then kernels = kernels[indx] else return
      cspice_furnsh, kernels

    endelse

    print," "
    print,"Kernels in use:"
    for i=0,(n_elements(kernels)-1) do print,file_basename(kernels[i]),format="(3x,a)"
    print," "

  endif

  if not keyword_set(tstep) then tstep = 60D else tstep = double(tstep)
  
  msg = strcompress("Time step: " + string(round(tstep),format='(i)') + " sec")
  print,msg
  print," "
  
  if not keyword_set(frame) then begin
    print,'You must specify a reference frame.'
    return
  endif

  frame = strupcase(frame)
  
  case strupcase(frame) of
    'J2000'    : frame = 'J2000'
    'IAU_MARS' : frame = 'IAU_MARS'
    'GEO'      : frame = 'IAU_MARS'
    'MSO'      : frame = 'MSO'
    else       : begin
                   print,'Unrecognized frame: ',frame
                   print,'Choices are: J2000, IAU_MARS (= GEO), or MSO.'
                   return
                 end
  endcase
  
  print,"Reference frame: ",frame
  print," "

; Get the time range spanned by the spacecraft SPK kernels

  maxiv = 1000
  winsiz = 2 * maxiv
  timlen = 51
  maxobj = 1000
  
  cover = cspice_celld(winsiz)
  ids   = cspice_celli(maxobj)

  indx = where(stregex(kernels,'trj_',/boolean) or stregex(kernels,'maven_orb',/boolean), nspk)
  if (nspk eq 0) then begin
    print,"No SPK kernels!"
    return
  endif
  
  maven_spk = kernels[indx]

  estart = [0D]
  estop = [0D]

  for k=0,(nspk-1) do begin
    cspice_spkobj, maven_spk[k], ids

    for i=0, cspice_card(ids) - 1 do begin
      obj = ids.base[ids.data + i]
      cspice_scard, 0L, cover
      cspice_spkcov, maven_spk[k], obj, cover

      niv = cspice_wncard(cover)
    
      for j=0, niv-1 do begin
        cspice_wnfetd, cover, j, b, e
        cspice_timout, [b,e], "YYYY-MM-DD/HR:MN:SC.###", timlen, timstr
        estart = [estart, time_double(timstr[0])]
        estop = [estop, time_double(timstr[1])]
      endfor
    endfor
  endfor
  
  estart = min(time_double(estart[1L:*]))
  estop = max(time_double(estop[1L:*]))

  print, "Spacecraft SPK start time: ", time_string(estart)
  print, "Spacecraft SPK stop  time: ", time_string(estop)
  print, "Number of intervals: ",niv,format='(a,i)'

; Get time range for generating ephemeris

  if not keyword_set(tstart) then begin
    if not keyword_set(tstart1) then begin
      print,''
      tstart = ''
      read,tstart,prompt="Ephemeris Start Time [YYYY-MM-DD/HH:MM:SS]: "
    endif else tstart = tstart1
  endif
  tstart = time_double(tstart) > estart
  
  if not keyword_set(tstop) then begin
    if not keyword_set(tstop1) then begin
      tstop = ''
      read,tstop,prompt="Ephemeris Stop Time [YYYY-MM-DD/HH:MM:SS]: "
    endif else tstop = tstop1
  endif
  tstop = time_double(tstop) < estop
  
  trange = [tstart,tstop]
  tstart1 = tstart
  tstop1 = tstop

; Define ephemeris structure 

  npts = floor((tstop - tstart)/tstep) + 1L
  
  eph = {t  : 0D , $
         x  : 0D , $
         y  : 0D , $
         z  : 0D , $
         vx : 0D , $
         vy : 0D , $
         vz : 0D    }
  
  eph = replicate(eph,npts)

  eph.t = tstart + tstep*dindgen(npts)
  timestr = time_string(eph.t,prec=3)

; Convert UTC to ET (TDB seconds past J2000)

  cspice_str2et, timestr, et

; Generate the ephemeris centered on Mars without aberration correction

  cspice_spkezr, 'MAVEN', et, frame, 'NONE', 'MARS', state, ltime

; Package the result

  eph.x = reform(state[0,*])
  eph.y = reform(state[1,*])
  eph.z = reform(state[2,*])

  eph.vx = reform(state[3,*])
  eph.vy = reform(state[4,*])
  eph.vz = reform(state[5,*])

; Clean up

  if keyword_set(unload) then cspice_kclear

  return

end
