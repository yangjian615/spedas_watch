;+
;PROCEDURE:   swe_engy_snap
;PURPOSE:
;  Plots energy spectrum snapshots in a separate window for times selected with the 
;  cursor in a tplot window.  Hold down the left mouse button and slide for a movie 
;  effect.  This procedure depends on running swe_plot_dpu first, which unpacks the
;  A4 packets, creating 16 energy spectra per packet.
;
;  If housekeeping data exist (almost always the case), then they are displayed 
;  as text in a small separate window.
;
;USAGE:
;  swe_engy_snap
;
;INPUTS:
;
;KEYWORDS:
;       UNITS:         Plot the data in these units.  See mvn_swe_convert_units.
;                      Default = 'eflux'.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show shapshots of archive data (A5).
;
;       SPEC:          Named variable to hold the energy spectrum at the last time
;                      selected.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       POT:           Overplot an estimate of the spacecraft potential.  Must run
;                      mvn_swe_sc_pot first.
;
;       PDIAG:         Plot potential estimator in a separate window.
;
;       PXLIM:         X limits (Volts) for diagnostic plot.
;
;       DDD:           Create an energy spectrum from the nearest 3D spectrum and
;                      plot for comparison.
;
;       ABINS:         Angular bins to include/exclude (0=exclude, 1=include).  
;                      Can be a 16x6 (azimuth x elevation) array or a 96-element 
;                      3D angle array.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:47:24 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15675 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_engy_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_engy_snap, units=units, keepwins=keepwins, archive=archive, spec=spec, $
                   ddd=ddd, abins=abins, sum=sum, pot=pot, pdiag=pdiag, pxlim=pxlim, $
                   mb=mb,erange=erange

  @mvn_swe_com
  common snap_layout, Dopt, Sopt, Popt, Nopt, Copt, Eopt, Hopt
  
  if not keyword_set(archive) then aflg = 0 else aflg = 1
  if not keyword_set(units) then units = 'eflux'
  if keyword_set(sum) then npts = 2 else npts = 1
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if keyword_set(abins) then begin
    if (n_elements(abins) ne 96) then begin
      print,'ABINS must have 96 elements.'
      return
    endif
    indx = where(round(abins) ne 0, anorm)
    abins = replicate(0.,96)
    abins[indx] = 1.
  endif else begin
    anorm = 96
    abins = replicate(1.,anorm)
  endelse
  amask = replicate(1.,64) # abins
  anorm = float(anorm)
  
  if keyword_set(pot) then dopot = 1 else dopot = 0
  
  if keyword_set(mb) then mflg = 1 else mflg = 0
  
  if (n_elements(erange) lt 2) then begin
    emin = 16.
    emax = 80.
  endif else emin = min(erange[0:1], max=emax)
  
  if (n_elements(erange) gt 2) then begin
    emax2 = erange[2]
    dokap = 1
  endif else dokap = 0

  if keyword_set(pdiag) then begin
    get_data,'df',data=df
    get_data,'d2f',data=d2f,index=i
    if (i gt 0) then pflg = 1 else pflg = 0
  endif else pflg = 0
  
  if (data_type(mvn_swe_engy) ne 8) then mvn_swe_getspec
  
  if (aflg) then begin
    if (data_type(mvn_swe_engy_arc) ne 8) then begin
      print,"No SPEC archive data."
      return
    endif
  endif else begin
    if (data_type(mvn_swe_engy) ne 8) then begin
      print,"No SPEC survey data."
      return
    endif
  endelse

  if (data_type(swe_hsk) ne 8) then hflg = 0 else hflg = 1
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if keyword_set(archive) then aflg = 1 else aflg = 0

; Put up snapshot window(s)

  Twin = !d.window

  if (data_type(Dopt) ne 8) then swe_snap_layout, 0

  window, /free, xsize=Eopt.xsize, ysize=Eopt.ysize, xpos=Eopt.xpos, ypos=Eopt.ypos
  Ewin = !d.window

  if (hflg) then begin
    window, /free, xsize=Hopt.xsize, ysize=Hopt.ysize, xpos=Hopt.xpos, ypos=Hopt.ypos
    Hwin = !d.window
  endif
  
  if (pflg) then begin
    window, /free, xsize=Sopt.xsize, ysize=Sopt.ysize, xpos=Sopt.xpos, ypos=Sopt.ypos
    Pwin = !d.window
  endif

