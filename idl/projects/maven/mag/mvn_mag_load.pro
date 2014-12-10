;+
;Procedure MVN_MAG_LOAD
;Usage:
;  MVN_MAG_LOAD,trange=trange
;-
pro mvn_mag_load,format,trange=trange,files=files,download_only=download_only,tplot=tplot_flag, $
        format=format_old, $
        source=source,verbose=verbose,L1_SAV=L1_SAV,pathname=pathname,data=str_all
        
if n_elements(tplot_flag) eq 0 then tplot_flag=1        
        
if keyword_set(format_old) then begin
  format = format_old
endif
if ~keyword_set(format) then format = 'L1_FULL'               

tstart=systime(1)

case strupcase(format) of 

'L1_FULL': begin
  pathname = 'maven/data/sci/mag/l1/sav/full/YYYY/MM/mvn_mag_l1_pl_full_YYYYMMDD.sav'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,/valid_only)
  if keyword_set(download_only) then break
  str_all=0
  ind=0
  for i = 0, n_elements(files)-1 do begin
    file = files[i]
    dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
    restore,file,verbose= keyword_set(verbose) && verbose ge 3
    append_array,str_all,data,index=ind
  endfor
  append_array,str_all,index=ind
  frame = header.spice_frame
  frame ='MAVEN_SPACECRAFT'
  if keyword_set(tplot_flag) then   store_data,'mvn_B_full',str_all.time,transpose(str_all.vec),dlimit={spice_frame:frame}
end


'L1_30SEC': begin
  pathname = 'maven/data/sci/mag/l1/sav/30sec/YYYY/MM/mvn_mag_l1_pl_30sec_YYYYMMDD.sav'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,/valid_only)
  if keyword_set(download_only) then break
  str_all=0
  ind=0
  for i = 0, n_elements(files)-1 do begin
    file = files[i]
    dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
    restore,file,verbose= keyword_set(verbose) && verbose ge 3
    append_array,str_all,data,index=ind
  endfor
  append_array,str_all,index=ind
;  frame = header.spice_frame
  frame ='MAVEN_SPACECRAFT'
  store_data,'mvn_B_30sec',str_all.time,transpose(str_all.vec),dlimit={spice_frame:frame}
 ; store_data,'mvn_Brms_30sec',rms_all.time,transpose(rms_all.vec)
end


'L1_1SEC': begin
  pathname = 'maven/data/sci/mag/l1/sav/1sec/YYYY/MM/mvn_mag_l1_pl_1sec_YYYYMMDD.sav'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,/valid_only)
  if keyword_set(download_only) then break
  str_all=0
  ind=0
  for i = 0, n_elements(files)-1 do begin
    file = files[i]
    dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
    restore,file,verbose= keyword_set(verbose) && verbose ge 3
    append_array,str_all,data,index=ind
  endfor
  append_array,str_all,index=ind
;  frame = header.spice_frame
  frame ='MAVEN_SPACECRAFT'
  store_data,'mvn_B_1sec',str_all.time,transpose(str_all.vec),dlimit={spice_frame:frame}
end


'L1_SAV': begin    ; Older style save files. Bigger and  Slower to read in 
  pathname = 'maven/data/sci/mag/l1_sav/YYYY/MM/mvn_mag_ql_YYYYdDOYpl_YYYYMMDD_v??_r??.sav'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,/valid_only)
  s = {time:0d,vec:[0.,0.,0.]}
  str_all=0
  for i = 0, n_elements(files)-1 do begin
      file = files[i]
      restore,file,/verbose
      nt = n_elements(data.time.sec)
      time = replicate(time_struct(0.),nt)
      time.year = data.time.year
      time.month= 1
      time.date =  data.time.doy
      time.hour = data.time.hour
      time.min  = data.time.min
      time.sec  = data.time.sec
      time.fsec = data.time.msec/1000d
      strs = replicate(s,nt)
      strs.time = time_double(time)  
      strs.vec[0] = data.ob_bpl.x
      strs.vec[1] = data.ob_bpl.y
      strs.vec[2] = data.ob_bpl.z
      append_array,str_all,strs,index=ind
  endfor
  append_array,str_all,index=ind
  frame = data.frame
  frame ='maven_spacecraft'
  store_data,'mvn_B',str_all.time,transpose(str_all.vec),dlimit={spice_frame:frame}
  end

'L2_CDF': begin
  pathname = 'maven/data/sci/mag/l1_cdf/YYYY/MM/mvn_mag_ql_YYYYdDOYpl_YYYYMMDD_v??_r??.cdf'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files)
  cdf2tplot,files
  end
  
else: begin
  dprint,format+' not found.'
  end

endcase
  
end




