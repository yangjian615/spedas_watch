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
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       SMO:           Number of energy bins to smooth over.
;
;       LABEL:         If set, label the anode and deflection bin numbers.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_pad_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_pad_snap, keepwins=keepwins, archive=archive, energy=energy, $
                  units=units, pad=pad, ddd=ddd, zrange=zrange, sum=sum, $
                  label=label, smo=smo

  @mvn_swe_com
  common snap_layout, Dopt, Sopt, Popt, Nopt, Copt, Eopt, Hopt

  if keyword_set(archive) then aflg = 1 else aflg = 0
  if (size(units,/type) ne 7) then units = 'crate'
  if keyword_set(energy) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if not keyword_set(zrange) then zrange = 0
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse
  if not keyword_set(smo) then smo = 1
  if keyword_set(label) then begin
    dolab = 1
    abin = string(indgen(16),format='(i2.2)')
    dbin = string(indgen(6),format='(i1)')
  endif else dolab = 0

; Put up snapshot window(s)

  Twin = !d.window

  if (size(Dopt,/type) ne 8) then swe_snap_layout, 0

  window, /free, xsize=Popt.xsize, ysize=Popt.ysize, xpos=Popt.xpos, ypos=Popt.ypos
  Pwin = !d.window

  if (sflg) then begin
    window, /free, xsize=Nopt.xsize, ysize=Nopt.ysize, xpos=Nopt.xpos, ypos=Nopt.ypos
    Nwin = !d.window
  endif
  
  if (dflg) then begin
    window, /free, xsize=Copt.xsize, ysize=Copt.ysize, xpos=Copt.xpos, ypos=Copt.ypos
    Cwin = !d.window
  endif

; Set plot options

  limits = {no_interp:1, xlog:1, xrange:[3,5000], xstyle:1, xtitle:'Energy (eV)', $
            yrange:[0,180], ystyle:1, yticks:6, yminor:3, ytitle:'Pitch Angle (deg)', $
            zlog:1, ztitle:strupcase(units), xmargin:[15,15], charsize:1.4}

  if keyword_set(zrange) then str_element, limits, 'zrange', zrange, /add

; Select the first time, then get the PAD spectrum closest that time

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime2,trange,npoints=npts,/silent,button=button

  if (size(trange,/type) eq 2) then begin  ; Abort before first time select.
    wdelete,Pwin                          ; Don't keep empty windows.
    if (sflg) then wdelete,Nwin
    wset,Twin
    return
  endif
  
  ok = 1

  while (ok) do begin

; Put up a PAD spectrogram
 
    wset, Pwin

    pad = mvn_swe_getpad(trange,archive=aflg,all=doall,/sum,units=units)

    if (size(pad,/type) eq 8) then begin
      title = string(time_string(pad.time), pad.Baz*!radeg, pad.Bel*!radeg, $
                     format='(a19,5x,"Baz = ",f5.1,3x,"Bel = ",f5.1)')
      str_element,limits,'title',title,/add

      x = pad.energy[*,0]
      y = pad.pa*!radeg
      z = smooth(pad.data,[smo,1])

      for i=0,63 do begin
        indx = sort(reform(y[i,0:7]))
        y[i,0:7] = y[i,indx]
        z[i,0:7] = z[i,indx]
        jndx = sort(reform(y[i,8:15])) + 8
        y[i,8:15] = y[i,jndx]
        z[i,8:15] = z[i,jndx]
      endfor

      !p.multi = [0,1,2]
      specplot,x,y[*,0:7],z[*,0:7],limits=limits
      limits.title = ''
      specplot,x,y[*,8:15],z[*,8:15],limits=limits
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
                title=string(energy,format='("Energy = ",f6.1," eV")'), charsize=1.4

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

        if (dflg) then begin
          ddd = mvn_swe_get3d(pad.time,archive=aflg,units=units)
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
          plot3d_new,ddd,0.,180.,ebins=[ebin,ebin+1]
        endif
      endif
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=npts,/silent,button=button
    if (size(trange,/type) eq 5) then ok = 1 else ok = 0

  endwhile

  if (kflg) then begin
    wdelete, Pwin
    if (sflg) then wdelete, Nwin
    if (dflg) then wdelete, Cwin
  endif

  wset, Twin

  return

end
