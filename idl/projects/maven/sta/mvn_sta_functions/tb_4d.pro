;+
;FUNCTION:	tb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_c6.pro, mvn_sta_d0.pro, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -90<theta<90 
;				phi   min,max (0,1),(1,1)   0<phi<360 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;PURPOSE:
;	Returns the temperature of a beam in units of eV 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;-
function tb_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, 0
endif

dat = conv_units(dat2,"counts")		; initially use counts
dat = omni4d(dat,/mass)
n_e = dat.nenergy

data = dat.data
energy = dat.energy
if n_e eq 64 then nne=8 
if n_e eq 32 then nne=4
if n_e le 16 then nne=2
if n_e eq 48 then nne=6		; when does this happen? is this for swia?

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
endif
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
endif

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
if dat.nmass eq 1 then begin
	if dat.time lt time_double('14-10-1') then begin
		maxcnt = max(data,mind)
		if n_e eq 64 then nnne=4 else nnne=nne
		data[0:(mind-nnne>0)]=0.
		data[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
	endif	
endif

; limit the energy range to near the peak
	if ndimen(data) eq 2 then begin
		maxcnt = max(total(data,2),mind) 
		data[0:(mind-nne>0),*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
	endif else begin
		maxcnt = max(data,mind)
		data[0:(mind-nne>0)]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
	endelse

charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if keyword_set(mincnt) then if total(data) lt mincnt then return,0

; Note - we don't need to divide by mass

v = (2.*energy*charge)^.5		; km/s
v = v>0.001

; Notes	f ~ Counts/v^4 = C/v^4 
; 	dv/v = constant for logrithmic sweep
;	vd = integral(fv v^2dv)/integral(f v^2dv) = sum(C/v^4 * v^4 *dv/v)/sum(C/v^4 * v^3 *dv/v) = sum(C)/sum(C/v)
;	vth^2 = integral(f(v-vd)^2 v^2dv)/integral(f v^2dv) = sum(C/v^4 * (v-vd)^2 * v^3 *dv/v)/sum(C/v^4 * v^3 *dv/v) = sum(C/v * (v-vd)^2)/sum(C/v)

if keyword_set(ms) then begin
	vd = total(data)/(total(data/v)>1.e-20)
	if keyword_set(mi) then if mi lt 1.5 then vd=0
	vth2  = total((v-vd)^2*data/v)/(total(data/v)>1.e-20)
endif else begin
	vd = total(data,1)/(total(data/v,1)>1.e-20)
	vd = replicate(1.,n_e)#reform(vd,n_elements(vd))
;print,v[*,0]
;print,' '
;print,reform(vd[0,*])
	vth2  = total((v-vd)^2*data/v,1)/(total(data/v,1)>1.e-20)
;print,'num',total((v-vd)^2*data/v,1)
;print,' '
;print,'den',total(data/v,1)>1.e-20
;print,' '
endelse

return, vth2/2.

end

