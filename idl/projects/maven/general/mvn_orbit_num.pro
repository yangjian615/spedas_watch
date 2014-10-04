;+
;NAME: MVN_ORBIT_NUM
; function: mvn_orbit_num()
;PURPOSE:
; returns database structure that contains orbit information about each MAVEN orbit.
; Alternatively - Returns the time if given the orbit number or returns the orbit number if given the time.
;  
;Typical CALLING SEQUENCE:
;  data=mvn_orbit_num() 
;TYPICAL USAGE:
;  print, mvn_orbit_num(time=systime(1) )          ;  prints current MAVEN orbit number
;  print ,  time_string( mvn_orbit_num(orbnum = 6.0)  ; prints the time of periapsis of orbit number 6
;Author: Davin Larson  - October, 2014
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function mvn_orbit_num,orbnum=orbnum,time=time,verbose=verbose

common mvn_orbit_num_com,alldat,time_cached
if ~keyword_set(time_cached) then time_cached=1d
if (systime(1) - time_cached) gt 300 then begin
  alldat = 0
  if ~keyword_set(source) then source = spice_file_source(preserve_mtime=1,verbose=verbose)
  if ~keyword_set(filename) then filename = file_retrieve('MAVEN/kernels/spk/maven_orb.orb',_extra=source)
  openr,lun,filename,/get_lun
  i=0L
  MOI_time = time_double('2014-9-22/01:35')        ; this is only approximate!
  dat = {num:1L, peri_time:MOI_TIME,  peri_MET:0d,  APO_time:moi_time+17.5*3600,  sol_lon:0., sol_lat:0.,  sc_lon:0., sc_lat:0.,  sc_alt:0., sol_dist:0.d}
  append_array,alldat,dat,index=ind
  while ~eof(lun) do begin
     s=''
     readf,lun,s
     dprint,dlevel=3,s
 ;    if i lt 2 then dprint,s,dlevel=2
     if i++ lt 2 then continue
     ss =  strsplit(s,/extract)
     dat.num = long(ss[0])
     dat.peri_time = time_double(strjoin(ss[1:4],' ') ,tformat='YYYY MTH DD hh:mm:ss')
     dat.peri_met  = double( strmid(ss[5],2) )
     dat.apo_time =  time_double(strjoin(ss[6:9],' ') ,tformat='YYYY MTH DD hh:mm:ss')
     dat.sol_lon  =  double( ss[10] )
     dat.sol_lat  =  double( ss[11] )
     dat.sc_lon   =  double( ss[12] )
     dat.sc_lat   =  double( ss[13] )
     dat.sc_alt   =  double( ss[14] )
     dat.sol_dist =  double( ss[15] )
     append_array,alldat,dat,index=ind
  endwhile
  append_array,alldat,index=ind,/done
  free_lun,lun
  time_cached = systime(1)
endif

if keyword_set(time)   then return, interp(double(alldat.num),alldat.peri_time,time_double(time))
if keyword_set(orbnum) then return, interp(alldat.peri_time,double(alldat.num),double(orbnum))
return , alldat
end







