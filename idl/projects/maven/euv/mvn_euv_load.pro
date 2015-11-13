;+
; NAME: 
;       mvn_euv_load
; SYNTAX: 
;       mvn_euv_load, trange=trange
; PURPOSE:
;       Load procedure for EUV L2 data
; INPUTS
;       trange
; OUTPUT: 
; KEYWORDS: 
; HISTORY:      
; VERSION: 
;  $LastChangedBy: jhalekas $
;  $LastChangedDate: 2015-11-12 12:48:13 -0800 (Thu, 12 Nov 2015) $
;  $LastChangedRevision: 19351 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/euv/mvn_euv_load.pro $
;
;CREATED BY:  Christina O. Lee  02-24-15
;FILE: mvn_euv_load.pro
;-


pro mvn_euv_load, trange=trange, all=all  
  L2_fileformat = 'maven/data/sci/euv/l2/YYYY/MM/mvn_euv_l2_bands_YYYYMMDD_v0?_r??.cdf'
  files = mvn_pfp_file_retrieve(L2_fileformat, trange=trange, /daily_names, /valid_only)
  
  if keyword_set(all) then vf='data freq dfreq ddata flag' else vf='data'
  cdf2tplot, files, varformat=vf, prefix='mvn_euv_'
end
