;+
;NAME: MVN_SPICE_LOAD
; Procedure: mvn_spice_load
;PURPOSE:
; LOADS SPICE kernels and creates a few tplot variables
; Demonstrates usage of MAVEN SPICE ROUTINES
;  
;CALLING SEQUENCE:
;   mvn_spice_load,kernels=kernels,trange=trange
;  
;  Author:  Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-01-21 17:01:02 -0800 (Tue, 21 Jan 2014) $
; $LastChangedRevision: 13960 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/idl_socware/trunk/projects/maven/general/mvn_file_source.pro $
;-

pro mvn_spice_load,trange=trange,kernels=kernels,download_only=download_only,verbose=verbose

   ; Create
   orbdata = mvn_orbit_num(verbose=verbose)                 
   store_data,'orbnum',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
;   tplot,var_label='orbnum'
   tplot_options,'timebar','orbnum'
   tplot_options,'var_label','orbnum'

   kernels = mvn_spice_kernels(/all,/clear,/load,trange=trange,verbose=2)
   if keyword_set(download_only) then return
   spice_position_to_tplot,'MAVEN','Mars',frame='MSO',res=300d,scale=1000.,name=n1  ,trange=trange
   xyz_to_polar,n1
   
   frame = 'MAVEN_SPACECRAFT'
;   frame = 'MAVEN_SCALT'
   spice_qrot_to_tplot,frame,'MSO',get_omega=3,res=30d,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .5 *!pi/180  ; .5 degree error
   spice_qrot_to_tplot,frame,'MAVEN_APP',get_omega=3,res=30d,names=tn,check_obj=['MAVEN_SPACECRAFT','MAVEN_APP_OG'] ,error=  .5 *!pi/180  ; .5 degree error
   
end