; Get the spectrum closest the selected time
  
  ok = 1

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  ctime2,trange,npoints=npts,/silent,button=button

  if (data_type(trange) eq 2) then begin
    wdelete,Ewin
    if (hflg) then wdelete,Hwin
    if (pflg) then wdelete,Pwin
    wset,Twin
    return
  endif
  
  if (aflg) then begin                                          ; closest ENGY
    old_units = mvn_swe_engy_arc[0].units_name
    mvn_swe_convert_units, mvn_swe_engy_arc, units
    units_name = mvn_swe_engy_arc[0].units_name

    if (npts gt 1) then begin
      tmin = min(trange, max=tmax)
      indx = where((mvn_swe_engy_arc.time ge tmin) and $
                   (mvn_swe_engy_arc.time le tmax), count)
      if (count eq 0L) then begin
        if (button eq 1) then print,'No SPEC archive data within selected time range.'
        ok = 0
      endif
      spec = mvn_swe_engy_arc[indx[0]]
      spec.time = mean(mvn_swe_engy_arc[indx].time)
      spec.data = total(mvn_swe_engy_arc[indx].data, 2, /nan)/float(count)
    endif else begin
      dt = min(abs(mvn_swe_engy_arc.time - trange[0]), iref)
      spec = mvn_swe_engy_arc[iref]
    endelse

    ymin = min(mvn_swe_engy_arc.data, max=ymax, /nan)           ; global yrange
    ymin = 10.^floor(alog10(ymin > 1.))
    ymax = 10.^ceil(alog10(ymax > 1.))
    yrange = [ymin, ymax]
  endif else begin
    old_units = mvn_swe_engy[0].units_name
    mvn_swe_convert_units, mvn_swe_engy, units
    units_name = mvn_swe_engy[0].units_name

    if (npts gt 1) then begin
      tmin = min(trange, max=tmax)
      indx = where((mvn_swe_engy.time ge tmin) and $
                   (mvn_swe_engy.time le tmax), count)
      if (count eq 0L) then begin
        if (button eq 1) then print,'No SPEC survey data within selected time range.'
        ok = 0
      endif
      spec = mvn_swe_engy[indx[0]]
      spec.time = mean(mvn_swe_engy[indx].time)
      spec.data = total(mvn_swe_engy[indx].data, 2, /nan)/float(count)
    endif else begin
      dt = min(abs(mvn_swe_engy.time - trange[0]), iref)
      spec = mvn_swe_engy[iref]
    endelse

    ymin = min(mvn_swe_engy.data, max=ymax, /nan)               ; global yrange
    ymin = 10.^floor(alog10(ymin > 1.))
    ymax = 10.^ceil(alog10(ymax > 1.))
    yrange = [ymin, ymax]
  endelse
  
  case strupcase(units_name) of
    'COUNTS' : ytitle = 'Raw Counts'
    'RATE'   : ytitle = 'Raw Count Rate'
    'CRATE'  : ytitle = 'Count Rate'
    'EFLUX'  : begin
                 ytitle = 'Energy Flux (eV/cm2-s-ster-eV)'
                 yrange[0] = 1.e4
               end
    'FLUX'   : ytitle = 'Flux (1/cm2-s-ster-eV)'
    'DF'     : begin
                 ytitle = 'Dist. Function (1/cm3-(km/s)3)'
                 yrange = [1.e-19, 1.e-8]
               end
    else     : ytitle = 'Unknown Units'
  endcase

  if (hflg) then dt = min(abs(swe_hsk.time - spec.time), jref)  ; closest HSK

  while (ok) do begin

    x = spec.energy
    y = spec.data
        
    wset, Ewin

