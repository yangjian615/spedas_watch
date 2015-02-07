; This function takes a pointer for multiple segment-index arrays
; and returns a list of valid (non -1, non NaN) segment-index sorted
FUNCTION eva_sitl_validate_getsegs, ptr_indices

  imax = n_elements(ptr_indices); how many arrays?
  
  ; get all indices
  seg_index = [-1]
  for i=0,imax-1 do begin
    seg_index = [seg_index, *(ptr_indices[i])]
  endfor

  idx = where((finite(seg_index) and seg_index ge 0),c)
  if c gt 0 then begin
    seg_index = seg_index[idx]; exclude -1 and NaN
    result = seg_index[UNIQ(seg_index, SORT(seg_index))]; uniq and sorted
  endif else result = -1
  return, result
END


