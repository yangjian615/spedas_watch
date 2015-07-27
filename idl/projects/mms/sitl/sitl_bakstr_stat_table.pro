FUNCTION sitl_bakstr_stat_table_cat, s, fomRange,strlbl, isPending=isPending
  compile_opt idl2
  fomRange = float(fomRange)
  if keyword_set(isPending) then begin
    idx = where((s.isPending eq 1) and $
      (fomRange[0] le s.FOM) and (s.FOM le fomRange[1]), ct)
  endif else begin
    idx = where($
      (~s.isPENDING) and $
      (~strmatch(s.STATUS,'*trimmed*')) and $
      (~strmatch(s.STATUS,'*subsumed*')) and $
      (fomRange[0] le s.FOM) and (s.FOM le fomRange[1]), ct)
  endelse
  if ct gt 0 then begin
    Nsegs = ct
    Nbuffs = long(total(s.NUMEVALCYCLES[idx]))
    Tminutes = double(Nbuffs)/6.d0
    Toldest = time_string(min(s.START[idx],/NAN))
  endif else begin
    Nsegs = ct
    Nbuffs = 0L
    Tminutes = 0.d0
    Toldest = ''
  endelse
  cat = {Nsegs:Nsegs, Nbuffs:Nbuffs, Tminutes:Tminutes, Toldest:Toldest, strlbl:strlbl}
  return, cat
END

FUNCTION sitl_bakstr_stat_table, isPending=isPending
  compile_opt idl2

  get_data,'mms_stlm_bakstr',data=D,dl=dl,lim=lim
  
  s = lim.UNIX_BAKSTR_MOD
  
  ;----------
  ; TOTAL 
  ;----------

  if keyword_set(isPending) then begin
    idx = where(s.isPending eq 1,$
      ct,comp=idx_comp, ncomp=ct_comp)
  endif else begin
    idx = where($
      ~strmatch(s.STATUS,'*trimmed*') and $
      ~strmatch(s.STATUS,'*subsumed*'), $
      ct,comp=idx_comp, ncomp=ct_comp)
  endelse
  
  if ct gt 0 then begin
    Nsegs = ct
    Nbuffs = long(total(s.NUMEVALCYCLES[idx])); Total number of buffers
    Tminutes = double(Nbuffs)/6.d0 ; Total minutes 
    Toldest = time_string(min(s.START[idx],/NAN)); Oldest segment start time
  endif else begin
    Nsegs = ct
    Nbuffs = 0L
    Tminutes = 0.d0
    Toldest = ''
  endelse
  catT = {Nsegs:Nsegs,Nbuffs:Nbuffs, Tminutes:Tminutes, Toldest:Toldest, strlbl:'Total     '}

  ;------------------------
  ; Completed (CATEGORIES) 
  ;------------------------
  fomLow = [200,100,50,25,0]
  fomHigh = [254,199,99,49,24]
  cat0 = sitl_bakstr_stat_table_cat(s,[200,254],'Category 0',isPending=isPending)
  cat1 = sitl_bakstr_stat_table_cat(s,[100,199],'Category 1',isPending=isPending)
  cat2 = sitl_bakstr_stat_table_cat(s,[ 50, 99],'Category 2',isPending=isPending)
  cat3 = sitl_bakstr_stat_table_cat(s,[ 25, 49],'Category 3',isPending=isPending)
  cat4 = sitl_bakstr_stat_table_cat(s,[  0, 24],'Category 4',isPending=isPending)
  
  cat_arr = [cat0, cat1, cat2, cat3, cat4, catT]
  
  return, cat_arr
END
