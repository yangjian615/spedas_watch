;+
;PROCEDURE:   swe_pad_snap
;PURPOSE:
;  Plots PAD snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;  A PAD snapshot is an pitch angle X energy spectrogram at the selected time.
;  Optionally, keyword ENERGY can be used to plot a PAD in histogram mode for a 
;  single energy.
;
;USAGE:
;  swe_pad_snap
;
;INPUTS:
;
;KEYWORDS:
;       ENERGY:        Energy (eV) to use for the histogram plot.
;
;       UNITS:         Plot PAD data in these units.
;
;       PAD:           Named variable to hold a PAD structure at the last time
;                      selected.
;
;       DDD:           If set, compare with the nearest 3D spectrum.
;
;       CENTER:        Specify the center azimuth for 3D plots.  Only works when DDD
;                      is set.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       SMO:           Number of energy bins to smooth over.
;
;       NORM:          At each energy step, normalize the distribution to the mean.
;
;       LABEL:         If set, label the anode and deflection bin numbers.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
;       BURST:         Synonym for ARCHIVE.
;
;       DIR:           If set, show some useful information with
;                      respect to the observed vector magnetic field
;                      in the MSO and LGEO(local geographic coordinate). 
;
;       MASK_SC:       Mask PA bins that are blocked by the spacecraft.
;                      Default = 1 (yes).
;
;       SPEC:          Plot energy spectra for parallel and anti-parallel
;                      populations.  The value of this keyword is the pitch 
;                      angle width (deg) to include:
;
;                        parallel      : 0 to SPEC degrees
;                        anti-parallel : (180 - SPEC) to 180 degrees
;
;                      Pitch angle bins must be entirely contained within
;                      one of these ranges to be included.
;
;                      Any value of SPEC < 30 deg is taken to be 30 deg.
;
;        PLOTLIMS:     Plot dashed lines at the limits of the pitch angle
;                      coverage.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-08-21 14:42:30 -0700 (Fri, 21 Aug 2015) $
; $LastChangedRevision: 18568 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_pad_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_pad_snap, keepwins=keepwins, archive=archive, energy=energy, $
                  units=units, pad=pad, ddd=ddd, zrange=zrange, sum=sum, $
                  label=label, smo=smo, dir=dir, mask_sc=mask_sc, $
                  abins=abins, dbins=dbins, obins=obins, burst=burst, $
                  pot=pot, spec=spec, plotlims=plotlims, norm=norm, $
                  center=center

  @mvn_swe_com
  common snap_layout, snap_index, Dopt, Sopt, Popt, Nopt, Copt, Fopt, Eopt, Hopt

  if keyword_set(archive) then aflg = 1 else aflg = 0
  if keyword_set(burst) then aflg = 1
  if (size(units,/type) ne 7) then units = 'eflux'
  if keyword_set(energy) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if not keyword_set(zrange) then zrange = 0
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if (size(center,/type) eq 0) then center = 0
  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse
  if not keyword_set(smo) then smo = 1
  if keyword_set(norm) then nflg = 1 else nflg = 0
  if keyword_set(pot) then dopot = 1 else dopot = 0
  if keyword_set(label) then begin
    dolab = 1
    abin = string(indgen(16),format='(i2.2)')
    dbin = string(indgen(6),format='(i1)')
  endif else dolab = 0
  if keyword_set(plotlims) then plot_pa_lims = 1 else plot_pa_lims = 0
  
  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  if (size(spec,/type) ne 0) then begin
    dospec = 1
    swidth = (float(abs(spec)) > 30.)*!dtor
  endif else begin
    dospec = 0
    swidth = 30.*!dtor
  endelse

  case n_elements(center) of
    0 : begin
          lon0 = 180.
          lat0 = 0.
        end
    1 : begin
          lon0 = center[0]
          lat0 = 0.
        end
    else : begin
             lon0 = center[0]
             lat0 = center[1]
           end
  endcase

  case strupcase(units) of
    'COUNTS' : drange = [1e0, 1e5]
    'RATE'   : drange = [1e1, 1e6]
    'CRATE'  : drange = [1e1, 1e6]
    'FLUX'   : drange = [1e1, 3e8]
    'EFLUX'  : drange = [1e4, 3e9]
    'E2FLUX' : drange = [1e6, 1e11]
    'DF'     : drange = [1e-18, 1e-8]
    else     : drange = [0,0]
  endcase
  
  case strupcase(units) of
    'COUNTS' : ytitle = 'Raw Counts'
    'RATE'   : ytitle = 'Raw Count Rate'
    'CRATE'  : ytitle = 'Count Rate'
    'EFLUX'  : ytitle = 'Energy Flux (eV/cm2-s-ster-eV)'
    'E2FLUX' : ytitle = 'Energy Flux (eV/cm2-s-ster)'
    'FLUX'   : ytitle = 'Flux (1/cm2-s-ster-eV)'
    'DF'     : ytitle = 'Dist. Function (1/cm3-(km/s)3)'
    else     : ytitle = 'Unknown Units'
  endcase

  get_data,'alt',data=alt
  if (size(alt,/type) eq 8) then begin
    doalt = 1
    get_data,'sza',data=sza
    get_data,'lon',data=lon
    get_data,'lat',data=lat
    get_data,'sza',data=sza
  endif else doalt = 0

