pro mvn_sep_var_restore,pathname,trange=trange,verbose=verbose,download_only=download_only,prereq_info=prereq_temp,filename=files

  @mvn_sep_handler_commonblock.pro
;    common mav_apid_sep_handler_com , sep_all_ptrs ,  sep1_hkp,sep2_hkp,sep1_svy,sep2_svy,sep1_arc,sep2_arc,sep1_noise,sep2_noise $
;    ,sep1_memdump,sep2_memdump  ,mag1_hkp_f0,mag2_hkp_f0
    
  @mvn_pfdpu_handler_commonblock.pro
  ;    common mvn_apid_misc_handler_com,manage,realtime,apid20x,apid21x,apid22x,apid23x,apid24x,apid25x


trange = timerange(trange)
;res = 86400.d
;days =  round( time_double(trange )/res)
;ndays = days[1]-days[0]
;tr = days * res

ndays=1
if ~keyword_set(files) then begin
  if not keyword_set(pathname) then pathname =  'maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_$NDAY.sav'
  pn = str_sub(pathname, '$NDAY', strtrim(ndays,2) +'day')
  files = mvn_pfp_file_retrieve(pn,/daily,trange=trange,source=source,verbose=verbose,/valid_only,no_update=0,last_version=0)
  
endif

if keyword_set(download_only) then return
undefine,prereq_temp

mvn_sep_handler,/clear
mvn_pfdpu_handler,/clear
for i=0,n_elements(files)-1 do begin
  undefine, s1_hkp,s1_svy,s1_arc,s1_nse
  undefine, s2_hkp,s2_svy,s2_arc,s2_nse
  undefine, prereq_info
  restore,verbose=verbose,filename=files[i]
  mav_gse_structure_append  ,sep1_hkp  , s1_hkp
  mav_gse_structure_append  ,sep1_svy  , s1_svy
  mav_gse_structure_append  ,sep1_arc  , s1_arc
  mav_gse_structure_append  ,sep1_noise, s1_nse
  mav_gse_structure_append  ,sep2_hkp  , s2_hkp
  mav_gse_structure_append  ,sep2_svy  , s2_svy
  mav_gse_structure_append  ,sep2_arc  , s2_arc
  mav_gse_structure_append  ,sep2_noise, s2_nse
  mav_gse_structure_append  ,mag1_hkp_f0  , m1_hkp
  mav_gse_structure_append  ,mag2_hkp_f0  , m2_hkp
  
  mav_gse_structure_append  ,apid20x  , ap20
  mav_gse_structure_append  ,apid21x  , ap21
  mav_gse_structure_append  ,apid22x  , ap22
  mav_gse_structure_append  ,apid23x  , ap23
  mav_gse_structure_append  ,apid24x  , ap24
  mav_gse_structure_append  ,apid25x  , ap25
  append_array, prereq_temp,prereq_info
endfor
mvn_pfdpu_handler,/finish
mvn_sep_handler,/finish
end




