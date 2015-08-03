FUNCTION sitl_bakstr_stat_fomt, s, isPending=isPending, status1=status1, status2=status2
  compile_opt idl2
  
  ;remove error segments
  idx = where(s.SEGLENGTHS ne 429496728,ct,comp=nidx)
  idx0 = idx; NON-ERATIC
  nidx0 = nidx; ERATIC
  
  ;remove TRIMMED segments
  idx = where(~strmatch(strlowcase(s.STATUS[idx0]),'*trimmed*'),ct,comp=nidx)
  idx1 = idx0[idx]; NOT-TRIMMED segments
  nidx1 = nidx0[nidx]; TRIMMED segments
  
  ;remove SUBSUMED segments
  idx = where(~strmatch(strlowcase(s.STATUS[idx1]),'*subsumed*'), ct, comp=nidx)
  idx2 = idx1[idx]; NOT-SUBSUMED segments
  nidx2 = idx1[nidx]; SUBSUMED segments
  
  ;remove DELETED segments
  idx = where(~strmatch(strlowcase(s.STATUS[idx2]),'*deleted*'), ct, comp=nidx)
  idx3 = idx2[idx]
  nidx3 = idx2[nidx]
  
  ;filter by isPending
  if n_elements(isPending) eq 1 then begin
    idx = where( s.isPending[idx3] eq isPending, ct, comp=nidx)
    idx4 = idx3[idx]
    nidx4 = idx3[nidx]
  endif else begin
    idx4 = idx3
    nidx4 = nidx3
  endelse

  ;filter by status1
  idx5 = idx4
  nidx5 = nidx4
  if n_elements(status1) eq 1 then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx4]),strlowcase('*'+status1+'*')), ct, comp=nidx)
    if ct gt 0 then begin
      idx5 = idx4[idx]
      nidx5 = idx4[nidx]
      if strmatch(strlowcase(status1),'complete') then begin; When 'complete', it should not be 'incomplete'
        idx = where(~strmatch(strlowcase(s.STATUS[idx5]),strlowcase('*incomplete*')), ct, comp=nidx)
        if ct gt 0 then begin
          idx5 = idx5[idx]
          nidx5 = idx5[nidx]
        endif
      endif
    endif; if ct gt 0
  endif; if status1

  ;filter by status2
  idx6 = idx5
  nidx6 = nidx5
  if (n_elements(status2) eq 1) and (ct gt 0) then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx5]),strlowcase('*'+status2+'*')), ct, comp=nidx)
    if ct gt 0 then begin
      idx6 = idx5[idx]
      nidx6 = idx5[nidx]
      if strmatch(strlowcase(status2),'complete') then begin; When 'complete', it should not be 'incomplete'
        idx = where(~strmatch(strlowcase(s.STATUS[idx6]),strlowcase('*incomplete*')), ct, comp=nidx)
        if ct gt 0 then begin
          idx6 = idx6[idx]
          nidx6 = idx6[nidx]
        endif
      endif
    endif; if ct gt 0
  endif; if status2
  
  idxE = idx6
  nidxE = nidx6
  
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
