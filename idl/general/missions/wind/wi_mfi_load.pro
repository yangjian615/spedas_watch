;+
;Procedure: WI_MFI_LOAD
;
;Purpose:  Loads WIND fluxgate magnetometer data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   wi_mfi_load
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2017-02-17 14:26:40 -0800 (Fri, 17 Feb 2017) $
; $LastChangedRevision: 22822 $
; $URL $
;-
pro wi_mfi_load,type,files=files,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      addmaster=addmaster,tplotnames=tn,source_options=source

if not keyword_set(datatype) then datatype = 'h0'
if keyword_set(type) then datatype = type

wind_init
if not keyword_set(source) then source = !wind

;URL deprecated by reorg at SPDF
;if datatype eq 'k0'  then    pathformat = 'wind/mfi/YYYY/wi_k0_mfi_YYYYMMDD_v0?.cdf'
;New URL 2012/10 pcruce@igpp
if datatype eq 'k0'  then    pathformat = 'wind/mfi/mfi_k0/YYYY/wi_k0_mfi_YYYYMMDD_v??.cdf'
;URL deprecated by reorg at SPDF
;if datatype eq 'h0'  then    pathformat = 'wind/mfi_h0/YYYY/wi_h0_mfi_YYYYMMDD_v0?.cdf'
;New URL 2012/10 pcruce@igpp
if datatype eq 'h0'  then    pathformat = 'wind/mfi/mfi_h0/YYYY/wi_h0_mfi_YYYYMMDD_v??.cdf'
;URL deprecated by reorg at SPDF
;if datatype eq 'h2'  then    pathformat = 'wind/mfi_h2/YYYY/wi_h2_mfi_YYYYMMDD_v0?.cdf'
;New URL 2012/10 pcruce@igpp
if datatype eq 'h2'  then    pathformat = 'wind/mfi/mfi_h2/YYYY/wi_h2_mfi_YYYYMMDD_v??.cdf'

if not keyword_set(varformat) then begin
   if datatype eq  'k0' then    varformat = 'BGSEc PGSE'
   if datatype eq  'h0' then    varformat = 'B3GSE'
   if datatype eq  'h2' then    varformat = 'BF1 BGSE'
endif

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)

files = spd_download(remote_file=relpathnames, remote_path=!wind.remote_data_dir, local_path = !wind.local_data_dir)

if keyword_set(downloadonly) then return

prefix = 'wi_'+datatype+'_mfi_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

dprint,dlevel=3,'tplotnames: ',tn

options,/def,tn+'',/lazy_ytitle          ; options for all quantities
options,/def,strfilter(tn,'*GSE* *GSM*',delim=' ') , colors='bgr' , labels=['x','y','z']    ; set colors for the vector quantities
options,/def,strfilter(tn,'*B*GSE* *B*GSM*',delim=' '),constant=0., labels=['Bx','By','Bz'] , ysubtitle = '[nT]'

end
