;+
;PROCEDURE: 
;	MVN_SWIA_CALC_BCRUSTAL
;PURPOSE: 
;	Routine to calculate crustal magnetic field (uses Dave Brain's routine)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_CALC_BCRUSTAL
;INPUTS:
;KEYWORDS:
;	TR: Time range (prompts to choose interactively if not set)
;	PDATA: Tplot variable for position (defaults to MSO), return will have same
;		number of components (make sure this has 'SPICE_FRAME' set or you will fail)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-11-17 09:08:14 -0800 (Mon, 17 Nov 2014) $
; $LastChangedRevision: 16194 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_calc_bcrustal.pro $
;
;-

@mars_crust_model

pro mvn_swia_calc_bcrustal, tr = tr, pdata = pdata


if not keyword_set(pdata) then pdata = 'MAVEN_POS_(MARS-MSO)'

spice_vector_rotate_tplot,pdata,'IAU_MARS', suffix = '_GEO'

if not keyword_set(tr) then ctime,tr,npoints = 2

get_data,pdata+'_GEO',data = pos

w = where(pos.x ge tr[0] and pos.x le tr[1],nel)

time = pos.x[w]
upos = pos.y[w,0:2]

mars_crust_model, upos, bout, /cain

store_data,'bcrustal',data = {x:time,y:bout}
options,'bcrustal','SPICE_FRAME','IAU_MARS'

spice_vector_rotate_tplot,'bcrustal','MAVEN_MSO'

end