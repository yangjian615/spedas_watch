PRO eva_data_plot_options, paramlist

  imax = n_elements(paramlist)

  for i=0,imax-1 do begin
    tpv = paramlist[i]


    ; ESA spectrograms
    if strmatch(tpv,'*pe??_en_eflux*') then begin
      ylim, tpv,7,30000,1
      zlim, tpv, 1e+0,1e+6,1
      ;options, tpv,'ytitle', 'ESA'+strmid(tpv,6,1);pmms+'!Cele'
      ;options, tpv,'ysubtitle','[keV]'
      if strpos(tpv,'pee') ge 0 then begin
        zlim, tpv, 1e+4, 1e+9, 1
      endif
    endif

    ; SST
    if strpos(tpv,'ps') ge 0 then begin
      ;options, tpv,'ytitle', 'SST'+strmid(tpv,6,1);pmms+'!Cele'
      options, tpv,'ysubtitle','[keV]'
      spectrogram = 0
      options, tpv, 'spec', spectrogram
      if spectrogram then begin
        options, tpv, 'panel_size', 0.5
        ylim, tpv, 30000,800000,1
        zlim, tpv, 1e+0,1e+6,1
      endif
    endif

    ; FBK
    if strpos(tpv,'fb_') ge 0 then begin
      if strpos(tpv,'edc') ge 0 then tag = 'E'
      if strpos(tpv,'scm') ge 0 then tag = 'B'
      options, tpv, 'spec',1
      options, tpv, 'zlog',1
      ;options, tpv, 'ytitle', lbl+'!CWave!C'+tag
      ;options, tpv, 'ysubtitle', '[Hz]'
      ylim, tpv, 2, 2000, 1
      if strpos(tpv,'edc') ge 0 then begin
        zlim, tpv, 0.005, 5.
      endif
    endif

    if strpos(tpv,'_tdn') ge 0 then begin
      spectrogram = 1
      options, tpv, 'spec', spectrogram
      options, tpv, 'ystyle', 0
      if spectrogram then options, tpv, 'ystyle', 1
    endif

  endfor; for i=0,imax-1
END
