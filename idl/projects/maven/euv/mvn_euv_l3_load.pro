;+
; NAME: 
;       mvn_euv_l3_load
; SYNTAX: 
;       mvn_euv_l3_load,/daily
;       or
;       mvn_euv_l3_load,/minute
; PURPOSE:
;       Load procedure for the EUV L3 (FISM) daily or minute data
; KEYWORDS: daily, minute 
; HISTORY:      
; VERSION: 
;  $LastChangedBy: davin-mac $
;  $LastChangedDate: 2016-04-22 18:26:36 -0700 (Fri, 22 Apr 2016) $
;-

pro mvn_euv_l3_load,trange=trange,daily=daily,minute=minute,tplot=tplot
  
  if keyword_set(daily) then begin
    L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_daily_YYYYMMDD_v??_r??.cdf'
  endif else L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_minute_YYYYMMDD_v??_r??.cdf'

  files = mvn_pfp_file_retrieve(L3_fileformat,trange=trange,/daily_names,/valid_only)
  
  if files[0] eq '' then begin
    dprint,dlevel=2,'No EUVM L3 (FISM) files were found for the selected time range.'
    store_data,'mvn_euv_l3',/delete
    return
  endif
  
  cdf2tplot,files,prefix='mvn_euv_l3_'
  
  get_data,'mvn_euv_l3_y',data=fismdata; FISM Irradiances
  store_data,'mvn_euv_l3_y',/delete

  store_data,'mvn_euv_l3',data={x:fismdata.x,y:fismdata.y,v:reform(fismdata.v[0,*])}, $
    dlimits={ylog:0,zlog:1,spec:1,ytitle:'Wavelength (nm)',ztitle:'FISM Irradiance (W/m2/nm)'}
  
  if keyword_set(tplot) then tplot,'mvn_euv_l3'

end
