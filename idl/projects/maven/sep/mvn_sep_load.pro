

pro mvn_sep_load,pathnames=pathnames,trange=trange,files=files,RT=RT,download_only=download_only, $
        mag=mag,pfdpu=pfdpu,sep=sep,lpw=lpw,sta=sta,format=format,  $
        source=source,verbose=verbose,L1=L1,L0=L0,ancillary=ancillary
        
        
if keyword_set(ancillary) then begin
  pformat = 'maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_anc_YYYYMMDD_v0?_r??.cdf'
  anc_files = mvn_pfp_file_retrieve(pformat,/daily_names,trange=trange,/valid_only,/last_version)
  if ~keyword_set(download_only) then cdf2tplot,anc_files
  return  
endif
          
if keyword_set(L0) then   format = 'L0_RAW'                   
if keyword_set(L1) then    format='L1_SAV'

if ~keyword_set(format) then format='L1_SAV'

if format eq 'L1_SAV' then begin
  mvn_sep_var_restore,trange=trange,download_only=download_only
  return
endif



tstart=systime(1)
if n_elements(pfdpu) eq 0 then pfdpu=1
if n_elements(sep) eq 0 then sep=1
if n_elements(mag) eq 0 then mag=1

files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)

if ~keyword_set(download_only) then begin
  mvn_pfp_l0_file_read,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,sta=sta ,pathname=pathname,file=files,trange=trange 
endif
  
end

