FUNCTION sitl_stat_bufftable_cat, s, fomrng, cat=cat, isPending=isPending, status1=status1, title=title,$
  quiet = quiet, ttl=ttl,status2=status2
  compile_opt idl2

  if n_elements(cat) eq 0 then cat = 5

  idx3 = sitl_stat_cleanseg(s)
  
  ;select a CATEGORY X segments
  idx = where( (fomrng[cat,0] le s.FOM[idx3]) and (s.FOM[idx3] lt fomrng[cat,1]), ct, comp=nidx)
  if ct gt 0 then begin
    idx4 = idx3[idx]
    nidx4 = idx3[nidx]
    ct4 = ct
  endif else begin
    message,'Something is wrong'
  endelse

  ;filter by isPending
  idx5 = idx4 & nidx5 = nidx4 & ct5 = ct4
  if keyword_set(isPending) then begin
    idx = where( s.isPending[idx4] eq 1, ct5, comp=nidx)
    if ct5 gt 0 then begin 
      idx5 = idx4[idx]
      nidx5 = idx4[nidx]
    endif
  endif

  ;filter by status1
  idx6 = idx5 & nidx6 = nidx5 & ct6 = ct5
  if n_elements(status1) eq 1 then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx5]),strlowcase('*'+status1+'*')), ct6, comp=nidx)
    if ct6 gt 0 then begin
      idx6 = idx5[idx]
      nidx6 = idx5[nidx]
    endif
  endif

  ;filter by status2
  idxE = idx6 & nidxE = nidx6 & ctE = ct6
  if n_elements(status2) eq 1 then begin
    idx = where(strmatch(strlowcase(s.STATUS[idx6]),strlowcase('*'+status2+'*')), ctE, comp=nidx)
    if ctE gt 0 then begin
      idxE = idx6[idx]
      nidxE = idx6[nidx]
    endif
  endif

  if ctE eq 0 then begin
    Nsegs = 0L
    Nbuffs = 0L
    Tmin = 0.d0
    strTlast = ''
  endif else begin
    Nsegs = ctE; total number of segments
    Nbuffs = total(s.SEGLENGTHS[idxE]); total number of buffers
    Tmin = double(Nbuffs)/6.d0; total number of minutes
    strTlast = time_string(min(s.START[idxE],n))
  endelse
  
  ttlPrcnt = (n_elements(ttl) eq 0) ? 100.0 : 100.0*Tmin/ttl

  if ~keyword_set(quiet) then begin
    if n_elements(title) eq 0 then title = ''
    print, title, Nsegs, Nbuffs, Tmin, ttlPrcnt, strTlast, format='(A11," ",I8," ",I8," ",I8," ",F7.1," ",A20)'
  endif

  return, Tmin
END


PRO sitl_stat_bufftable, s, fomrng, isPending=isPending
  compile_opt idl2
  
  print,' Number of HELD segments/buffers as of '+time_string(systime(/utc,/seconds))+' UTC'
  print,' -------------------------------------------------------------------'
  print,'           ,   Nsegs,  Nbuffs,   [min],      %,  Oldest segment'
  print,' -------------------------------------------------------------------'

  Tmin  = sitl_stat_bufftable_cat(s,fomrng,isPending=isPending,/quiet)
  Tmin0 = sitl_stat_bufftable_cat(s,fomrng,cat=0,title='Category 0',isPending=isPending,ttl=Tmin)
  Tmin1 = sitl_stat_bufftable_cat(s,fomrng,cat=1,title='Category 1',isPending=isPending,ttl=Tmin)
  Tmin2 = sitl_stat_bufftable_cat(s,fomrng,cat=2,title='Category 2',isPending=isPending,ttl=Tmin)
  Tmin3 = sitl_stat_bufftable_cat(s,fomrng,cat=3,title='Category 3',isPending=isPending,ttl=Tmin)
  Tmin4 = sitl_stat_bufftable_cat(s,fomrng,cat=4,title='Category 4',isPending=isPending,ttl=Tmin)
  TminT = sitl_stat_bufftable_cat(s,fomrng,title='Total     ',isPending=isPending,ttl=Tmin)
 
END
