;+
;Procedure:
;  mms_get_fpi_dist
;
;Purpose:
;  Returns 3D particle data structures containing MMS FPI
;  data for use with spd_slice2d. 
;
;Calling Sequence:
;  data = mms_get_hpca_dist(tname)
;
;Input:
;  tname: Tplot variable containing the desired data.
;  structure: Flag to return a structure array instead of a pointer.  
;
;Output:
;  return value: pointer to array of 3D particle distribution structures
;                or 0 in case of error
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-10-02 20:00:08 -0700 (Fri, 02 Oct 2015) $
;$LastChangedRevision: 18994 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_get_fpi_dist.pro $
;-

function mms_get_fpi_dist, tname, structure=structure

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

if size(d.y,/n_dim) ne 4 then begin
  dprint, 'Variable: "'+tname+'" has wrong number of elements'
  return, 0
endif

;get info from tplot variable name
var_info = stregex(name, '(mms([1-4])_d([ei])s_)brstSkyMap_dist', /subexpr, /extract)
probe = var_info[2]
species = var_info[3]


; Initialize energies, angles, and support data
;-----------------------------------------------------------------

;get energy tables
s = mms_get_fpi_info()

;dimensions
;data is stored as azimuth x elevation x energy
;slice code expects energy to be the first dimension
dim = (size(d.y,/dim))[1:*]
dim = dim[[2,0,1] ]
base_arr = fltarr(dim)


;get support data
azimuth_name = (tnames(var_info[1]+'startDelPhi_angle'))[0]
if azimuth_name eq '' then begin
  dprint, 'Cannot find azimuth data: "'+var_info[1]+'startDelPhi_angle'
  return, 0
endif

step_name = (tnames(var_info[1]+'stepTable_parity'))[0]
if step_name eq '' then begin
  dprint, 'Cannot find energy table data: "'+var_info[1]+'stepTable_parity'
  return, 0
endif

get_data, azimuth_name, data=azimuth 
get_data, step_name, data=step


;mass, charge, & energies
;  -slice routines assume mass in eV/(km/s)^2
case strlowcase(species) of 
  'i': begin
         mass = 1.04535e-2
         charge = 1.
         energy_table = transpose(s.ion_energy) 
         data_name = 'FPI Ion'
       end
  'e': begin
         mass = 5.68566e-06
         charge = -1.
         energy_table = transpose(s.electron_energy)
         data_name = 'FPI Electron'
       end
  else: begin
    dprint, 'Cannot determine species'
    return, 0
  endelse
endcase

;elevations are constant
theta = rebin( reform(s.elevation,[1,1,dim[2]]), dim )

;phi grid is constant, offsets will be added later
phi = rebin( reform(s.azimuth,[1,dim[1]]), dim )

dphi = replicate(11.25, dim)
dtheta = replicate(11.25, dim)


; Create standard 3D distribution
;-----------------------------------------------------------------

;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: data_name, $
  units_name: 'dist fn', $
  units_procedure: '', $ ;placeholder
  valid: 1b, $

  charge: charge, $
  mass: mass, $  
  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
  bins: base_arr+1, $ ;must be set or data will be considered invalid

  energy: base_arr, $
  denergy: base_arr, $ ;placeholder
  phi: phi, $
  dphi: dphi, $
  theta: theta, $
  dtheta: dtheta $
}

dist = replicate(template, n_elements(d.x))


; Populate
;-----------------------------------------------------------------
dist.time = d.x
dist.end_time = d.x+.1499 ;TODO: get actual integration time

dist.data = transpose(d.y,[3,1,2,0])

;get energy values for each time sample and copy into
;structure array with the correct dimensions
e0 = reform(energy_table[*,step.y], [dim[0],1,1,n_elements(d.x)])
dist.energy = rebin( e0, [dim,n_elements(d.x)] )

;add phi offset to (near) GSE
for i=0, n_elements(d.x)-1 do begin
  dist[i].phi += azimuth.y[i]
endfor

;phi must be in [0,360)
dist.phi = dist.phi mod 360

;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(structure) then begin
  return, dist 
endif else begin
  return, ptr_new(dist,/no_copy)
endelse


end