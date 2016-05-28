


function spp_swp_word_decom,buffer,n, mask=mask ,shft=shft
  val =  swap_endian(/swap_if_little_endian,  uint(buffer,n) )
  if n_elements(shft) ne 0 then val = ishft(val,shft)
  if n_elements(mask) ne 0 then val = val and mask
  return, val
end