; Put up an Energy Spectrum

    psym = 10

    plot_oo,x,y,yrange=yrange,/ysty,xtitle='Energy (eV)',ytitle=ytitle, $
            charsize=1.4,psym=psym

    if (dflg) then begin
      if (npts gt 1) then ddd = mvn_swe_get3d([tmin,tmax],/all,/sum) $
                     else ddd = mvn_swe_get3d(spec.time)
      ddd = conv_units(ddd, units_name)
      dt = min(abs(swe_hsk.time - ddd.time), kref)
      spec3d = total(ddd.data*amask,2)/anorm
      oplot,ddd.energy[*,0],spec3d,psym=psym,color=4
    endif

    if (dopot) then oplot,[spec.sc_pot,spec.sc_pot],yrange,line=2,color=6
    
    if (mflg) then begin
      e1 = spec.energy
      eflux = spec.data
      p = swe_maxbol()
      p.pot = spec.sc_pot      
      indx = where((e1 gt emin) and (e1 lt emax))
      fit,e1[indx],eflux[indx],func='swe_maxbol',par=p,names='N T',/silent
      if (dokap) then begin
        indx = where((e1 gt emin) and (e1 lt emax2))
        fit,e1[indx],eflux[indx],func='swe_maxbol',par=p,names='N T K_N K_VH K_K'
      endif
      oplot,e1[indx],swe_maxbol(e1[indx],par=p),color=6,thick=2
      xyouts,0.75,0.90,string(p.n,format='("N = ",f4.1)'),color=6,charsize=1.2,/norm
      xyouts,0.75,0.87,string(p.T,format='("T = ",f4.1)'),color=6,charsize=1.2,/norm
      xyouts,0.75,0.84,string(p.pot,format='("V = ",f4.1)'),color=6,charsize=1.2,/norm
    endif
    
    if (pflg) then begin
      wset, Pwin
      
      if not keyword_set(pxlim) then xlim = [0,30]
      xlim = [min(xlim),max(xlim)]

      indx = where((df.v ge xlim[0]) and (df.v le xlim[1]))
      ymin = min(df.y[indx],/nan) < min(d2f.y[indx],/nan)
      ymax = max(df.y[indx],/nan) > max(d2f.y[indx],/nan)
      ylim = [floor(100.*ymin), ceil(100.*ymax)]/100.

      dt = min(abs(d2f.x - trange[0]), kref)
      px = reform(d2f.v[kref,*])
      py = reform(df.y[kref,*])
      py2 = reform(d2f.y[kref,*])
      
      title = string(pot,format='("Potential = ",f5.1," V")')
      plot,px,py,xtitle='Potential (V)',ytitle='dF and d2F',$
                  xrange=xlim,/xsty,yrange=ylim,/ysty,title=title,charsize=1.4
      oplot,[pot,pot],ylim,line=2,color=6
      oplot,px,py2,color=4
      pmax = max(py2,i)
      oplot,[px[i],px[i]],ylim,line=2,color=4
      oplot,xlim,[0,0],line=2

    endif

