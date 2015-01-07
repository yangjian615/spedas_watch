;+
;PROCEDURE:   maven_orbit_snap
;PURPOSE:
;  After running maven_orbit_tplot, this routine plots the orbit as viewed
;  along each of the MSO axes.  Optionally, the orbit can be superimposed on
;  models of the solar wind interaction with Mars.  Also optionally, the 
;  position of the spacecraft can be plotted (in GEO coordinates) on a map
;  of Mars' topography and magnetic field based on MGS MOLA and MAG data.
;
;  All plots are generated at times selected with the cursor on the TPLOT
;  window.  Hold down the left mouse button and drag for a movie effect.
;
;USAGE:
;  maven_orbit_snap
;INPUTS:
;
;KEYWORDS:
;       PREC:     Plot the position of the spacecraft at the selected time,
;                 superimposed on the orbit.  Otherwise, the periapsis 
;                 location for each orbit is plotted.
;
;       MHD:      Plot the orbit superimposed on an image of an MHD simulation
;                 of the solar wind interaction with Mars (from Ma).
;                   1 : Plot the XY projection
;                   2 : Plot the XZ projection
;
;       HYBRID:   Plot the orbit superimposed on an image of a hybrid simulation
;                 of the solar wind interaction with Mars (from Brecht).
;                   1 : Plot the XZ projection
;                   2 : Invert Z in the model, then plot the XZ projection
;
;       LATLON:   Plot MSO longitudes and latitudes of periapsis (PREC=0) or 
;                 the spacecraft (PREC=1) in a separate window.
;
;       XZ:       Plot only the XZ projection.
;
;       MARS:     Plot the position of the spacecraft (PREC=1) or periapsis 
;                 (PREC=0) on an image of Mars topography and magnetic field
;                 based on MGS data (from Connerney).
;                   1 : Use a small image
;                   2 : Use a large image
;
;       NPOLE:    Plot the position of the spacecraft (PREC=1) or periapsios
;                 (PREC=0) on a north polar projection (lat > 55 deg).  The
;                 background image is the north polar magnetic anomalies observed
;                 at 180-km altitude by MGS (from Acuna).
;
;       NOERASE:  Don't erase previously plotted positions.  Can be used to build
;                 up a visual representation of sampling.
;
;       RESET:    Initialize all plots.
;
;       COLOR:    Symbol color index.
;
;       KEEP:     Do not kill the plot windows on exit.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-01-05 15:34:05 -0800 (Mon, 05 Jan 2015) $
; $LastChangedRevision: 16594 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_snap.pro $
;
;CREATED BY:	David L. Mitchell  10-28-11
;-
pro maven_orbit_snap, prec=prec, mhd=mhd, hybrid=hybrid, latlon=latlon, xz=xz, mars=mars, $
    npole=npole, noerase=noerase, keep=keep, color=color, reset=reset

  common mav_orb_tplt, time, ss, wind, sheath, pileup, wake, sza, torb, period, lon, lat, hgt, mex

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if keyword_set(prec) then pflg = 1 else pflg = 0
  if (size(color,/type) gt 0) then cflg = 1 else cflg = 0  
  if keyword_set(noerase) then noerase = 1 else noerase = 0
  if keyword_set(reset) then reset = 1 else reset = 0
  
  if keyword_set(xz) then xzflg = 1 else xzflg = 0

  if keyword_set(mhd) then begin
    if (mhd gt 1) then begin
      if (~noerase or reset) then mhd_orbit, [-10.], [-10.], /reset, /xz
      nflg = 2
    endif else begin
      if (~noerase or reset) then mhd_orbit, [-10.], [-10.], /reset, /xy
      nflg = 1
    endelse
  endif else nflg = 0

  if keyword_set(hybrid) then begin
    if (hybrid eq 1) then begin
      if (~noerase or reset) then hybrid_orbit_new, [-10.], [-10.], /reset, /xz
      bflg = 1
    endif else begin
      if (~noerase or reset) then hybrid_orbit_new, [-10.], [-10.], /reset, /xz, /flip
      bflg = 2
    endelse
  endif else bflg = 0

  if keyword_set(npole) then begin
    if (~noerase or reset) then mag_npole_orbit, [0.], [0.], /reset
    npflg = 1
  endif else npflg = 0

  if keyword_set(latlon) then gflg = 1 else gflg = 0
  
  if keyword_set(mars) then begin
    mflg = mars
    if (mflg gt 1) then mbig = 1 else mbig = 0
  endif else mflg = 0
  
  if keyword_set(orbit) then oflg = 1 else oflg = 0

  Twin = !d.window

