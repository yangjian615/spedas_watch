pro spp_save_data,dynarray,structure,pname=pname,apdat=apdat

  if keyword_set(pname) && apdat.rt_flag && apdat.rt_tags then begin
    ;if structure.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  endif

  if isa(dynarray,'DynamicArray') then begin
    dynarray.append,structure
  endif


end