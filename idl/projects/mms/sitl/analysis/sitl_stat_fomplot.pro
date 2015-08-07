FUNCTION sitl_stat_fomplot_status, s, isPending=isPending, status1=status1, status2=status2
  compile_opt idl2

  idx3 = sitl_stat_cleanseg(s)
  
  ;filter by isPending
  if n_elements(isPending) eq 1 then begin
    idx = where( s.isPending[idx3] eq isPending, ct, comp=nidx)
    idx4 = idx3[idx]
  endif else begin
    idx4 = idx3
  endelse

  ;filter by status1
  idx5 = idx4
  if n_elements(status1) eq 1 then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx4]),strlowcase('*'+status1+'*')), ct, comp=nidx)
    if ct gt 0 then begin
      idx5 = idx4[idx]
      if strmatch(strlowcase(status1),'complete') then begin; When 'complete', it should not be 'incomplete'
        idx = where(~strmatch(strlowcase(s.STATUS[idx5]),strlowcase('*incomplete*')), ct, comp=nidx)
        if ct gt 0 then begin
          idx5 = idx5[idx]
        endif
      endif
    endif; if ct gt 0
  endif; if status1

  ;filter by status2
  idx6 = idx5
  if (n_elements(status2) eq 1) and (ct gt 0) then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx5]),strlowcase('*'+status2+'*')), ct, comp=nidx)
    if ct gt 0 then begin
      idx6 = idx5[idx]
      if strmatch(strlowcase(status2),'complete') then begin; When 'complete', it should not be 'incomplete'
        idx = where(~strmatch(strlowcase(s.STATUS[idx6]),strlowcase('*incomplete*')), ct, comp=nidx)
        if ct gt 0 then begin
          idx6 = idx6[idx]
        endif
      endif
    endif; if ct gt 0
  endif; if status2

  idxE = idx6

  if ct eq 0 then begin
    return, {x:[0], y:[0], idx:-1, nmax:0, Nsegs:0L}
  endif


  ; FOM vs time plot
  strFinish = s.FINISHTIME[idxE]
  i = where(strlen(strFinish) eq 0,c)
  dblFinish = time_double(strFinish)
  if c gt 0 then begin
    dblFinish[i] = systime(/utc,/seconds)
  endif
  ;wx = (time_double(s.FINISHTIME[idxE])-time_double(s.CREATETIME[idxE]))/86400.d0
  wx = (dblFinish-time_double(s.CREATETIME[idxE]))/86400.d0
  wy = s.FOM[idxE]
  Nsegs = long(total(s.SEGLENGTHS[idxE]))
  nmax = n_elements(wx)
  if nmax gt 0 then begin
    for n=0,nmax-1 do begin
      if wx[n] lt 0 then begin
        print, idxE[n],' ', s.STATUS[idxE[n]], ', isPending=',s.isPENDING[idxE[n]]
      endif
    endfor
  endif else begin
    wx = [0]
    wy = [0]
  endelse
  return, {x:[wx], y:[wy], idx:idxE, nmax:nmax, Nsegs:Nsegs}
END

PRO sitl_stat_fomplot, s, tr=tr
  compile_opt idl2

  ;---------------
  ; PREPARE PLOT
  ;---------------
  A = FINDGEN(17) * (!PI*2/16.); Make a vector of 16 points, A[i] = 2pi/16:
  USERSYM, COS(A), SIN(A), /FILL; Define the symbol, unit circle, filled
  charsize = 1.2
  plot,[0,30],[0,250],/nodata,xtitle='Number of days to FINISH',ytitle='FOM', color=0

  ;---------------
  ; COMPLETED
  ;---------------
  complete = sitl_stat_fomplot_status(s,status1='COMPLETE')
  oplot, complete.x, complete.y, psym=8,color=4
  xyouts, 20,200, 'TRANSMITTED: '+string(complete.NSEGS,format='(I8)'), charsize=charsize, color=4,/data

  ;---------------
  ; PENDING
  ;---------------
  pending = sitl_stat_fomplot_status(s,isPending=1)
  oplot, pending.x, pending.y, psym=8, color=0
  xyouts, 20,190, 'PENDING:     '+string(pending.NSEGS,format='(I8)'), charsize=charsize, color=0,/data

  ;---------------
  ; DEMOTED
  ;---------------
  demoted = sitl_stat_fomplot_status(s,status1='DEMOTED')
  if demoted.NMAX gt 0 then begin
    oplot, demoted.x, demoted.y, psym=8, color=6
    for n=0,demoted.NMAX-1 do begin
      print, 'n=',n,',',s.STATUS[demoted.IDX[n]]
    endfor
  endif
  xyouts, 20,180, 'OVERWRITTEN: '+string(demoted.NSEGS,format='(I8)'), charsize=charsize, color=6,/data

END