; Put up snapshot window(s)

  Twin = !d.window

  if (size(Dopt,/type) ne 8) then swe_snap_layout, 0
  IF keyword_set(dir) THEN wdy = 0.125*Nopt.ysize ELSE wdy = 0.
  window, /free, xsize=Popt.xsize, ysize=Popt.ysize, xpos=Popt.xpos, ypos=Popt.ypos
  Pwin = !d.window

  if (sflg) then begin
    window, /free, xsize=Nopt.xsize, ysize=Nopt.ysize + wdy, xpos=Nopt.xpos, ypos=Nopt.ypos
    Nwin = !d.window
  endif
  
  if (dflg) then begin
    window, /free, xsize=Copt.xsize, ysize=Copt.ysize, xpos=Copt.xpos, ypos=Copt.ypos
    Cwin = !d.window
  endif
  
  if (dospec) then begin
    window, /free, xsize=Fopt.xsize, ysize=Fopt.ysize, xpos=Fopt.xpos, ypos=Fopt.ypos
    Ewin = !d.window
  endif

; Set plot options

  limits = {no_interp:1, xlog:1, xrange:[3,5000], xstyle:1, xtitle:'Energy (eV)', $
            yrange:[0,180], ystyle:1, yticks:6, yminor:3, ytitle:'Pitch Angle (deg)', $
            zlog:1, ztitle:strupcase(units), xmargin:[15,15], charsize:1.4}

  if keyword_set(zrange) then str_element, limits, 'zrange', zrange, /add

; Select the first time, then get the PAD spectrum closest that time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime,trange,npoints=npts,/silent
  if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released

  if (size(trange,/type) eq 2) then begin  ; Abort before first time select.
    wdelete,Pwin                           ; Don't keep empty windows.
    if (sflg) then wdelete,Nwin
    if (dospec) then wdelete,Ewin
    wset,Twin
    return
  endif
  
  if keyword_set(dir) then begin
    if (aflg) then begin
      str_element, mvn_swe_pad_arc, 'time', ptime, success=ok
      if (not ok) then str_element, a3, 'time', ptime, success=ok
    endif else begin
      str_element, mvn_swe_pad, 'time', ptime, success=ok
      if (not ok) then str_element, a2, 'time', ptime, success=ok
    endelse
    if (not ok) then begin
      print,"No PAD data!"
      wdelete,Pwin                         ; Don't keep empty windows.
      if (sflg) then wdelete,Nwin
      if (dospec) then wdelete,Ewin
      wset,Twin
      return
    endif
    get_mvn_eph, ptime, pos, verbose=-1
  endif

  ok = 1

  while (ok) do begin

; Put up a PAD spectrogram
 
    wset, Pwin

    pad = mvn_swe_getpad(trange,archive=aflg,all=doall,/sum,units=units)
    
    if (size(pad,/type) eq 8) then begin
    
      case strupcase(pad.units_name) of
        'COUNTS' : zlo = 1
        'RATE'   : zlo = 1
        'CRATE'  : zlo = 1
        'FLUX'   : zlo = 1
        'EFLUX'  : zlo = 1e3
        'DF'     : zlo = 1e-18
        else     : zlo = 1
      endcase

      title = string(time_string(pad.time), pad.Baz*!radeg, pad.Bel*!radeg, $
                     format='(a19,5x,"Baz = ",f5.1,3x,"Bel = ",f5.1)')
      str_element,limits,'title',title,/add
      
      if (pad.time gt t_mtx[2]) then boom = 1 else boom = 0
      indx = where(obins[pad.k3d,boom] eq 0B, count)
      if (count gt 0L) then pad.data[*,indx] = !values.f_nan

      x = pad.energy[*,0]
      y = pad.pa*!radeg
      ylo = pad.pa_min*!radeg
      yhi = pad.pa_max*!radeg
      z = smooth(pad.data,[smo,1],/nan)
      
      if (nflg) then begin
        zmean = average(z,2,/nan) # replicate(1.,16)
        z /= (zmean > 1.)
      endif

