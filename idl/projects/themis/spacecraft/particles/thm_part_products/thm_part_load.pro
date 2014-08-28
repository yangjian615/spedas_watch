;+
;Name:
;  thm_part_load
;
;Purpose:
;  Load ESA or SST particle data.
;
;Calling Sequence:
;  thm_part_load, [probe=probe], [datatype=datatype], [instrument=instrument], 
;                 [trange=trange], [sst_cal=sst_cal]
;
;Keywords:
;  probe: String or string array containing spacecraft designation (e.g. 'a')
;  datatype: String or string array containing data type specification (e.g. 'peif')
;  trange: Two element array specifying the desired time range
;  sst_cal: Flag to use improved SST calibrations
;  forceload: Flag to ignore check for existing data
;  
;Notes:
;  -If all requested data is already present the load will be 
;   skipped unless the forceload keyword is set.
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-11-15 11:15:58 -0800 (Fri, 15 Nov 2013) $
;$LastChangedRevision: 13539 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_part_load.pro $
;-


pro thm_part_load, probe=probe, datatype=datatype, trange=trange, $
                   sst_cal=sst_cal, forceload=forceload, _extra=_extra

    compile_opt idl2
  
  
  ;get instrument selection(s)
  if keyword_set(datatype) then begin
  
    esa = total( stregex(datatype, 'pe..', /bool,/fold_case) ) gt 0
    
    sst = total( stregex(datatype, 'ps..', /bool,/fold_case) ) gt 0
    
    if sst && undefined(sst_cal) && strlowcase(strmid(datatype,3,1)) ne 'r' then begin
      sst_cal = 1
    endif
    
  endif
  
  
  ;check if requested data is already present
  if keyword_set(probe) and keyword_set(datatype) and ~keyword_set(forceload) then begin
    
    for i=0, n_elements(probe)-1 do begin
    
      for j=0, n_elements(datatype)-1 do begin
      
        ok = thm_part_check_trange(probe, datatype, trange, sst_cal=sst_cal, fail=fail)
        
        if ~ok then break
        
      endfor
      
      if ~ok then break
      
    endfor
    
    ;if check never failed then all requested data is present
    if ok then return
    
  endif


  ;load esa
  if keyword_set(esa) then begin
  
    thm_load_esa_pkt,probe=probe,trange=trange,datatype=datatype, _extra=_extra
  
  endif
  
  
  ;load sst
  if keyword_set(sst) then begin
  
    if keyword_set(sst_cal) then begin

      thm_load_sst2,probe=probe,trange=trange,datatype=datatype, _extra=_extra
    
    endif else begin
    
      thm_load_sst,probe=probe,trange=trange,datatype=datatype, _extra=_extra
    
    endelse
  
  endif
  
  
  
end