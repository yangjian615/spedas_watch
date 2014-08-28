;+
;FUNCTION:	dv_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
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
;PURPOSE:
;	Returns the velocity, [Vx,Vy,Vz], km/s for each mass bin 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	14-02-26	
;LAST MODIFICATION:
;-
function dv_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q

vel = [0.,0.,0.]

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, vel
endif

flux = j_4d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
density = n_4d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
dflux = dj_4d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
ddensity = dn_4d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)

nm = n_elements(density)

if keyword_set(ms) then begin
	dvel1 = dflux/(density+1.e-10)
	dvel2 = flux*ddensity/(density+1.e-10)^2
	dvel = 1.e-5*((dvel1)^2+(dvel2)^2)^.5
endif else begin
	dvel1 = reform([dflux[0,*]/(density+1.e-10),dflux[1,*]/(density+1.e-10),dflux[2,*]/(density+1.e-10)],3,nm)
	dvel2 = reform([flux[0,*]*ddensity/(density+1.e-10)^2,flux[1,*]*ddensity/(density+1.e-10)^2,flux[2,*]*ddensity/(density+1.e-10)^2],3,nm)
	dvel = 1.e-5*((dvel1)^2+(dvel2)^2)^.5
endelse

return, dvel

end

