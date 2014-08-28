function goes_fixpath,p
; Trim leading and trailing whitespace
fp=strtrim(p,2)
; Ensure path ends with a forward slash
if (strmid(fp,0,1,/reverse_offset) NE '/') then fp = fp+'/'
; Return cleaned up path
return, fp
end

