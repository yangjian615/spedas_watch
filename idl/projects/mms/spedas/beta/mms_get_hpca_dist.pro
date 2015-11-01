;+
;Procedure:
;  mms_get_hpca_dist
;
;Purpose:
;  Returns pseudo-3D particle data structures containing mms hpca data
;  for use with spd_slice2d.
;
;Calling Sequence:
;  data = mms_get_hpca_dist(tname)
;
;Input:
;  tname: Tplot variable containing the desired data.
;  structure: Flag to return a structure array instead of a pointer.  
;
;Output:
;  return value: pointer to array of pseudo 3D particle distribution structures
;                or 0 in case of error
;
;Notes:
;  This is a work in progress
;
;  **Currently requires angle data that is not available for download**
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-10-30 19:54:06 -0700 (Fri, 30 Oct 2015) $
;$LastChangedRevision: 19203 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_get_hpca_dist.pro $
;-

function mms_get_hpca_dist, tname, structure=structure

    compile_opt idl2


name = (tnames(tname))[0]
if name eq '' then begin
  dprint, 'Variable: "'+tname+'" not found'
  return, 0
endif

;pull data and metadata
get_data, name, data=d, dlimits=dl

if ~is_struct(d) then begin
  dprint, 'Variable: "'+tname+'" contains invalid data'
  return, 0
endif

if size(d.y,/n_dim) ne 3 then begin
  dprint, 'Variable: "'+tname+'" has wrong number of elements'
  return, 0
endif

;get some basic info from name
var_info = stregex(name, 'mms([1-4])_hpca_([^_]+)_(.+)', /subexpr, /extract)
probe = var_info[1]
species = var_info[2]
datatype = var_info[3]


; Initialize energies, angles, and support data
;-----------------------------------------------------------------

s = mms_get_hpca_info()

;get azimuth data from ancillary file
;this will be used to set phi angles and as the timestamps of the final distributions
get_data, 'mms'+probe+'_hpca_azimuth_angles_degrees', data=azimuth 

;find azimuth times with complete 1/2 spins of particle data
;this is used to determine the number of 3D distributions that will be created
;and where their corresponding data is located in the particle data structure
n_times = n_elements(azimuth.y[0,0,*])
idx = value_locate(d.x, azimuth.x)
full = where( (idx[1:*] - idx[0:n_elements(idx)-2]) eq n_times, n_full)
if n_full eq 0 then begin
  dprint, 'No azimuth data found for current time range'
  return, 0
endif
idx = idx[full]

;dimensions (energy-azimuth-elevation)
dim = [dimen2(d.y), dimen2(azimuth.y), (dimen(d.y))[2]]
base_arr = fltarr(dim)

;mass & charge of species
;  -slice routines assume mass in eV/(km/s)^2
case species of 
  'hplus':begin
    mass = 1.04535e-2
    charge = 1.
  end
  'heplus':begin
    mass = 4.18138e-2
    charge = 1.
  end
  'heplusplus':begin
    mass = 4.18138e-2
    charge = 2.
  end
  'oplus':begin
    mass = 0.167255
    charge = 1.
  end
  'oplusplus':begin
    mass = 0.167255
    charge = 2.
  end
  else: begin
    dprint, 'Cannot determine species'
    return, 0
  endelse
endcase

;energy bins are constant
energy = rebin(d.v2, dim)

;elevations bins are constant
;  -index by anode number in case order is inconsistent
;  -convert to from colat to lat
theta = rebin( reform((90 - s.elevation[d.v1]),[1,1,dim[2]]), dim)
dtheta = replicate(22.5, dim)

;azimuths are be populated below


; Create standard 3D distributions
;-----------------------------------------------------------------

;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: 'HPCA '+species, $
  units_name: 'f (s!U3!N/cm!U6!N)', $
  units_procedure: '', $ ;placeholder
  valid: 1b, $

  charge: charge, $
  mass: mass, $  
  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
  bins: base_arr+1, $ ;must be set or data will be considered invalid

  energy: energy, $
  denergy: base_arr, $
  phi: base_arr, $
  dphi: base_arr, $
  theta: theta, $
  dtheta: dtheta $
}

dist = replicate(template, n_full)


; Populate the structures
;-----------------------------------------------------------------

;get start/end times
;  -this assumes that the times from the particle (and angle) data 
;   are at the center of the corresponding energy sweep
dt = azimuth.x[1:*] - azimuth.x[0:*]  ;delta-time for each 1/2 spin
dt_sweep = d.x[1:*] - d.x[0:*]        ;delta-time for each full energy sweep
dist.time = azimuth.x[full] - dt_sweep[idx[full]]
dist.end_time = dist.time + dt[full]  ;index won't exceed elements due to selection criteria

;shuffle and expand applicable azimuth data 
;  -shift from from time-elevation-azimuth to azimuth-elevation-time
;   (time must be last to be added to structure array)
;  -expand to energy-azimuth-elevation-time
;   (energy sweep offsets will be added later)
phi = transpose(azimuth.y[full,*,*],[2,1,0])
dist.phi = rebin( reform(phi,[1,dimen(phi)]), [dim,n_full] )

;get dphi
;  -no vairation across elevation, probably very little across time
;  -median is used to discard large differences across 0=360
dphi = median( phi[1:*,0,*] - phi[0:dim[1]-2,0,*], dim=1 )
dist.dphi = rebin( reform(dphi, [1,1,1,n_full]), [dim,n_full] )

;add phi energy sweep offsets 
;  -phi values are for the center of each sweep
;  -this approximates the time between energy acquisitions as constant
;   (it is actually somewhat irregular)
n_steps = dim[0]+1  ;add one to account for flyback step at end of sweep  
dphi_energy = dphi / n_steps  ;delta-phi per energy step (approx.)
seed = findgen(n_steps) - (n_steps-1)/2.
seed = seed[0:n_steps-2]  ;discard flyback step
phi_offset = seed # dphi_energy
dist.phi += rebin( reform(phi_offset, [dim[0],1,1,n_full]), [dim,n_full])

;copy particle data
for i=0,  n_elements(dist)-1 do begin

  ;shift from azimuth-energy-elevation to energy-azimuth-elevation
  dist[i].data = transpose( d.y[idx[i]:idx[i]+(n_times-1),*,*], [1,0,2] )

endfor

;ensure phi values are in [0,360]
dist.phi = (dist.phi + 360) mod 360

;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(structure) then begin
  return, dist 
endif else begin
  return, ptr_new(dist,/no_copy)
endelse


end
