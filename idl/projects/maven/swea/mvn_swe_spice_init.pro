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
; $LastChangedDate: 2014-11-26 19:08:15 -0800 (Wed, 26 Nov 2014) $
; $LastChangedRevision: 16325 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_spice_init.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_spice_init, trange=trange, list=list

  @mvn_swe_com

  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed, kernel_verified, $
         time_verified, sclk, tls

  if (size(trange,/type) eq 0) then begin
    if (size(mvn_swe_engy,/type) ne 8) then begin
      print,"You must specify a time range or load data first."
      return
    endif
    
    trange = minmax(mvn_swe_engy.time)
  endif
  
  dprint, "Initializing SPICE ...", getdebug=old_dbug, setdebug=0

  swe_kernels = mvn_spice_kernels(/all,/load,trange=trange,verbose=-1)
  swe_kernels = spice_test('*')  ; only loaded kernels, no wildcards
  n_ker = n_elements(swe_kernels)
  
  if keyword_set(list) then begin
    print, "Kernels in use: "
    for i=0,(n_ker-1) do print,"  ",file_basename(swe_kernels[i])
  endif

; Use common block settings to inform later routines that kernels have
; already been loaded, and they don't need to check again and print out
; a bunch of unnecessary diagnostics that can't be turned off.

  i = where(strpos(swe_kernels,'SCLK') ne -1, scnt)  ; spacecraft clock kernel
  j = where(strpos(swe_kernels,'tls') ne -1, tcnt)   ; leap seconds kernel
  
  if (scnt and tcnt) then begin
    kernel_verified = 1
    sclk = swe_kernels[i]
    tls = swe_kernels[j]
    time_verified = systime(1)
    msg = "Success"
  endif else begin
    kernel_verified = 0
    msg = "WARNING: no SPICE kernels!"
  endelse

  dprint, msg, setdebug=old_debug

  return

end
