pro mvn_sep_load,pathnames=pathnames,trange=trange,files=files,RT=RT,download_only=download_only, $
        mag=mag,pfdpu=pfdpu,sep=sep,lpw=lpw,sta=sta,attitude=attitude,format=format,  $
        source=source,verbose=verbose,L1=L1
        
          
if keyword_set(L1) then format='L1_SAV'

if ~keyword_set(format) then format=''

if format eq 'L1_SAV' then begin
  mvn_sep_var_restore,trange=trange

return
endif

tstart=systime(1)
if n_elements(pfdpu) eq 0 then pfdpu=1
if n_elements(sep) eq 0 then sep=1
if n_elements(mag) eq 0 then mag=1

;pathname = 'maven/data/sci/pfp/l0/mvn_pfp_all_l0_YYYYMMDD_v???.dat'   ; old source
;pathname = 'maven/pfp/l0/YYYY/MM/mvn_pfp_all_l0_YYYYMMDD_v???.dat'
files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)

if keyword_set(attitude) then begin
  mkernels = mvn_spice_kernels(/all,load=~keyword_set(download_only),trange=timerange())
endif


if ~keyword_set(download_only) then begin
  mvn_pfp_l0_file_read,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,sta=sta ,pathname=pathname,file=files,trange=trange 
  if keyword_set(attitude) then begin
    dprint,dlevel=2,'Computing rotations'
    def_frame = 'MAVEN_SSO'
    spice_qrot_to_tplot,'MAVEN_SPACECRAFT',def_frame,get_omega=3,res=360d,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .1 *!pi/180  ;  degree error
  endif
endif
  
end




