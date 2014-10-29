;+
;FUNCTION:	nb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
;INPUT:	
;	dat:	structure,	3d data structure filled by themis routines get_th?_p???
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
;	MASS:	intarr(nm)	optional, 
;PURPOSE:
;	Returns the density of a beam in units of km/s
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-05-2
;LAST MODIFICATION:
;-
function nb_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, 0
endif

dat = omni4d(dat2,/mass)
n_e = dat.nenergy
data = dat.data
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
domega = dat.domega
;	if ndimen(domega) eq 0 then domega=replicate(1.,dat.nenergy)#domega
if n_e eq 64 then nne=4 else nne=3
if n_e eq 48 then nne=6


if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
endif
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
; 		the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
	if dat.time lt time_double('14-10-1') then begin
		tcnts = total(data,2)
		maxcnt = max(tcnts,mind)
		data[0:(mind-nne>0),*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
	endif	
endif

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
if dat.nmass eq 1 then begin
	if dat.time lt time_double('14-10-1') then begin
		maxcnt = max(data,mind)
		data[0:(mind-nne>0)]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
	endif	
endif

if dat.nmass gt 1 then begin
	if keyword_set(mi) then begin
		dat.mass_arr[*]=mi & mass=dat.mass*dat.mass_arr 
	endif else begin
		dat.mass_arr[*]=round(dat.mass_arr-.1)>1. & mass=dat.mass*dat.mass_arr	; the minus 0.1 helps account for straggling at low mass
	endelse
endif else mass = dat.mass

dat.data=data
dat = conv_units(dat,"df")		; Use distribution function
data=dat.data

Const = (mass)^(-1.5)*(2.)^(.5)
charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if keyword_set(ms) then begin
	density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi)
endif else begin
	density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
endelse

return, density

end

