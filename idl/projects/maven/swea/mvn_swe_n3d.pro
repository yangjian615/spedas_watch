;+
;PROCEDURE: 
;	mvn_swe_n3d
;PURPOSE:
;	Determines density from a 3D distribution.  Wrapper for McFadden's n_3d.pro.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_n3d
;INPUTS: 
;KEYWORDS:
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
;
;   POTENTIAL: Spacecraft potential.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:49:36 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15677 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_n3d.pro $
;
;-

pro mvn_swe_n3d, EBINS=ebins, ABINS=abins, DBINS=dbins, pans=pans, archive=archive

  compile_opt idl2

  @mvn_swe_com
  
; Make sure data are loaded

  if (data_type(swe_3d) ne 8) then begin
    print,"Load SWEA data first.  Use mvn_swe_load_l0."
    return
  endif
  
  if (data_type(swe_sc_pot) ne 8) then begin
    print,"No spacecraft potential.  Use mvn_swe_sc_pot."
    return
  endif
  
  if keyword_set(archive) then aflg = 1 else aflg = 0
  
  c = 2.99792458D5                ; velocity of light [km/s]
  mass = (5.10998910D5)/(c*c)     ; electron rest mass [eV/(km/s)^2]    
  units = 'eflux'
  
  if (aflg) then t = swe_3d_arc.time else t = swe_3d.time
  npts = n_elements(t)
  density = fltarr(npts)
  
  for i=0L,(npts-1L) do begin
    ddd = mvn_swe_get3d(t[i],archive=aflg)
    str_element,ddd,'mass',mass,/add
    density[i] = swe_n_3d(ddd,ebins=ebins,abins=abins,dbins=dbins)
  endfor
  
; Create TPLOT variables

  store_data,'swe_density',data={x:t, y:density}
  options,'swe_density','ytitle','Ne (1/cc)'
  pans = ['swe_density']
  
  return

end