; Print out housekeeping in another window

    if (hflg) then begin
      wset, Hwin
      
      csize = 1.4
      x1 = 0.05
      x2 = 0.75
      x3 = x2 - 0.12
      y1 = 0.95 - 0.035*findgen(28)
  
      fmt1 = '(f7.2," V")'
      fmt2 = '(f7.2," C")'
      fmt3 = '(i2)'
      
      j = jref
    
      tabnum = mvn_swe_tabnum(swe_hsk[j].chksum[swe_hsk[j].ssctl])
          
      erase
      xyouts,x1,y1[0],/normal,"SWEA Housekeeping",charsize=csize
      xyouts,x1,y1[1],/normal,time_string(swe_hsk[j].time),charsize=csize
      xyouts,x1,y1[3],/normal,"P28V",charsize=csize
      xyouts,x2,y1[3],/normal,string(swe_hsk[j].P28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[4],/normal,"MCP28V",charsize=csize
      xyouts,x2,y1[4],/normal,string(swe_hsk[j].MCP28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[5],/normal,"NR28V",charsize=csize
      xyouts,x2,y1[5],/normal,string(swe_hsk[j].NR28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[6],/normal,"MCPHV",charsize=csize
      xyouts,x2,y1[6],/normal,string(sigfig(swe_hsk[j].MCPHV,3),format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[7],/normal,"NRV",charsize=csize
      xyouts,x2,y1[7],/normal,string(swe_hsk[j].NRV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[9],/normal,"P12V",charsize=csize
      xyouts,x2,y1[9],/normal,string(swe_hsk[j].P12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[10],/normal,"N12V",charsize=csize
      xyouts,x2,y1[10],/normal,string(swe_hsk[j].N12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[11],/normal,"P5AV",charsize=csize
      xyouts,x2,y1[11],/normal,string(swe_hsk[j].P5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[12],/normal,"N5AV",charsize=csize
      xyouts,x2,y1[12],/normal,string(swe_hsk[j].N5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[13],/normal,"P5DV",charsize=csize
      xyouts,x2,y1[13],/normal,string(swe_hsk[j].P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[14],/normal,"P3P3DV",charsize=csize
      xyouts,x2,y1[14],/normal,string(swe_hsk[j].P3P3DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[15],/normal,"P2P5DV",charsize=csize
      xyouts,x2,y1[15],/normal,string(swe_hsk[j].P2P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[17],/normal,"ANALV",charsize=csize
      xyouts,x2,y1[17],/normal,string(swe_hsk[j].ANALV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[18],/normal,"DEF1V",charsize=csize
      xyouts,x2,y1[18],/normal,string(swe_hsk[j].DEF1V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[19],/normal,"DEF2V",charsize=csize
      xyouts,x2,y1[19],/normal,string(swe_hsk[j].DEF2V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[20],/normal,"V0V",charsize=csize
      xyouts,x2,y1[20],/normal,string(swe_hsk[j].V0V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[22],/normal,"ANALT",charsize=csize
      xyouts,x2,y1[22],/normal,string(swe_hsk[j].ANALT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[23],/normal,"LVPST",charsize=csize
      xyouts,x2,y1[23],/normal,string(swe_hsk[j].LVPST,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[24],/normal,"DIGT",charsize=csize
      xyouts,x2,y1[24],/normal,string(swe_hsk[j].DIGT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[26],/normal,"SWEEP TABLE",charsize=csize
      xyouts,x2,y1[26],/normal,string(tabnum,format=fmt3),charsize=csize,align=1.0
    endif

; Get the next button press

    wset,Twin
    ctime2,trange,npoints=npts,/silent,button=button

    if (data_type(trange) eq 5) then begin
  
      if (aflg) then begin
        if (npts gt 1) then begin
          tmin = min(trange, max=tmax)
          indx = where((mvn_swe_engy_arc.time ge tmin) and $
                       (mvn_swe_engy_arc.time le tmax), count)
          if (count eq 0L) then begin
            if (button eq 1) then print,'No SPEC archive data within selected time range.'
            ok = 0
          endif else begin
            spec = mvn_swe_engy_arc[indx[0]]
            spec.time = mean(mvn_swe_engy_arc[indx].time)
            spec.data = total(mvn_swe_engy_arc[indx].data, 2, /nan)/float(count)
          endelse
        endif else begin
          dt = min(abs(mvn_swe_engy_arc.time - trange[0]), iref)
          spec = mvn_swe_engy_arc[iref]
        endelse
      endif else begin
        if (npts gt 1) then begin
          tmin = min(trange, max=tmax)
          indx = where((mvn_swe_engy.time ge tmin) and $
                       (mvn_swe_engy.time le tmax), count)
          if (count eq 0L) then begin
            if (button eq 1) then print,'No SPEC survey data within selected time range.'
            ok = 0
          endif else begin
            spec = mvn_swe_engy[indx[0]]
            spec.time = mean(mvn_swe_engy[indx].time)
            spec.data = total(mvn_swe_engy[indx].data, 2, /nan)/float(count)
          endelse
        endif else begin
          dt = min(abs(mvn_swe_engy.time - trange[0]), iref)
          spec = mvn_swe_engy[iref]
        endelse
      endelse

      if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)

    endif else ok = 0

  endwhile
  
  if (aflg) then mvn_swe_convert_units, mvn_swe_engy_arc, old_units $
            else mvn_swe_convert_units, mvn_swe_engy, old_units

  if (kflg) then begin
    wdelete, Ewin
    if (hflg) then wdelete, Hwin
    if (pflg) then wdelete, Pwin
  endif

  wset, Twin

  return

end
