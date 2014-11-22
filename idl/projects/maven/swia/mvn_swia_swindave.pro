;+
;PROCEDURE: 
;	MVN_SWIA_SWINDAVE
;PURPOSE: 
;	Routine to determine density and velocity of undisturbed upstream solar wind
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_SWINDAVE, REG = REG
;INPUTS:
;KEYWORDS:
;	REG: region structure from 'mvn_swia_regid'
;	NPO: number of determinations per orbit
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-11-19 15:39:14 -0800 (Wed, 19 Nov 2014) $
; $LastChangedRevision: 16250 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_swindave.pro $
;
;-

pro mvn_swia_swindave, reg = reg, npo = npo

common mvn_swia_data

if not keyword_set(npo) then npo = 1

if keyword_set(reg) then begin
	ureg = interpol(reg.y(*,0),reg.x,swim.time_unix+2.0)
	w = where(ureg eq 1)
	uswim = swim(w)
endif else begin
	uswim = swim
endelse

times = uswim.time_unix
vels = sqrt(total(uswim.velocity*uswim.velocity,1))
densities = uswim.density


orb = mvn_orbit_num(time = times)
orb = floor(orb*npo)

mino = min(orb)
maxo = max(orb)
norb = maxo-mino+1

nout = fltarr(norb)
vout = fltarr(norb)
tout = dblarr(norb)

for i = 0,norb-1 do begin
	w = where(orb eq (mino+i),nw)
	if nw gt 10 then begin
		nout(i) = mean(densities(w),/nan)

		vout(i) = mean(vels(w),/nan)
		tout(i) = mean(uswim(w).time_unix,/double,/nan)
	endif
endfor

w = where(tout ne 0)

store_data,'nsw',data = {x:tout(w),y:nout(w)}
store_data,'vsw',data = {x:tout(w),y:vout(w)}

end