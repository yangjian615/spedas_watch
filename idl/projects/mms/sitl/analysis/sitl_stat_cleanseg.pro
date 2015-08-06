FUNCTION sitl_stat_cleanseg, s
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

  return, idx3
END
