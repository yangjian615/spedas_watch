pro erg_remove_duplicated_tframe, tvars 
  
  if n_params() ne 1 then return 
  tvars = tnames(tvars) 
  if strlen(tvars[0]) lt 1 then return 
  
  for i=0L, n_elements(tvars)-1 do begin
    tvar = tvars[i] 
    
    get_data, tvar, time, data, dl=dl, lim=lim 
    n = n_elements(time) 
    dt = [ time[1:(n-1)], time[n-1]+1 ] - time[0:(n-1)] 
    idx = where( abs(dt) gt 0d, n1 ) 
    
    if n ne n1 then begin
      newtime = time[idx] 
      if size(data,/n_dim) eq 1 then begin
        newdata = data[idx]
      endif else newdata = data[ idx, *] 
      store_data, tvar, data={x:newtime, y:newdata},dl=dl, lim=lim
    endif
    
    
  endfor
  
  return
end