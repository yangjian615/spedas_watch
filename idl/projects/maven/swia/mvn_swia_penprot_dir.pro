;+
;PROCEDURE: 
;	MVN_SWIA_PENPROT_DIR
;PURPOSE: 
;	Routine to determine density and velocity of penetrating protons at periapsis
;	Uses directional spectra to better filter out penetrating proton population
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PENPROT_DIR, REG = REG, NPO = NPO, /ARCHIVE
;INPUTS:
;KEYWORDS:
;	REG: region structure from 'mvn_swia_regid'
;	NPO: number of determinations per orbit
;	ARCHIVE: use archive data
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-12-08 13:10:18 -0800 (Mon, 08 Dec 2014) $
; $LastChangedRevision: 16405 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_penprot_dir.pro $
;
;-

pro mvn_swia_penprot_dir, reg = reg, npo = npo, archive = archive

mass = 0.0104389*1.6e-22
Const = (mass/(2.*1.6e-12))^0.5

if not keyword_set(npo) then npo = 1

common mvn_swia_data

if keyword_set(archive) then begin
	get_data,'mvn_swica_en_eflux_MSO_mX',data = data 
	denergy = data.v*(info_str[swica.info_index].deovere_coarse#replicate(1,48))
endif else begin
	get_data,'mvn_swics_en_eflux_MSO_mX',data = data
	denergy = data.v*(info_str[swics.info_index].deovere_coarse#replicate(1,48))
endelse

if keyword_set(reg) then begin
	ureg = interpol(reg.y(*,0),reg.x,data.x)
	w = where(ureg eq 4)
	times = data.x(w)
	spectra = data.y(w,*)
	energies = data.v(w,*)
	denergies = denergy(w,*)
endif else begin
	times = data.x
	spectra = data.y
	energies = data.v
	denergies = denergy
endelse

orb = mvn_orbit_num(time = times)
orb = floor((orb+0.5)*npo)  ; deal with silly orbit convention

mino = min(orb)
maxo = max(orb)
norb = maxo-mino+1

nout = fltarr(norb)
vout = fltarr(norb)
tout = dblarr(norb)

for i = 0,norb-1 do begin
	w = where(orb eq (mino+i),nw)		
	if nw gt 5 then begin
		spec = total(spectra(w,*),1,/nan)/nw
		energy = total(energies(w,*),1,/nan)/nw
		denergy = total(denergies(w,*),1,/nan)/nw
		
		wr = where(energy gt 200 and energy lt 4000)
		nout(i) = Const*!pi*total(denergy(wr)*energy(wr)^(-1.5)*spec(wr))
		spec = spec-min(spec(wr)) > 0

		maxc = max(spec(wr),maxi)
		eout = energy(wr(maxi))
		vout(i) = sqrt(2*eout*1.6e-19/1.67e-27)/1e3
		tout(i) = mean(times(w),/double,/nan)
	endif
endfor

w = where(tout ne 0)

store_data,'npen',data = {x:tout(w),y:nout(w)}
store_data,'vpen',data = {x:tout(w),y:vout(w)}

end