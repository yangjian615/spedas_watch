;+
;PROCEDURE:	
;	MVN_SWIA_MINVAR_BV
;PURPOSE:	
;	Do minimum variance on magnetic field and rotate velocity to same frame 
;
;INPUT:		
;
;KEYWORDS:
;	BDATA: tplot variable for the magnetic field (needs to be same frame as velocity)
;	VDATA: tplot variable for the velocity (needs to be same frame as mag field)
;	TRANGE: time range to do minimum variance (will prompt to choose if not set)
;
;AUTHOR:	J. Halekas	
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-10-09 11:47:24 -0700 (Thu, 09 Oct 2014) $
; $LastChangedRevision: 15956 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_minvar_bv.pro $
;
;-

pro mvn_swia_minvar_bv, bdata = bdata, vdata = vdata, trange = trange

if not keyword_set(bdata) then bdata = 'mvn_mag1_svy_BAVG_MAVEN_MSO'
if not keyword_set(vdata) then vdata = 'mvn_swim_velocity_mso'

if not keyword_set(trange) then ctime,trange,npoints = 2

get_data,bdata,data = data

w= where(data.x ge trange(0) and data.x le trange(1))

minvar,transpose(data.y(w,*)),eig,vrot = vrot

store_data,'bminv',data = {x:data.x(w),y:transpose(vrot)}
options,'bminv','labels',['i','j','k']

get_data,vdata,data  = vel

vin = transpose(vel.y)
vout = vin

vout(0,*) = eig(0,0)*vin(0,*) + eig(1,0)*vin(1,*) + eig(2,0)*vin(2,*)
vout(1,*) = eig(0,1)*vin(0,*) + eig(1,1)*vin(1,*) + eig(2,1)*vin(2,*)
vout(2,*) = eig(0,2)*vin(0,*) + eig(1,2)*vin(1,*) + eig(2,2)*vin(2,*)

store_data,'vminv',data = {x:vel.x,y:transpose(vout)}
options,'vminv','labels',['i','j','k']

end
