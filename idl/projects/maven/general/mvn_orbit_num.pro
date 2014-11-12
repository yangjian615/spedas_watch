;+
;NAME: MVN_ORBIT_NUM
; function: mvn_orbit_num()
;PURPOSE:
; returns database structure that contains orbit information about each MAVEN orbit.
; Alternatively - Returns the time if given the orbit number or returns the orbit number if given the time.
;  
;Typical CALLING SEQUENCE:
;  orbdata = mvn_orbit_num()
;  store_data,'orbnum',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
;  tplot,var_label='orbnum'

;  
;TYPICAL USAGE:
;  print, mvn_orbit_num(time=systime(1) )          ;  prints current MAVEN orbit number
;  print ,  time_string( mvn_orbit_num(orbnum = 6.0)  ; prints the time of periapsis of orbit number 6
;  timebar, mvn_orbit_num( orbnum = indgen(300) )   ; plots a vertical line at periapsis for the first 300 orbits
;Author: Davin Larson  - October, 2014
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function mvn_orbit_num,orbnum=orbnum,time=time,verbose=verbose

common mvn_orbit_num_com,alldat,time_cached
if ~keyword_set(time_cached) then time_cached=1d
if (systime(1) - time_cached) gt 3600 then begin   ; generate no more than once per hour
  alldat = 0
  if ~keyword_set(source) then source = spice_file_source(preserve_mtime=1,verbose=verbose,ignore_filesize=1)
  if ~keyword_set(filename) then filename = file_retrieve('MAVEN/kernels/spk/maven_orb.orb',_extra=source)
  openr,lun,filename,/get_lun
  i=0L
  MOI_time = time_double('2014-9-22/02:06')        ; this is only approximate!
  nan = !values.f_nan
  dnan = !values.d_nan
  dat = {num:1L, peri_time:MOI_TIME,  peri_MET:dnan,  APO_time:moi_time+17.5*3600,  sol_lon:nan, sol_lat:nan,  sc_lon:nan, sc_lat:nan,  sc_alt:nan, sol_dist:dnan}
  append_array,alldat,dat,index=ind
  while ~eof(lun) do begin
     s=''
     readf,lun,s
     dprint,dlevel=3,s
 ;    if i lt 2 then dprint,s,dlevel=2
     if i++ lt 2 then continue
;     ss =  strsplit(s,/extract)
;     dat.num = long(ss[0])
;     dat.peri_time = time_double(strjoin(ss[1:4],' ') ,tformat='YYYY MTH DD hh:mm:ss')
;     dat.peri_met  = double( strmid(ss[5],2) )
;     dat.apo_time =  time_double(strjoin(ss[6:9],' ') ,tformat='YYYY MTH DD hh:mm:ss')
;     dat.sol_lon  =  double( ss[10] )
;     dat.sol_lat  =  double( ss[11] )
;     dat.sc_lon   =  double( ss[12] )
;     dat.sc_lat   =  double( ss[13] )
;     dat.sc_alt   =  double( ss[14] )
;     dat.sol_dist =  double( ss[15] )
     dat.num = long(strmid(s,0,5))
     dat.peri_time = time_double( strmid(s,7,20) ,tformat='YYYY MTH DD hh:mm:ss')
     dat.peri_met  = double( strmid(s,33,16)  ) 
     dat.apo_time =  time_double( strmid(s,51,20) ,tformat='YYYY MTH DD hh:mm:ss')
     dat.sol_lon  =  double(  strmid(s,72,8) )
     dat.sol_lat  =  double(  strmid(s,81,8) )
     dat.sc_lon   =  double(  strmid(s,90,8) )
     dat.sc_lat   =  double(  strmid(s,99,8) )
     dat.sc_alt   =  double(  strmid(s,108,11) )
     dat.sol_dist =  double(  strmid(s,120,12) )
     append_array,alldat,dat,index=ind
  endwhile
  append_array,alldat,index=ind,/done
  free_lun,lun
  time_cached = systime(1)
endif

if n_elements(time) ne 0   then return, interp(double(alldat.num),alldat.peri_time,time_double(time))
if n_elements(orbnum) ne 0 then return, interp(alldat.peri_time,double(alldat.num),double(orbnum))
return , alldat
end







