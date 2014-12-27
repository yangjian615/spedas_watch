;+
;PROCEDURE: 
;	MVN_SWIA_STACOMP
;PURPOSE: 
;	Routine to compare density and velocity from SWIA to STATIC
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_STACOMP, TYPE = TYPE, TRANGE = TRANGE
;INPUTS:
;KEYWORDS:
;	TYPE: STATIC data type to use for moments
;	TRANGE: time range to use
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-12-23 07:54:41 -0800 (Tue, 23 Dec 2014) $
; $LastChangedRevision: 16541 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_stacomp.pro $
;
;-

pro mvn_swia_stacomp, type = type, trange = trange

if not keyword_set(trange) then ctime,trange,npoints = 2
if not keyword_set(type) then type = 'd0'

get_4dt,'n_4d','mvn_sta_get_'+type,mass = [0.3,1.8],name = 'np', t1= trange(0),t2 = trange(1)
get_4dt,'n_4d','mvn_sta_get_'+type,mass = [1.8,2.5],name = 'na', t1= trange(0),t2 = trange(1)
get_4dt,'n_4d','mvn_sta_get_'+type,mass = [10,20],name = 'no', t1= trange(0),t2 = trange(1)
get_4dt,'n_4d','mvn_sta_get_'+type,mass = [20,40],name = 'no2', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [0.3,1.8],name = 'vp', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [1.5,2.5],name = 'va', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [10,20],name = 'vo', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [20,40],name = 'vo2', t1= trange(0),t2 = trange(1)

get_data,'np',data = np
get_data,'na',data = na
get_data,'no',data = no
get_data,'no2',data = no2
get_data,'vp',data = vp
get_data,'va',data = va
get_data,'vo',data = vo
get_data,'vo2',data = vo2


ntot = np.y + na.y/sqrt(2) + no.y/sqrt(16) + no2.y/sqrt(32)
ftot = (np.y#replicate(1,3)) * vp.y + (na.y#replicate(1,3)) * va.y + (no.y#replicate(1,3)) * vo.y + (no2.y#replicate(1,3))*vo2.y

vtot = ftot/(ntot#replicate(1,3))

store_data,'nswista',data = {x:np.x,y:ntot}
store_data,'vswista',data = {x:np.x,y:vtot,v:[0,1,2]}



end