; Mars shock parameters

  R_m = 3389.9D
  x0  = 0.600
  psi = 1.026
  L   = 2.081

; Mars MPB parameters

  x0_p1  = 0.640
  psi_p1 = 0.770
  L_p1   = 1.080

  x0_p2  = 1.600
  psi_p2 = 1.009
  L_p2   = 0.528

; Get the orbit closest the selected time

  print,'Use button 1 to select time; button 3 to quit.'

  if (xzflg) then begin
    window,26,xsize=600,ysize=538
    Owin = !d.window
  endif else begin
    device, get_screen_size=scr
    oscale = 0.965*(scr[1]/943.)

    xsize = round(350.*oscale)
    ysize = round(943.*oscale)

    window,26,xsize=xsize,ysize=ysize
    Owin = !d.window
  endelse

  if (gflg) then begin
    window,/free,xsize=600,ysize=280
    Gwin = !d.window
  endif

  if (mflg gt 0) then mag_mola_orbit, -100., -100., big=mbig, /reset

  wset,Twin
  ctime2,trange,npoints=1,/silent,button=button

  if (size(trange,/type) eq 2) then begin
    wdelete,Owin
    wset,Twin
    return
  endif

  tref = trange[0]
  dt = min(abs(time - tref), iref)
  tref = time[iref]
  ndays = (tref - time[0])/86400D

  dt = min(abs(torb - tref), jref)
  dj = round(double(period[jref])*3600D/(time[1] - time[0]))
  
  
  ok = 1

  while (ok) do begin
    title = string(time_string(tref),floor(ndays),format='(a19,2x,"(Day ",i3,")")')

    wset, Owin

    npts = n_elements(ss[*,0])

    imid = dj/2L
    rndx = iref + lindgen(dj+1L) - imid

    imin = min(rndx)
    if (imin lt 0L) then rndx = rndx - imin

    imax = max(rndx)
    if (imax gt (npts-1L)) then rndx = rndx - (imax-npts-1L)

    xo = ss[rndx,0]
    yo = ss[rndx,1]
    zo = ss[rndx,2]
    ro = ss[rndx,3]

    xs = sheath[rndx,0]
    ys = sheath[rndx,1]
    zs = sheath[rndx,2]

    xp = pileup[rndx,0]
    yp = pileup[rndx,1]
    zp = pileup[rndx,2]

    xw = wake[rndx,0]
    yw = wake[rndx,1]
    zw = wake[rndx,2]

; Orbit plots with three orthogonal views

    phi = findgen(361)*!dtor
    xm = cos(phi)
    ym = sin(phi)

    rmin = min(ro, imin)
    imin = imin[0]
    rmax = ceil(max(ro) + 1D)

    xrange = [-rmax,rmax]
    yrange = xrange

    if (xzflg eq 0) then !p.multi = [3,1,3]
    erase

; X-Y Projection

    if (xzflg eq 0) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + y*y)

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      mlon = atan(yo[i],xo[i])
      mlat = asin(zo[i]/ro[i])
      alt = (ro[i] - 1D)*R_m
      szaref = acos(cos(mlon)*cos(mlat))

      plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty, $
           xtitle='X (Rp)',ytitle='Y (Rp)',charsize=2.0,title=title
      oplot,xm,ym,color=6
      oplot,x,y

      oplot,[x[i]],[y[i]],psym=8,color=5

      x = xs
      y = ys
      z = zs

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,x,y,color=4

      x = xp
      y = yp
      z = zp

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,x,y,color=5

      x = xw
      y = yw
      z = zw

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,x,y,color=2

