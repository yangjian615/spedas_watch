;+
;Procedure:
;  mms_get_fpi_dist
;
;Purpose:
;  Returns 3D particle data structures containing MMS FPI
;  data for use with spd_slice2d. 
;
;Calling Sequence:
;  data = mms_get_fpi_dist(tname, [trange=trange], [index=index], [/structure])
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
;$LastChangedDate: 2015-10-14 17:28:32 -0700 (Wed, 14 Oct 2015) $
;$LastChangedRevision: 19075 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_get_fpi_dist.pro $
;-

function mms_get_fpi_dist, tname, trange=trange, index, structure=structure

    compile_opt idl2


name = (tnames(tname))[0]
if name eq '' then begin
  dprint, 'Variable: "'+tname+'" not found'
  return, 0
endif

;pull data and metadata
get_data, name, ptr=p

if ~is_struct(p) then begin
  dprint, 'Variable: "'+tname+'" contains invalid data'
  return, 0
endif

if size(*p.y,/n_dim) ne 4 then begin
  dprint, 'Variable: "'+tname+'" has wrong number of elements'
  return, 0
endif


; Allow calling code to request a time range and/or specify index
; to specific sample.  This allows calling code to extract 
; structures one at time and improves efficency in other cases.
;-----------------------------------------------------------------

;get range of indices corresponding to requested time range
if ~undefined(trange) then begin
  tr = time_double(trange)
  indices = minmax(where( *p.x ge min(tr) and *p.x lt max(tr), n_times))
endif else begin
  n_times = n_elements(*p.x)
  indices = [0,n_times-1]
endelse

;apply requisted index within requested time range so that calling 
;code can loop without accessing sample times
if ~undefined(index) then begin
  if n_elements(index) ne 1 then return, 0
  if index lt 0 or index gt n_times-1 then return, 0
  indices += index
  n_times = 1
endif

;for clarity later
start = indices[0]
stop = indices[1]

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
dim = (size(*p.y,/dim))[1:*]
dim = dim[[2,0,1] ]
base_arr = fltarr(dim)


;get support data
step_name = (tnames(var_info[1]+'stepTable_parity'))[0]
if step_name eq '' then begin
  dprint, 'Cannot find energy table data: "'+var_info[1]+'stepTable_parity'
  return, 0
endif
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

dist = replicate(template, n_times)


; Populate
;-----------------------------------------------------------------
dist.time = (*p.x)[start:stop]
dist.end_time = (*p.x)[start:stop] + .1499 ;TODO: get actual integration time

;shuffle data to be energy-azimuth-elevation-time
;time must be last to be added to structure array
dist.data = transpose((*p.y)[start:stop,*,*,*],[3,1,2,0])

;get energy values for each time sample and copy into
;structure array with the correct dimensions
e0 = reform(energy_table[*,step.y[start:stop]], [dim[0],1,1,n_times])
dist.energy = rebin( e0, [dim,n_times] )

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