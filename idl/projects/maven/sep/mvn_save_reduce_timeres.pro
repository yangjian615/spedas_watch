
pro mvn_save_reduce_timeres,trange=trange0,init=init,timestamp=timestamp,fileformat=fileformat,mag_cluge=mag_cluge,resstr=resstr,resolution=res

if keyword_set(init) then begin
  trange0 = [time_double('2014-9-22'), systime(1) ]
  if init lt 0 then trange0 = [time_double('2013-12-5'), systime(1) ]
endif else trange0 = timerange(trange0)

;filename example:  http://sprg.ssl.berkeley.edu/data/maven/data/sci/mag/l1/2014/10/mvn_mag_ql_2014d290pl_20141017_v00_r01.sts


if keyword_set(mag_cluge) then begin
  fileformat =  'maven/data/sci/mag/l1a/YYYY/MM/sav/$RES/mvn_mag_l1_pl_YYYYMMDD_$RES.sav'  
endif

if ~keyword_set(resstr) then resstr = '30sec'
if ~keyword_set(res) then begin
   res = double(resstr)
   if strpos(resstr,'min') ge 0 then res *= 60
   if strpos(resstr,'hr') ge 0 then res *= 3600
   dprint,'Time resolution not provided, Using: ',res,' seconds'
endif


fullres_fmt = str_sub(fileformat, '$RES', 'full')
redures_fmt = str_sub(fileformat, '$RES', resstr)

day = 86400L
trange = day* double(round( (timerange((trange0+ [ 0,day-1]) /day)) ))         ; round to days
nd = round( (trange[1]-trange[0]) /day) 

for i=0L,nd-1 do begin
  tr = trange[0] + [i,i+1] * day
  tn = tr[0]
  prereq_files=''

  fullres_files  = mvn_pfp_file_retrieve(fullres_fmt,trange=tn +[0,1.0001d]*day ,/daily_names)   ; use a little bit of following day file
  redures_file   = mvn_pfp_file_retrieve(redures_fmt,trange=tn,/daily_names,/create_dir)
  
  dprint,dlevel=3,fullres_files[0]
  
  if file_test(fullres_files[0],/regular) eq 0 then begin
    dprint,dlevel=2,fullres_files[0]+' Not found. Skipping
    continue
  endif

  append_array,prereq_files,fullres_files

  prereq_info = file_info(prereq_files)
  prereq_timestamp = max([prereq_info.mtime, prereq_info.ctime])
  
  target_info = file_info(redures_file)
  target_timestamp =  target_info.mtime 

  if prereq_timestamp lt target_timestamp then continue    ; skip if L1 does not need to be regenerated
  dprint,dlevel=1,'Generating new file: '+redures_file
  
  alldata=0
;  all_dependents=''
  all_dependents = file_hash(prereq_files,/add_mtime)
  
  for j=0,n_elements(fullres_files)-1 do begin
     f = fullres_files[j]
     if file_test(/regular,f) eq 0 then continue
     restore,f    ;,/verbose   ; it is presumed that the variables: 'data' and 'dependents' are defined here.
     if keyword_set(mag_cluge) then dependents = [header.sts_info,header.spice_list]
     append_array,alldata,data
     append_array,all_dependents,dependents
  endfor
  
  data = average_hist(alldata,alldata.time,binsize=res,range=tr)
  dependents = all_dependents
  
  save,file=redures_file ,data,dependents

endfor
  
end


