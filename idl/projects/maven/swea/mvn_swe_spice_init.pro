;+
;PROCEDURE:   mvn_swe_spice_init
;PURPOSE:
;  Initializes SPICE.
;
;USAGE:
;  mvn_swe_spice_init
;
;INPUTS:
;
;KEYWORDS:
;
;    TRANGE:        Time range for MAVEN spacecraft spk and ck kernels.
;
;    LIST:          If set, list the kernels in use.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:49:36 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15677 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_spice_init.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_spice_init, trange=trange, list=list

  @mvn_swe_com

  if (data_type(trange) eq 0) then begin
    if (data_type(mvn_swe_engy) ne 8) then begin
      print,"You must specify a time range or load data first."
      return
    endif
    
    tmin = min(mvn_swe_engy.time, max=tmax)
    trange = [tmin, tmax]
  endif  

  swe_kernels = mvn_spice_kernels(/all,/load,trange=trange,verbose=1)
  
  if keyword_set(list) then begin
    for i=0,(n_elements(swe_kernels)-1) do print, file_basename(swe_kernels[i])
  endif

  return

end
