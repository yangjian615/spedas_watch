;+
;PROCEDURE: 
;	MVN_SWIA_SWINDAVE
;PURPOSE: 
;	Routine to determine density and velocity of undisturbed upstream solar wind
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_SWINDAVE, REG = REG, IMF = IMF
;INPUTS:
;KEYWORDS:
;	REG: region structure from 'mvn_swia_regid'
;	NPO: number of determinations per orbit
;	IMF: if set, calculate upstream IMF
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-12-29 05:31:31 -0800 (Mon, 29 Dec 2014) $
; $LastChangedRevision: 16544 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_swindave.pro $
;
;-

pro mvn_swia_swindave, reg = reg, npo = npo, imf = imf, bdata = bdata

common mvn_swia_data

if not keyword_set(bdata) then bdata = 'mvn_B_1sec_MAVEN_MSO'
if not keyword_set(npo) then npo = 1

if keyword_set(reg) then begin
	ureg = interpol(reg.y[*,0],reg.x,swim.time_unix+2.0)
	w = where(ureg eq 1)
	uswim = swim[w]
endif else begin
	uswim = swim
endelse

times = uswim.time_unix
vels = sqrt(total(uswim.velocity*uswim.velocity,1))
densities = uswim.density

if keyword_set(imf) then begin
	get_data,bdata,data = bvec
	bx = interpol(bvec.y[*,0],bvec.x,times)
	by = interpol(bvec.y[*,1],bvec.x,times)
	bz = interpol(bvec.y[*,2],bvec.x,times)
endif

orb = mvn_orbit_num(time = times)
orb = floor(orb*npo)

mino = min(orb)
maxo = max(orb)
norb = maxo-mino+1

nout = fltarr(norb)
vout = fltarr(norb)
tout = dblarr(norb)

if keyword_set(imf) then begin
	bxout = fltarr(norb)
	byout = fltarr(norb)
	bzout = fltarr(norb)
endif

for i = 0,norb-1 do begin
	w = where(orb eq (mino+i),nw)
	if nw gt 10 then begin
		nout(i) = mean(densities[w],/nan)

		vout(i) = mean(vels[w],/nan)
		tout(i) = mean(uswim[w].time_unix,/double,/nan)

		if keyword_set(imf) then begin
			bxout(i) = mean(bx(w),/nan)
			byout(i) = mean(by(w),/nan)
			bzout(i) = mean(bz(w),/nan)
		endif
	endif
endfor

w = where(tout ne 0)

store_data,'nsw',data = {x:tout[w],y:nout[w]}
store_data,'vsw',data = {x:tout[w],y:vout[w]}

if keyword_set(imf) then store_data,'bsw',data = {x:tout(w),y:[[bxout[w]],[byout[w]],[bzout[w]]],v:[0,1,2]}

end