; Shock conic

      phi = (-150. + findgen(301))*!dtor
      rho = L/(1. + psi*cos(phi))

      xshock = x0 + rho*cos(phi)
      yshock = rho*sin(phi)
      oplot,xshock,yshock,color=3,line=1

; MPB conic

      phi = (-160. + findgen(160))*!dtor

      rho = L_p1/(1. + psi_p1*cos(phi))
      x1 = x0_p1 + rho*cos(phi)
      y1 = rho*sin(phi)

      rho = L_p2/(1. + psi_p2*cos(phi))
      x2 = x0_p2 + rho*cos(phi)
      y2 = rho*sin(phi)

      indx = where(x1 ge 0)
      jndx = where(x2 lt 0)
      xpileup = [x2[jndx], x1[indx]]
      ypileup = [y2[jndx], y1[indx]]

      phi = findgen(161)*!dtor

      rho = L_p1/(1. + psi_p1*cos(phi))
      x1 = x0_p1 + rho*cos(phi)
      y1 = rho*sin(phi)

      rho = L_p2/(1. + psi_p2*cos(phi))
      x2 = x0_p2 + rho*cos(phi)
      y2 = rho*sin(phi)

      indx = where(x1 ge 0)
      jndx = where(x2 lt 0)
      xpileup = [xpileup, x1[indx], x2[jndx]]
      ypileup = [ypileup, y1[indx], y2[jndx]]

      oplot,xpileup,ypileup,color=3,line=1

    endif

; X-Z Projection

    x = xo
    y = yo
    z = zo
    s = sqrt(x*x + z*z)

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      z[indx] = !values.f_nan
    endif

    if (xzflg) then msg = title else msg = ''

    plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty, $
         xtitle='X (Rp)',ytitle='Z (Rp)',charsize=2.0,title=msg
    oplot,xm,ym,color=6
    oplot,x,z

    if (pflg) then i = imid else i = imin
    oplot,[x[i]],[z[i]],psym=8,color=5

    x = xs
    y = ys
    z = zs

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      z[indx] = !values.f_nan
    endif
    oplot,x,z,color=4

    x = xp
    y = yp
    z = zp

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      y[indx] = !values.f_nan
    endif
    oplot,x,z,color=5

    x = xw
    y = yw
    z = zw

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      z[indx] = !values.f_nan
    endif
    oplot,x,z,color=2

; Shock conic

    phi = (-150. + findgen(301))*!dtor
    rho = L/(1. + psi*cos(phi))

    xshock = x0 + rho*cos(phi)
    zshock = rho*sin(phi)
    oplot,xshock,zshock,color=3,line=1

; MPB conic

    phi = (-160. + findgen(160))*!dtor

    rho = L_p1/(1. + psi_p1*cos(phi))
    x1 = x0_p1 + rho*cos(phi)
    z1 = rho*sin(phi)

    rho = L_p2/(1. + psi_p2*cos(phi))
    x2 = x0_p2 + rho*cos(phi)
    z2 = rho*sin(phi)

    indx = where(x1 ge 0)
    jndx = where(x2 lt 0)
    xpileup = [x2[jndx], x1[indx]]
    zpileup = [z2[jndx], z1[indx]]

    phi = findgen(161)*!dtor

    rho = L_p1/(1. + psi_p1*cos(phi))
    x1 = x0_p1 + rho*cos(phi)
    z1 = rho*sin(phi)

    rho = L_p2/(1. + psi_p2*cos(phi))
    x2 = x0_p2 + rho*cos(phi)
    z2 = rho*sin(phi)

    indx = where(x1 ge 0)
    jndx = where(x2 lt 0)
    xpileup = [xpileup, x1[indx], x2[jndx]]
    zpileup = [zpileup, z1[indx], z2[jndx]]

    oplot,xpileup,zpileup,color=3,line=1

