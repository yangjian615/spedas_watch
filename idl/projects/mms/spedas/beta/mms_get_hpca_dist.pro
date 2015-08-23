;+
;Procedure:
;  mms_get_hpca_dist
;
;Purpose:
;  Returns a pointer to a THEMIS-like array of particle distributions.
;  This is intended for testing with THEMIS slice routines.
;
;Calling Sequence:
;  pointer = mms_get_hpca_dist(tname)
;
;Input:
;  tname: Tplot variable containing the desired data.
;         The data should be in three dimensions: (time, energy, elevation)  
;
;Output:
;  return value: pointer to array of pseudo 3D particle distribution structures
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
;$LastChangedDate: 2015-08-21 19:29:30 -0700 (Fri, 21 Aug 2015) $
;$LastChangedRevision: 18580 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_get_hpca_dist.pro $
;-

function mms_get_hpca_dist, tname

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
phi_direction = replicate(1.,dim[0]) # s.azimuth_direction
phi_offset = s.azimuth_energy_offset # replicate(1.,dim[1])
phi = phi_direction + phi_offset

;not physical values, just for plotting
;TODO: should be dynamic
dtheta = replicate(22.5, dim)
dphi = replicate(11.25, dim)

;get mass & charge from species
m = 0.0104389 ;proton mass in eV/(km/s)^2
case species of 
  'hplus':begin
    mass = m
    charge = 1.
  end
  'heplus':begin
    mass = 4*m
    charge = 1.
  end
  'heplusplus':begin
    mass = 4*m
    charge = 2.
  end
  'oplus':begin
    mass = 16*m
    charge = 1.
  end
  'oplusplus':begin
    mass = 16*m
    charge = 2.
  end
  else: begin
    dprint, 'Cannot determine species'
    return, 0
  endelse
endcase

; Create pseudo-3D distributions
;  -The simplest method to convert the data into a recognisable format is to treat
;   each sample as a separate distribution.  Combining every 16 samples into a 
;   THEMIS-like 3D distribution would yield a more memory efficient end product
;   but would also be a more complex process.  The slice2d routines already 
;   aggregate & average data across time so the results should be identical.
;-----------------------------------------------------------------

;basic template structure that should be compatible with slice2d routines
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: species, $
  units_name: datatype, $
  units_procedure: '', $ ;placeholder
  apid: 0, $  ;placeholder
  valid: 1b, $

  charge: charge, $
  mass: mass, $  
  magf: replicate(!values.f_nan,3), $ ;placeholder
  velocity: replicate(!values.f_nan,3), $ ;placeholder

  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
;  scaling: base_arr, $ ;placeholder for spectra/moments
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
  phi_shift = 360./s.t_spin * ( d.x[i] - sun_pulse ) mod 360

  dist[i].phi += phi_shift
  dist[i].data = d.y[i,*,*]
  
endfor


;THEMIS routines expect a pointer
ptr = ptr_new(dist,/no_copy) 

return, ptr


end
