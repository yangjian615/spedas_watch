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
;         The data should be in three dimensions: (time, energy, elevation)
;  pointer: Flag to return a pointer instead of structure array.  
;
;Output:
;  return value: array of pseudo 3D particle distribution structures
;                or 0 in case of error
;
;Notes:
;  **EXPERIMENTAL!**
;  
;  Caveats:
;    -Azimuths have not been synchronized with sun data and are currently
;     measured from an arbitrary point.
;    -Spacecraft spin and sweep times are assumed to be ideal.
;    -Only tested with burst data.
;    -Masses of ions larger than h+ slightly off.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-16 20:14:13 -0700 (Wed, 16 Sep 2015) $
;$LastChangedRevision: 18812 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_get_hpca_dist.pro $
;-

function mms_get_hpca_dist, tname, pointer=pointer

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

;get angle tables & info
s = mms_get_hpca_info()

;dimensions
dim = (size(d.y,/dim))[1:*]
base_arr = fltarr(dim)

;energy bins are constant
energy = d.v2 # replicate(1.,dim[1])

;elevations bins are constant
;  -index by anode number in case order is inconsistent
;  -convert to from colat to lat
theta = replicate(1.,dim[0]) # (90 - s.elevation[d.v1])

;azimuth offsets should be constant to first approximation
;populate phi with them now and add further adjustments later 
phi_direction = replicate(1.,dim[0]) # s.azimuth_direction[d.v1]
phi_offset = s.azimuth_energy_offset # replicate(1.,dim[1])
phi = phi_direction + phi_offset

;not physical values, just for plotting
;TODO: should be dynamic
dtheta = replicate(22.5, dim)
dphi = replicate(11.25, dim)

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

; Create pseudo-3D distributions
;  -The simplest method to convert the data into a compatible format is to treat
;   each sample as a separate distribution.  Combining every 16 samples into a 
;   3D distribution would yield a more memory efficient end product but would 
;   also be a more complex process.  Spd_slice2d already aggregates & averages
;   data across time so the results should be identical.
;-----------------------------------------------------------------

;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: species, $
  units_name: datatype, $ ;TODO: set units dynamically
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
  phi: phi, $
  dphi: dphi, $
  theta: theta, $
  dtheta: dtheta $
}

dist = replicate(template, n_elements(d.x))


; Populate and correct the rest of the data
;-----------------------------------------------------------------

;this time difference probably shouldn't be used for physical calculations yet
dist.time = d.x
dist.end_time = d.x + s.t_sweep

;time of last sun pulse
;just use arbitrary reference point for testing
sun_pulse = d.x[0]

;some items need a loop to be set
for i=0,  n_elements(dist)-1 do begin

  ;azimuthal correction based on spin
  phi_shift = 360./s.t_spin * ( dist[i].time - sun_pulse ) mod 360
  
  dist[i].phi += phi_shift
  dist[i].data = d.y[i,*,*]
  
endfor


;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(pointer) then begin
  return, ptr_new(dist,/no_copy) 
endif else begin
  return, dist
endelse


end
