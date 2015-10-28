

pro mvn_sep_load,pathnames=pathnames,trange=trange,files=files,RT=RT,download_only=download_only, $
        mag=mag,pfdpu=pfdpu,sep=sep,lpw=lpw,sta=sta,format=format,use_cache=use_cache,  $
        source=source,verbose=verbose,L1=L1,L0=L0,L2=L2,ancillary=ancillary, anc_structure = anc_structure,$
                 pad = pad
        
      @mvn_sep_handler_commonblock.pro
;common mvn_sep_load_com, last_files
        
; loading the ancillary data.
if keyword_set(ancillary) then begin
  cdf_format = 'maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v0?_r??.cdf'
  cdf_files = mvn_pfp_file_retrieve(cdf_format,/daily_names,trange=trange,/valid_only,/last_version)
  if CDF_files[0] eq '' then print, 'Ancillary files do not exist for this time range' else begin
  ;sav_format ='maven/data/sci/sep/anc/sav/YYYY/MM/mvn_sep_anc_YYYYMMDD_v0?_r??.sav'
  ;sav_files = mvn_pfp_file_retrieve(sav_format,/daily_names,trange=trange,/valid_only,/last_version)
    if ~keyword_set(download_only) then cdf2tplot,cdf_files
    
    if arg_present (anc_structure) then mvn_sep_anc_read_cdf, cdf_files, sep_ancillary = anc_structure
 endelse  
 return
endif
  
if keyword_set(pad) then begin
   pad_format = 'maven/data/sci/sep/l2_pad/sav/YYYY/MM/mvn_sep_l2_pad_YYYYMMDD_v0?_r??.sav'
   pad_files = mvn_pfp_file_retrieve(pad_format,/daily_names,trange=trange,/valid_only,/last_version)
   if pad_files[0] eq '' then print, 'PAD files do not exist for this time range' else begin
      restore, pad_files[0]
      npadfiles = n_elements(pad_files)
      pads = pad;rename the pad structure
      if npadfiles gt 1 then begin
         for J = 1, npadfiles-1 do begin
            print,'Restoring '+pad_files[J]
            restore, pad_files[J]
            pads = [pads, pad]
         endfor
      endif
     
      mvn_sep_pad_load_tplot,pads
   endelse
   return
endif
      
if keyword_set(L0) then   format = 'L0_RAW'                   
if keyword_set(L1) then   format = 'L1_SAV'
if keyword_set(L2) then   format = 'L2_CDF'

if ~keyword_set(format) then format='L1_SAV'

if format eq 'L1_SAV' then begin
  mvn_sep_var_restore,trange=trange,download_only=download_only
  if ~keyword_set(download_only) then begin
    mvn_sep_cal_to_tplot,sepn=1
    mvn_sep_cal_to_tplot,sepn=2
  endif
  return
endif


if format eq 'L2_CDF' then begin
  for sepnum = 1,2 do begin
    sepstr = 's'+strtrim(sepnum,2)
    data_type = sepstr+'-cal-svy-full'
    L2_fileformat =  'maven/data/sci/sep/l2/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_v03_r??.cdf'
    filenames = mvn_pfp_file_retrieve(l2_fileformat,/daily_name,trange=trange,verbose=verbose,/last_version,/valid_only)
    if ~keyword_set(download_only) then   cdf2tplot,filenames    ,prefix = 'MVN_SEP'+strtrim(sepnum,2)+''
  endfor
  return
endif


;  Use L0 format if it reaches this point.

files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)

if keyword_set(use_cache) and keyword_set(source_filenames) then begin
  if array_equal(files,source_filenames) then begin
    dprint,dlevel=2,'Using cached common block'
    return
  endif
endif



tstart=systime(1)
if n_elements(pfdpu) eq 0 then pfdpu=1
if n_elements(sep) eq 0 then sep=1
if n_elements(mag) eq 0 then mag=1



;last_files=''

if ~keyword_set(download_only) then begin
  mvn_pfp_l0_file_read,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,sta=sta ,pathname=pathname,file=files,trange=trange 
  mvn_sep_handler,record_filenames = files
;  last_files = files
endif

  
end

