; A and B can be either FOMStr or BAKStr
FUNCTION eva_sitl_strct_comp, A, B
  ntagA = n_tags(A)
  ntagB = n_tags(B)
  if ntagA ne ntagB then return, 'modified'
  
  NsegsA = n_elements(A.FOM)
  NsegsB = n_elements(B.FOM)
  if NsegsA ne NsegsB then return, 'modified'
  
  if ~array_equal(A.SEGLENGTHS, B.SEGLENGTHS) then return, 'modified'
  
  ; Further check if BAKStr
  tn = tag_names(A)
  idx = where(strmatch(tn,'FOMSKEW'),ct_fom); FOMStr ?
  if ct_fom eq 0 then begin; if BAKStr
  
    equal = array_equal(A.STATUS, B.STATUS)
    if equal eq 0 then return, 'modified'
    
    equal = array_equal(A.FOM, B.FOM)
    if equal eq 0 then return, 'modified'
  endif
  
  return, 'unchanged'
END