; Y-Z Projection

    if (xzflg eq 0) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(y*y + z*z)

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty, $
           xtitle='Y (Rp)',ytitle='Z (Rp)',charsize=2.0
      oplot,xm,ym,color=6
      oplot,y,z

      if (pflg) then i = imid else i = imin
      oplot,[y[i]],[z[i]],psym=8,color=5

      x = xs
      y = ys
      z = zs

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif
      oplot,y,z,color=4

      x = xp
      y = yp
      z = zp

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,y,z,color=5

      x = xw
      y = yw
      z = zw

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif
      oplot,y,z,color=2

      L0 = sqrt((L + psi*x0)^2. - x0*x0)
      oplot,L0*xm,L0*ym,color=3,line=1

      L0 = sqrt((L_p1 + psi_p1*x0_p1)^2. - x0_p1*x0_p1)
      oplot,L0*xm,L0*ym,color=3,line=1

    endif

    !p.multi = 0

; Put up the ground track

    if (gflg) then begin
      wset, Gwin
      mlon = mlon*!radeg
      mlat = mlat*!radeg
      szaref = szaref*!radeg

      title = string(mlon,mlat,alt,szaref,$
                format='("Lon = ",f6.1,2x,"Lat = ",f5.1,2x,"Alt = ",f5.0,2x,"SZA = ",f5.1)')

      plot,[mlon],[mlat],xrange=[-180,180],/xsty,yrange=[-90,90],/ysty,$
           xticks=12,xminor=3,yticks=6,yminor=4,title=title,$
           xtitle='MSO Longitude',ytitle='MSO Latitude',psym=3
      oplot,[-90,-90],[-90,90],color=4,line=1
      oplot,[90,90],[-90,90],color=4,line=1
      oplot,[0],[0],psym=8,color=5,symsize=2.0
      oplot,[mlon],[mlat],psym=8,color=6,symsize=2.0
    endif

; Put up the MHD simulation plot

    if (nflg eq 1) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + y*y)

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      if (cflg) then j = color else j = 0

      mhd_orbit, x, y, x[i], y[i], color=j, psym=0, /xy
    endif

    if (nflg eq 2) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + z*z)

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      if (cflg) then j = color else j = 0

      mhd_orbit, x, z, x[i], z[i], color=j, psym=0, /xz
    endif

; Put up the hybrid simulation plot

    if (bflg gt 0) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + z*z)

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      if (cflg) then j = color else j = 255

      if (bflg eq 1) then hybrid_orbit_new, x, z, x[i], z[i], color=j, psym=0, /xz $
                     else hybrid_orbit_new, x, z, x[i], z[i], color=j, psym=0, /xz, /flip
    endif

; Put up Mars orbit

    if (mflg gt 0) then begin
      if (pflg) then i = iref else i = rndx[imin]
      title = ''
      if (cflg) then j = color else j = 2
      mag_mola_orbit, lon[i], lat[i], big=mbig, noerase=noerase, title=title, color=j
    endif

; Put up Mars North polar plot

    if (npflg) then begin
      if (pflg) then i = iref else i = rndx[imin]
      title = ''
      if (cflg) then j = color else j = 2
      mag_Npole_orbit, lon[i], lat[i], noerase=noerase, title=title, color=j
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (size(trange,/type) eq 5) then begin
      tref = trange[0]
      dt = min(abs(time - tref), iref)
      ok = 1
    endif else ok = 0

    tref = time[iref]
    ndays = (tref - time[0])/86400D

  endwhile

  if not keyword_set(keep) then begin
    wdelete, Owin
    if (gflg) then wdelete, Gwin
    if (npflg gt 0) then wdelete, 27
    if (mflg gt 0)  then wdelete, 29
    if (nflg gt 0)  then wdelete, 30
    if (bflg gt 0)  then wdelete, 31
  endif

  !p.multi = 0

  return

end
