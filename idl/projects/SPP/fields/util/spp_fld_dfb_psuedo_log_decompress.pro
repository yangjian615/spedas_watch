function spp_fld_dfb_psuedo_log_decompress, compressed

  dim_compressed = size(compressed,/dim)
  
  compressed = long(compressed)

  exponent = compressed / 2l^4

  mantissa = compressed MOD 2l^4
  
  exp_zero_ind = where(exponent EQ 0, exp_zero_count, $
    complement = exp_nonzero_ind, ncomplement = exp_nonzero_count)
  
  decompressed = lonarr(dim_compressed)
  
  if exp_zero_count GT 0 then begin
    
    decompressed[exp_zero_ind] = mantissa[exp_zero_ind]

  endif

  if exp_nonzero_count GT 0 then begin
    
    decompressed[exp_nonzero_ind] = $
      (mantissa[exp_nonzero_ind] + 2l^4) * 2l^(exponent[exp_nonzero_ind] - 1l)
    
  endif

  return, decompressed

end