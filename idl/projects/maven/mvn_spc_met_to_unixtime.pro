;
;+
;Function:  mvn_spc_met_to_unixtime
;Purpose:  Convert MET (mission Elapsed Time) to Unix Time  (which is almost equivalent to UTC)
;see also:  "mvn_spc_unixtime_to_met" for the reverse conversion
; This routine is in the process of being modified to use SPICE Kernels to correct for clock drift as needed.
; Author: Davin Larson
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-09-23 10:02:10 -0700 (Tue, 23 Sep 2014) $
; $LastChangedRevision: 15840 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mvn_spc_met_to_unixtime.pro $
;-
function mvn_spc_met_to_unixtime,input,reverse=reverse,correct_clockdrift=correct_clockdrift  ; ,reset=reset   ;,prelaunch = prelaunch

common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed  , kernel_verified, time_verified, sclk

if n_elements(correct_clockdrift) eq 1 then begin
;  if n_params() ne 0 then message,'Not allowed'
  cor_clkdrift = correct_clockdrift
endif

if keyword_set(cor_clkdrift) then begin
   if  n_elements(kernel_verified) eq 0 || keyword_set(reset) then begin ; check for cspice first
      if spice_test() then begin
         tls = spice_standard_kernels(/load) ;jmm, 22-sep-2014
         sclk = mvn_spice_kernels(['STD','SCK'],/load)
         if keyword_set(sclk)  then begin
            kernel_verified = 1
         endif else begin
            kernel_verified = 0
            dprint,dlevel=2,'ICY is not installed.'
            dprint,dlevel=2,'Times are subject to spacecraft clock drift.'
            prelaunch = 1
         endelse
      endif else begin
         kernel_verified = 0
         prelaunch = 1
      endelse 
      reset=0
      time_verified = systime(1)
   endif 
endif else cor_clkdrift = 0b ;need to set this to avoid crash at line 66, jmm, 22-sep-2014
      

if n_elements(input) eq 0 then message,'Must provide input'
      
if keyword_set(reverse) then begin
  if n_params() ge 1 then unixtime = input
  if ~keyword_set(cor_clkdrift)  then begin
    epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ; Normal use
    ut = time_double(unixtime)
;    if unixtime[0] le 1354320000  then unixtime = met + epoch + 3600L*12   ; correction prior to '2012-12-1' 
    delta = (ut le 1354320000) * 3600L*12
    met = ut - epoch + delta
    return,met
  endif else begin
;   dprint,'Using cspice',dlevel=3
    et = time_ephemeris(unixtime)
    cspice_sce2c, -202, et, sclkdp1
    met = sclkdp1 / 2d^16
  endelse
  return,met
endif

met = input
if ~cor_clkdrift then begin
;    epoch =  978307200d    ; long(time_double('2001-1-1'))  ; valid for files prior to about June, 2012
    epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ; Normal use
    unixtime =  met +  epoch    
;    if unixtime[0] le 1356998400  then unixtime = met + epoch + 3600L*12   ; correction prior to '2013-1-1' 
;    if unixtime[0] le 1354320000  then unixtime = met + epoch + 3600L*12   ; correction prior to '2012-12-1' 
    delta = (unixtime le 1354320000) * 3600L*12
    unixtime += delta
;    if unixtime[0] le 1351728000  then unixtime = met + epoch + 3600L*12   ; correction prior to '2012-11-1' 
endif else begin
   eti = double(met)
   n = n_elements(met)
   for i=0L,n-1 do begin
     cspice_sct2e, -202, double(MET[i]*2D^16), ET
     eti[i] = et
   endfor 
   unixtime = time_ephemeris(ETI,/et2ut)
endelse

return,unixtime
end
