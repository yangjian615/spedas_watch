FUNCTION sitl_bakstr_stat_table, s, cat=cat, isPending=isPending, status1=status1, title=title,$
  quiet = quiet, ttl=ttl,status2=status2
  compile_opt idl2
  
  if n_elements(cat) eq 0 then cat = 5

  fomrng = fltarr(6,2)
  fomrng[0,*] = [200,256]
  fomrng[1,*] = [100,200]
  fomrng[2,*] = [ 50,100]
  fomrng[3,*] = [ 25, 50]
  fomrng[4,*] = [  0, 25]
  fomrng[5,*] = [  0,256]; in case FOM=255


  ;remove eratic segments 
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
  
  ;select a CATEGORY X segments
  idx = where( (fomrng[cat,0] le s.FOM[idx3]) and (s.FOM[idx3] lt fomrng[cat,1]), ct, comp=nidx)
  idx4 = idx3[idx]
  nidx4 = idx3[nidx]
  
  ;filter by isPending
  if keyword_set(isPending) then begin
    idx = where( s.isPending[idx4] eq 1, ct, comp=nidx)
    idx5 = idx4[idx]
    nidx5 = idx4[nidx] 
  endif else begin
    idx5 = idx4
    nidx5 = nidx4
  endelse
  
  ;filter by status1
  if n_elements(status1) eq 1 then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx5]),strlowcase('*'+status1+'*')), ct, comp=nidx)
    idx6 = idx5[idx]
    nidx6 = idx5[nidx]
  endif else begin
    idx6 = idx5
    nidx6 = nidx5
  endelse

  ;filter by status2
  if n_elements(status2) eq 1 then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx6]),strlowcase('*'+status2+'*')), ct, comp=nidx)
    idxE = idx6[idx]
    nidxE = idx6[nidx]
  endif else begin
    idxE = idx6
    nidxE = nidx6
  endelse
  
  Nsegs = ct; total number of segments
  Nbuffs = total(s.SEGLENGTHS[idxE]); total number of buffers
  Tmin = double(Nbuffs)/6.d0; total number of minutes
  
  ttlPrcnt = (n_elements(ttl) eq 0) ? 100.0 : 100.0*Tmin/ttl
  
  if ~keyword_set(quiet) then begin
    if n_elements(title) eq 0 then title = ''
    print, title, Nsegs, Nbuffs, Tmin, ttlPrcnt, format='(A10," ",I8," ",I8," ",I8," ",F7.1)'
  endif
  
  ; FOM vs time plot
  wx=[0]
  wy=[0]
  if (n_elements(status1) eq 1) and (n_elements(status2) eq 1) then begin
    if strmatch(strlowcase(status1),'complete') and $
       strmatch(strlowcase(status2),'finished') then begin
      wx = (time_double(s.FINISHTIME[idxE])-time_double(s.CREATETIME[idxE]))/86400.d0
      wy = s.FOM[idxE]
    endif; if complete and finished
  endif
  stat = {Tmin:Tmin, wx:wx, wy:wy}
  return, stat
END
