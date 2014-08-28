;+
;PROCEDURE:   swe_3d_snap
;PURPOSE:
;  Plots 3D snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;  This version uses plot3d and spec3d on packaged 3D data.
;
;USAGE:
;  swe_3d_snap
;
;INPUTS:
;
;KEYWORDS:
;       EBINS:         Energy bins to plot (passed to plot3d).  Default = 16 evenly
;                      spaced bins.
;
;       CENTER:        Longitude and latitude of the center [lon, lat].
;
;       SPEC:          Plot energy spectra using spec3d.
;
;       UNITS:         Units for the spec3d.
;
;       ENERGY:        One or more energies to plot.  Overrides EBINS.
;
;       PADMAG:        If set, use the MAG angles in the PAD data to show the 
;                      magnetic field direction.
;
;       DDD:           Named variable to hold a 3D structure at the last time
;                      selected.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       SMO:           Set smoothing in energy and angle.  Since there are only six
;                      theta bins, smoothing in that dimension is not recommended.
;
;                        smo = [n_energy, n_phi, n_theta]  ; default = [1,1,1]
;
;                      This routine takes into account the 360-0 degree wrap when 
;                      smoothing.
;
;       SYMDIR:        Calculate and overplot the symmetry direction of the 
;                      electron distribution.
;
;       SYMENERGY:     Energy at which to calculate the symmetry direction.  Should
;                      be > 100 eV.  Using the SMO keyword also helps.
;
;       POWER:         Weighting function is proportional to eflux^power.  Higher
;                      powers emphasize the peak of the distribution; lower powers
;                      give more weight to surrounding cells.  Default = 2.
;
;       SYMDIAG:       Plot symmetry weighting function in separate window.
;
;       SUNDIR:        Plot the direction of the Sun in SWEA coordinates.
;
;       LABEL:         If set, label the 3D angle bins.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:46:09 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15673 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_3d_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_3d_snap, spec=spec, keepwins=keepwins, archive=archive, ebins=ebins, $
                 center=center, units=units, ddd=ddd, sum=sum, padmag=padmag, $
                 energy=energy, label=label, smo=smo, symdir=symdir, sundir=sundir, $
                 symenergy=symenergy, symdiag=symdiag, power=pow

  @mvn_swe_com
  common snap_layout, Dopt, Sopt, Popt, Nopt, Copt, Eopt, Hopt

  if keyword_set(archive) then aflg = 1 else aflg = 0
  if (data_type(units) ne 7) then units = 'crate'
  
  case strupcase(units) of
    'COUNTS' : yrange = [1.,1.e5]
    'RATE'   : yrange = [1.,1.e5]
    'CRATE'  : yrange = [1.,1.e6]
    'FLUX'   : yrange = [1.,1.e8]
    'EFLUX'  : yrange = [1.e4,1.e9]
    'DF'     : yrange = [1.e-19,1.e-8]
    else     : yrange = [0.,0.]
  endcase

  case n_elements(center) of
    0 : begin
          lon = 180.
          lat = 0.
        end
    1 : begin
          lon = center[0]
          lat = 0.
        end
    else : begin
             lon = center[0]
             lat = center[1]
           end
  endcase

  if keyword_set(spec) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if keyword_set(padmag) then pflg = 1 else pflg = 0
  if (data_type(ebins) eq 0) then ebins = reverse(4*indgen(16))
  if not keyword_set(symenergy) then symenergy = 130.
  if not keyword_set(pow) then pow = 3.
  if keyword_set(symdiag) then dflg = 1 else dflg = 0

  if (n_elements(smo) gt 0) then begin
    nsmo = [1,1,1]
    for i=0,(n_elements(smo)-1) do nsmo[i] = round(smo[i])
    dosmo = 1
  endif else dosmo = 0

  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse
  
  if keyword_set(sundir) then begin
    get_data,'Sun_MAVEN_SWEA_STOW',data=sun,index=i
    if (i eq 0) then begin
      print,"No sun direction!"
      sundir = 0
    endif else begin
      xyz_to_polar, sun, theta=the, phi=phi, /ph_0_360
      sun = {time:sun.x, the:the.y, phi:phi.y}
      the = 0
      phi = 0
    endelse
  endif

; Put up snapshot window(s)

  Twin = !d.window

  if (data_type(Dopt) ne 8) then swe_snap_layout, 0

  window, /free, xsize=Dopt.xsize, ysize=Dopt.ysize, xpos=Dopt.xpos, ypos=Dopt.ypos
  Dwin = !d.window

  if (sflg) then begin
    window, /free, xsize=Sopt.xsize, ysize=Sopt.ysize, xpos=Sopt.xpos, ypos=Sopt.ypos
    Swin = !d.window
  endif
  
  if (dflg) then begin
    window, /free, xsize=Sopt.xsize, ysize=Sopt.ysize, xpos=Sopt.xpos, ypos=Sopt.ypos
    Fwin = !d.window
  endif

; Select the first time, then get the 3D spectrum closest that time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime2,trange,npoints=npts,/silent,button=button

  if (data_type(trange) eq 2) then begin  ; Abort before first time select.
    wdelete,Dwin                          ; Don't keep empty windows.
    if (sflg) then wdelete,Swin
    if (dflg) then wdelete,Fwin
    wset,Twin
    return
  endif
  
  ok = 1

  while (ok) do begin