; Add extra elements to force specplot to show the full pitch angle range

      y1 = fltarr(64,10)
      ylo1 = y1
      yhi1 = y1
      z1 = y1
      y2 = y1
      ylo2 = y1
      yhi2 = y1
      z2 = y1

      for i=0,63 do begin
        indx = sort(reform(y[i,0:7]))
        y1[i,1:8] = y[i,indx]
        z1[i,1:8] = z[i,indx]
        ylo1[i,1:8] = ylo[i,indx]
        yhi1[i,1:8] = yhi[i,indx]
        jndx = sort(reform(y[i,8:15])) + 8
        y2[i,1:8] = y[i,jndx]
        z2[i,1:8] = z[i,jndx]
        ylo2[i,1:8] = ylo[i,jndx]
        yhi2[i,1:8] = yhi[i,jndx]
      endfor
      y1[*,0] = ylo1[*,1]
      y1[*,9] = yhi1[*,8]
      z1[*,0] = z1[*,1]
      z1[*,9] = z1[*,8]

      y2[*,0] = ylo2[*,1]
      y2[*,9] = yhi2[*,8]
      z2[*,0] = z2[*,1]
      z2[*,9] = z2[*,8]

      str_element,limits,'zrange',success=ok
      if (not ok) then begin
        zmin = min(z, max=zmax, /nan) > zlo
        if (nflg) then begin
          zmin = 0.1
          zmax = 10.0
          str_element,limits,'zlog',1,/add
          str_element,limits,'ztitle','NORM',/add
        endif
        str_element,limits,'zrange',[zmin,zmax],/add
      endif

      !p.multi = [0,1,2]
      specplot,x,y1,z1,limits=limits
      if (dopot) then oplot,[pad.sc_pot,pad.sc_pot],[0,180],line=2
      if (plot_pa_lims) then begin
        oplot,[3,5000],[ylo1[63,1],ylo1[63,1]],line=2
        oplot,[3,5000],[yhi1[63,8],yhi1[63,8]],line=2
      endif
      limits.title = ''
      specplot,x,y2,z2,limits=limits
      if (dopot) then oplot,[pad.sc_pot,pad.sc_pot],[0,180],line=2
      if (plot_pa_lims) then begin
        oplot,[3,5000],[ylo2[63,1],ylo2[63,1]],line=2
        oplot,[3,5000],[yhi2[63,8],yhi2[63,8]],line=2
      endif

      !p.multi = 0

      if (sflg) then begin
        x = pad.energy[*,0]
        y = pad.pa*!radeg
        z = pad.data

        wset, Nwin
        de = min(abs(energy - x),i)
        energy = x[i]
        ylo = reform(pad.pa_min[i,*])*!radeg
        yhi = reform(pad.pa_max[i,*])*!radeg
        zi = z[i,*]/mean(z[i,*],/nan)

        col = [replicate(2,8), replicate(6,8)]

        plot_io,[-1.],[0.1],psym=3,xtitle='Pitch Angle (deg)',ytitle='Normalized', $
                yrange=[0.1,10.],ystyle=1,xrange=[0,180],xstyle=1,xticks=6,xminor=3, $
                title='', charsize=1.4, $
                pos=[0.140005, 0.124449 - (wdy/4000.), 0.958005, 0.937783 - (wdy/525.)]

        xyouts,140,7.5,string(energy,format='(f6.1," eV")'),charsize=1.4

        for j=0,15 do oplot,[ylo[j],yhi[j]],[zi[j],zi[j]],color=col[j]
        oplot,y[i,0:7],zi[0:7],linestyle=1,color=2
        oplot,y[i,0:7],zi[0:7],psym=4
        oplot,y[i,8:15],zi[8:15],linestyle=1,color=6
        oplot,y[i,8:15],zi[8:15],psym=4
      
        if (dolab) then begin
          alab = abin[pad.iaz]
          dlab = dbin[pad.jel]
          for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,8.,alab[j],color=2,align=0.5
          for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,7.,dlab[j],color=2,align=0.5

          for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.15,alab[j],color=6,align=0.5
          for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.13,dlab[j],color=6,align=0.5
        endif

        IF keyword_set(dir) THEN BEGIN
           et = time_ephemeris(pad.time)
           objects = ['MARS', 'MAVEN_SPACECRAFT']
           valid = spice_valid_times(et, object=objects)
           IF valid EQ 0B THEN BEGIN
              dprint, 'SPICE/kernels are invalid.'
              if (kflg) then begin
                 wdelete, Pwin
                 if (sflg) then wdelete, Nwin
                 if (dflg) then wdelete, Cwin
                 if (dospec) then wdelete, Ewin
              endif
              
              wset, Twin
              RETURN
           ENDIF
           undefine, et, objects

           IF pad.time LT t_mtx[2] THEN fswe = 'MAVEN_SWEA_STOW' $
           ELSE fswe = 'MAVEN_SWEA'
           bmso = REFORM(spice_vector_rotate(pad.magf, pad.time, fswe, 'MAVEN_MSO', verbose=-1))
           bmso /= SQRT(TOTAL(bmso*bmso))
           bgeo = REFORM(spice_vector_rotate(pad.magf, pad.time, fswe, 'IAU_MARS', verbose=-1))
           bgeo /= SQRT(TOTAL(bgeo*bgeo))
           
           ;get_mvn_eph, pad.time, pos, /silent
           idx = nn(pos.time, pad.time)
           lat = pos[idx].lat
           lon = pos[idx].elon
                      
           mtx = DBLARR(3, 3)
           mtx[0, 0] = -SIN(lon)
           mtx[1, 0] =  COS(lon)
           mtx[2, 0] =  0.d0
           mtx[0, 1] = -COS(lon) * SIN(lat)
           mtx[1, 1] = -SIN(lon) * SIN(lat)
           mtx[2, 1] =  COS(lat)
           mtx[0, 2] =  COS(lon) * COS(lat)
           mtx[1, 2] =  SIN(lon) * COS(lat)
           mtx[2, 2] =  SIN(lat)
           B_lg = TRANSPOSE(mtx ## TRANSPOSE(bgeo))
           
           B_azim = atan(B_lg[1],B_lg[0])*!radeg
           B_elev = asin(B_lg[2])*!radeg
           
           IF bmso[0] GT 0. THEN append_array, dirname, 'SUN' ELSE append_array, dirname, 'TAIL'
           IF B_elev GT 0. THEN append_array, dirname, 'UP' ELSE append_array, dirname, 'DOWN'
           IF -bmso[0] GT 0. THEN append_array, dirname, 'SUN' ELSE append_array, dirname, 'TAIL'
           IF -B_elev GT 0. THEN append_array, dirname, 'UP' ELSE append_array, dirname, 'DOWN'
           
           bperp = [bmso[1], bmso[2], -bgeo[0], -bgeo[1]]
           FOR j=0, 3 DO $
              IF bperp[j] GT 0. THEN append_array, dircol, 6 ELSE append_array, dircol, 2
           FOR j=0, 3 DO $
              XYOUTS, 17.5+45.*j, 15., dirname[j], color=!p.color, charsize=1.3, /data

           undefine, dircol
           PLOT, [-1., 1.], [-1., 1.], /nodata, pos=[0.285892, 0.874722, 0.39075, 1.], $
                 /noerase, yticks=1, xticks=1, xminor=1, yminor=1, xstyle=5, ystyle=5
           OPLOT, 0.9*COS(FINDGEN(361)*!DTOR), 0.9*SIN(FINDGEN(361)*!DTOR)
           angle = ATAN(bmso[2], bmso[1])
           IF bmso[0] GT 0. THEN dircol = 6 ELSE dircol = 2
           ARROW, 0., 0., 0.7*COS(angle), 0.7*SIN(angle), /data, color=dircol
           XYOUTS, 0., -1.3, 'MSO', /data, alignment=0.5
           XYOUTS, 0., 0.5, 'Z', /data, alignment=0.5
           XYOUTS, 0.6, 0., 'Y', /data, alignment=0.5

           undefine, dircol
           PLOT, [-1., 1.], [-1., 1.], /nodata, pos=[0.708061, 0.874722, 0.812919, 1.], $
                 /noerase, yticks=1, xticks=1, xminor=1, yminor=1, xstyle=5, ystyle=5
           OPLOT, 0.9*COS(FINDGEN(361)*!DTOR), 0.9*SIN(FINDGEN(361)*!DTOR)
           angle = ATAN(-bgeo[1], -bgeo[0])
           IF -bgeo[2] GT 0. THEN dircol = 6 ELSE dircol = 2
           ARROW, 0., 0., 0.7*COS(angle), 0.7*SIN(angle), /data, color=dircol
           XYOUTS, 0., -1.3, 'GEO', /data, alignment=0.5
           XYOUTS, 0., 0.5, 'N', /data, alignment=0.5
           XYOUTS, 0.6, 0., 'E', /data, alignment=0.5

           undefine, bmso, bgeo, bperp, angle
           undefine, idx, lat, lon, mtx
           undefine, dirname, dircol
        ENDIF  

        if (dflg) then begin
          ddd = mvn_swe_get3d(trange,archive=aflg,all=doall,/sum,units=units)
          indx = where(obins[*,boom] eq 0B, count)
          if (count gt 0L) then ddd.data[*,indx] = !values.f_nan

          de = min(abs(ddd.energy[*,0] - energy),ebin)
          z3d = reform(ddd.data[ebin,pad.k3d])  ; 3D mapped into PAD
          z3d = z3d/mean(z3d,/nan)

          col = [replicate(3,8), replicate(7,8)]

          for j=0,15 do oplot,[ylo[j],yhi[j]],[z3d[j],z3d[j]],color=col[j],line=2

          wset, Cwin
          d_dat = replicate(!values.f_nan,96)
          d_dat[pad.k3d] = reform(z[i,*])       ; PAD mapped into 3D
          ddd.data[ebin+1,*] = d_dat            ; overwrite adjacent energy bin
          ddd.energy[ebin+1,*] = ddd.energy[ebin,*]
          ddd.magf[0] = cos(pad.Baz)*cos(pad.Bel)
          ddd.magf[1] = sin(pad.Baz)*cos(pad.Bel)
          ddd.magf[2] = sin(pad.Bel)
          plot3d_new,ddd,lat0,lon0,ebins=[ebin,ebin+1]
        endif
      endif
            
      if (dospec) then begin
        wset, Ewin
        x = pad.energy[*,0]
        pndx = where(reform(pad.pa_max[63,*]) lt swidth, count)
        if (count gt 0L) then Fp = average(pad.data[*,pndx],2,/nan) $
                         else Fp = replicate(!values.f_nan,64)
        mndx = where(reform(pad.pa_min[63,*]) gt (!pi - swidth), count)
        if (count gt 0L) then Fm = average(pad.data[*,mndx],2,/nan) $
                         else Fm = replicate(!values.f_nan,64)
        
        plot_oo, [0.1,0.1], drange, xrange=[1,5000], yrange=drange, /ysty, $
          xtitle='Energy (eV)', ytitle=ytitle, title=time_string(pad.time), $
          charsize=1.4
        oplot, x, Fp, psym=10, color=6
        oplot, x, Fm, psym=10, color=2
        if (dopot) then oplot,[pad.sc_pot,pad.sc_pot],drange,line=2

        xs = 0.71
        ys = 0.90
        dys = 0.03
        pa_min = round(swidth*!radeg)
        pa_max = 180 - pa_min
        xyouts,xs,ys,string(pa_min, format='("0 - ",i2)'),charsize=1.2,/norm,color=6
        ys -= dys
        xyouts,xs,ys,string(pa_max, format='(i3," - 180")'),charsize=1.2,/norm,color=2
        ys -= dys

        if (doalt) then begin
          dt = min(abs(alt.x - pad.time), aref)
          xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=1.2,/norm
          ys -= dys
          xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=1.2,/norm
          ys -= dys
        endif
        
        if keyword_set(dir) then begin
          if (B_azim lt 0.) then B_azim = (B_azim + 360.) mod 360.
          xyouts,xs,ys,string(round(B_azim), format='("B_az = ",i4)'),charsize=1.2,/norm
          ys -= dys
          xyouts,xs,ys,string(round(B_elev), format='("B_el = ",i4)'),charsize=1.2,/norm          
          ys -= dys
        endif
      endif
    endif

; Get the next button press

    wset,Twin
    ctime,trange,npoints=npts,/silent
    if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(trange,/type) eq 5) then ok = 1 else ok = 0

  endwhile

  if (kflg) then begin
    wdelete, Pwin
    if (sflg) then wdelete, Nwin
    if (dflg) then wdelete, Cwin
    if (dospec) then wdelete, Ewin
  endif

  wset, Twin

  return

end
