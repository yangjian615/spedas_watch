pro mvn_mag_load,format=format,trange=trange,files=files,download_only=download_only, $
        source=source,verbose=verbose,L1_SAV=L1_SAV,pathnames=pathnames,data=str_all
        
if ~keyword_set(format) then format = 'L1_SAV'               

tstart=systime(1)

case strupcase(format) of 

'L1_SAV': begin
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
  store_data,'mvn_B',str_all.time,transpose(str_all.vec),dlimit={spice_frame:data.frame}
  end

'L2_SAV': begin
  pathname = 'maven/data/sci/mag/l1_cdf/YYYY/MM/mvn_mag_ql_YYYYdDOYpl_YYYYMMDD_v??_r??.cdf'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files)
  cdf2tplot,files
  end

endcase
  
end




