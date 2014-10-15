;+
;PROCEDURE:	
;	MVN_SWIA_ADD_MAGF
;PURPOSE:	
;	Add magnetic field (in SWIA coordinates) to SWIA fine and coarse common blocks 
;
;INPUT:		
;
;KEYWORDS:
;	BDATA: tplot variable for the magnetic field 
;	(will be converted to 'MAVEN_SWIA' frame - so needs 'SPICE_FRAME' defined to work)
;
;AUTHOR:	J. Halekas	
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-10-10 08:45:32 -0700 (Fri, 10 Oct 2014) $
; $LastChangedRevision: 15973 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_add_magf.pro $
;
;-

pro mvn_swia_add_magf, bdata = bdata

;FIXME: In the future might want to average over the accumulation time or some-such
; (currently just samples field at the start of the sweep)

compile_opt idl2

common mvn_swia_data

if not keyword_set(bdata) then bdata = 'mvn_mag1_pl_ql'

spice_vector_rotate_tplot,bdata,'MAVEN_SWIA'

get_data,bdata+'_MAVEN_SWIA',data = bswia

if n_elements(swifs) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swifs.time_unix)
	uby = interpol(bswia.y[*,1],bswia.x,swifs.time_unix)
	ubz = interpol(bswia.y[*,2],bswia.x,swifs.time_unix)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swifs,'magf',magf,/add

endif

if n_elements(swifa) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swifa.time_unix)
	uby = interpol(bswia.y[*,1],bswia.x,swifa.time_unix)
	ubz = interpol(bswia.y[*,2],bswia.x,swifa.time_unix)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swifa,'magf',magf,/add

endif

if n_elements(swics) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swics.time_unix)
	uby = interpol(bswia.y[*,1],bswia.x,swics.time_unix)
	ubz = interpol(bswia.y[*,2],bswia.x,swics.time_unix)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swics,'magf',magf,/add

endif

if n_elements(swica) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swica.time_unix)
	uby = interpol(bswia.y[*,1],bswia.x,swica.time_unix)
	ubz = interpol(bswia.y[*,2],bswia.x,swica.time_unix)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swica,'magf',magf,/add

endif


end