; Put up a 3D spectrogram
 
    wset, Dwin

    ddd = mvn_swe_get3d(trange,archive=aflg,all=doall,/sum,units=units)

    if (data_type(ddd) eq 8) then begin
    
      if keyword_set(energy) then begin
        n_e = n_elements(energy)
        ebins = intarr(n_e)
        for k=0,(n_e-1) do begin
          de = min(abs(ddd.energy[*,0] - energy[k]), j)
          ebins[k] = j
        endfor
      endif
      nbins = float(n_elements(ebins))
      
      if (dosmo) then begin
        ddat = reform(ddd.data,64,16,6)
        dat = fltarr(64,32,6)
        dat[*,8:23,*] = ddat
        dat[*,0:7,*] = ddat[*,8:15,*]
        dat[*,24:31,*] = ddat[*,0:7,*]
        dats = smooth(dat,nsmo)
        ddd.data = reform(dats[*,8:23,*],64,96)
      endif

      plot3d_new, ddd, lat, lon, ebins=ebins
    
      if (pflg) then begin
        dt = min(abs(a2.time - mean(ddd.time)),j)
        mvn_swe_magdir, a2[j].time, a2[j].Baz, a2[j].Bel, Baz, Bel
        Baz = Baz*!radeg
        Bel = Bel*!radeg
        if (abs(Bel) gt 61.) then col=255 else col=0
        oplot,[Baz],[Bel],psym=1,color=col,thick=2,symsize=1.5
        oplot,[Baz+180.],[-Bel],psym=4,color=col,thick=2,symsize=1.5
      endif

      if keyword_set(label) then begin
        lab=strcompress(indgen(ddd.nbins),/rem)
        xyouts,reform(ddd.phi[63,*]),reform(ddd.theta[63,*]),lab,align=.5
      endif
      
      if keyword_set(sundir) then begin
        dt = min(abs(sun.time - mean(ddd.time)),j)
        Saz = sun.phi[j]
        Sel = sun.the[j]
        if (abs(Sel) gt 61.) then col=255 else col=0
        oplot,[Saz],[Sel],psym=6,color=col,thick=2,symsize=1.2
        Saz = (Saz + 180.) mod 360.
        Sel = -Sel
        oplot,[Saz],[Sel],psym=7,color=col,thick=2,symsize=1.2
      endif
      
      if keyword_set(symdir) then begin
        de = min(abs(ddd.energy[*,0] - symenergy), sbin)
        f = reform(ddd.data[sbin,*],16,6)
        if (min(ddd.time) lt t_mtx[2]) then f[*,0:1] = 0.
        phi = (reform(ddd.phi[sbin,*],16,6))[*,0]
        the = (reform(ddd.theta[sbin,*],16,6))[0,*]
        
        fmax = max(f,k)
        k = k mod 16

        faz = total((f/fmax)^pow,2)
        faz = (faz - mean(faz)) > 0.
        k = (k + 9) mod 16
        az = shift(phi,-k)
        if (k gt 0) then az[16-k:*] = az[16-k:*] + 360.
        faz = shift(faz,-k)
        m = indgen(9) + 3
        az0 = (total(az[m]*faz[m])/total(faz[m]) + 360.) mod 360.

        el = reform(the,6)
        f = shift(f,-k,0)
        fel = total((f[m,*]/fmax)^pow,1)
        fel = (fel - mean(fel)) > 0.
        el0 = total(el*fel)/total(fel)

        oplot,[az0],[el0],psym=5,color=0,thick=2,symsize=1.2
        
        if (dflg) then begin
          wset, Fwin
          !p.multi = [0,1,2]
          x = az[m]
          if (min(x) gt 270.) then x = x - 360.
          plot,x,faz[m],xtitle='Azimuth',title='Symmetry Function',psym=10
          oplot,[az0,az0],[0.,2.*max(faz[m])], line=2, color=6
          oplot,[az0,az0]-360.,[0.,2.*max(faz[m])], line=2, color=6
          oplot,[az0,az0]+360.,[0.,2.*max(faz[m])], line=2, color=6

          plot,el,fel,xtitle='Elevation',psym=10
          if (min(ddd.time) lt t_mtx[2]) then j = 2 else j = 0
          oplot,[el[j],el[j]],[0.,2.*max(fel)], line=2, color=4
          oplot,[el[5],el[5]],[0.,2.*max(fel)], line=2, color=4
          oplot,[el0,el0],[0.,2.*max(fel)], line=2, color=6
          !p.multi = 0
        endif
      endif

      if (sflg) then begin
        wset, Swin
        spec3d, ddd, units=units, limits={yrange:yrange, ystyle:1, ylog:1, psym:0}
      endif
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=npts,/silent,button=button
    if (data_type(trange) eq 5) then ok = 1 else ok = 0

  endwhile

  if (kflg) then begin
    wdelete, Dwin
    if (sflg) then wdelete, Swin
    if (dflg) then wdelete, Fwin
  endif

  wset, Twin

  return

end
