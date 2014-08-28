;Keep track of the parts of an HSBM buffer
;Input:
;  t - timestamp, scalar double. sec+subsec/2^16
;  d - HSBM data, array of signed 16 bit integers
;  /compressed - set if the data is compressed 
;In/out:
;  hsbm_t - array of all HSBM xF timestamps
;  hsbm_p - array of pointers to decompressed data of all HSBM xF packets  
pro mvn_lpw_r_package_hsbm,t,d,hsbm_t,hsbm_p,compressed=compressed
  if n_elements(hsbm_t) eq 0 then hsbm_t=t else hsbm_t=[hsbm_t,t]
  if keyword_set(compressed) then p=ptr_new(mvn_lpw_r_multi_free_decompress(d,0,32)) else p=ptr_new(d)
  if n_elements(hsbm_p) eq 0 then hsbm_p=p else hsbm_p=[hsbm_p,p]
end