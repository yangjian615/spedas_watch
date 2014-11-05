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
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_spice_init.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_spice_init, trange=trange, list=list, silent=silent

  @mvn_swe_com

  if (size(trange,/type) eq 0) then begin
    if (size(mvn_swe_engy,/type) ne 8) then begin
      print,"You must specify a time range or load data first."
      return
    endif
    
    trange = minmax(mvn_swe_engy.time)
  endif
  
  if keyword_set(silent) then verbose = -1 else verbose = 1

  swe_kernels = mvn_spice_kernels(/all,/load,trange=trange,verbose=verbose)
  n_ker = n_elements(swe_kernels)
  
  if keyword_set(list) then for i=0,(n_ker-1) do print, file_basename(swe_kernels[i])

  return

end
