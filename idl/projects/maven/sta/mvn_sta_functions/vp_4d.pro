;+
;FUNCTION:	vp_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
;INPUT:	
;	dat:	structure,	3d data structure filled by themis routines mvn_sta_get_???
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
;	Returns the perpendicular velocity of a beam in units of km/s for apid C8
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;-
function vp_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, 0
endif

if dat2.apid ne 'C8' and dat2.apid ne 'CA' then begin
	print,'Invalid Data: Data must be Maven APID C8 or CA'
	return, 0
endif

dat = conv_units(dat2,"counts")		; initially use counts
n_e = dat.nenergy
n_m = dat.nmass
mass_amu = dat.mass_arr
data = dat.data
energy = dat.energy
if dat2.apid eq 'CA' then data = total(reform(data,16,4,16),2)

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
endif

charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if keyword_set(ms) then mass_amu = ms
mass = dat.mass*mass_amu

v = (2.*energy/mass)^.5								; km/s  note - mass=mass/charge, energy=energy/charge, charge cancels
if dat2.apid eq 'CA' then begin
	phi = total(reform(dat.phi,16,4,16),2)/4.
	sth = sin(phi/!radeg) 
endif else sth = sin(dat.theta/!radeg)
vp = v*sth									; km/s

vperp = total(vp*data)/total(data)

return, vperp									; km/s

end

