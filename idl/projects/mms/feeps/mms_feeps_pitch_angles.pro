;+
; PROCEDURE:
;         mms_feeps_pitch_angles
;
; PURPOSE:
;         Generates a tplot variable containing the FEEPS pitch angles for each telescope
;         from magnetic field data.
;
;
; NOTES:
;         Most of this routine was copy+pasted from routines provided by Drew Turner
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-24 14:43:32 -0700 (Fri, 24 Mar 2017) $
;$LastChangedRevision: 23031 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_pitch_angles.pro $
;-

pro mms_feeps_pitch_angles, trange=trange, probe=probe, level=level, data_rate=data_rate, datatype=datatype, suffix=suffix
  if undefined(suffix) then suffix = ''
  if undefined(datatype) then datatype = 'electron' else datatype = strlowcase(datatype)
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(level) then level = 'l2'
  
  ; get the times from the currently loaded FEEPS data
  get_data, 'mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pitch_angle'+suffix, data=pad_data, dlimits=pad_dl

  if ~is_struct(pad_data) then begin
    dprint, dlevel = 0, 'Error, could not find current pitch angle variable for time array'
    return
  endif
  
  if undefined(trange) then trange=timerange(minmax(pad_data.X))

  ; load the B-field data if not already loaded
  if (tnames('mms'+probe+'_fgm_b_bcs_srvy_l2_bvec'))[0] eq '' then mms_load_fgm, trange=trange, probe=probe
  get_data, 'mms'+probe+'_fgm_b_bcs_srvy_l2_bvec', data=b_field_data
  
  if ~is_struct(b_field_data) then begin
    ; couldn't find the L2 FGM data, try the L2pre DFG data instead:
    if (tnames('mms'+probe+'_dfg_b_bcs_srvy_l2pre_bvec') eq '') then mms_load_fgm, trange=trange, probe=probe, level='l2pre', instrument='dfg'
    get_data, 'mms'+probe+'_dfg_b_bcs_srvy_l2pre_bvec', data=b_field_data
    
    if ~is_struct(b_field_data) then begin
        ; one more fallback - L1b
        if (tnames('mms'+probe+'_dfg_srvy_bcs_bvec') eq '') then mms_load_fgm, trange=trange, probe=probe, level='l1b', instrument='dfg'
        get_data, 'mms'+probe+'_dfg_srvy_bcs_bvec', data=b_field_data
        if ~is_struct(b_field_data) then begin
          dprint, dlevel = 0, "Error, couldn't load B-field data for calculating FEEPS pitch angles"
          return
        endif
    endif
  endif
  Bbcs = b_field_data.Y
  
  nbins = 13; number of pitch angle bins; 10 deg = 17 bins, 15 deg = 13 bins
  dpa = 180.0/nbins ; delta-pitch angle for each bin
  
  ; Rotation matrices for FEEPS coord system (FCS) into body coordinate system (BCS):
  Ttop = [[1./sqrt(2.), -1./sqrt(2.), 0], [1./sqrt(2.), 1./sqrt(2.), 0], [0, 0, 1]]
  Tbot = [[-1./sqrt(2.), -1./sqrt(2.), 0], [-1./sqrt(2.), 1./sqrt(2.), 0], [0, 0, -1]]

  ; Telescope vectors in FCS:
  V1fcs = [0.347, -0.837, 0.423]
  V2fcs = [0.347, -0.837, -0.423]
  V3fcs = [0.837, -0.347, 0.423]
  V4fcs = [0.837, -0.347, -0.423]
  V5fcs = [-0.087, 0.000, 0.996]
  V6fcs = [0.104, 0.180, 0.978]
  V7fcs = [0.654, -0.377, 0.656]
  V8fcs = [0.654, -0.377, -0.656]
  V9fcs = [0.837, 0.347, 0.423]
  V10fcs = [0.837, 0.347, -0.423]
  V11fcs = [0.347, 0.837, 0.423]
  V12fcs = [0.347, 0.837, -0.423]
  
  if datatype eq 'electron' then begin
    pas = dblarr(n_elements(b_field_data.X), 18)   ; pitch angles for each eye at each time

    ; Telescope vectors in Body Coordinate System:
    ;   Factors of -1 account for 180 deg shift between particle velocity and telescope normal direction:
    ; Top:
    Vt1bcs = [-1.*(Ttop[0,0]*V1fcs[0] + Ttop[1,0]*V1fcs[1] + Ttop[2,0]*V1fcs[2]), $
      -1.*(Ttop[0,1]*V1fcs[0] + Ttop[1,1]*V1fcs[1] + Ttop[2,1]*V1fcs[2]), $
      -1.*(Ttop[0,2]*V1fcs[0] + Ttop[1,2]*V1fcs[1] + Ttop[2,2]*V1fcs[2])]
    Vt2bcs = [-1.*(Ttop[0,0]*V2fcs[0] + Ttop[1,0]*V2fcs[1] + Ttop[2,0]*V2fcs[2]), $
      -1.*(Ttop[0,1]*V2fcs[0] + Ttop[1,1]*V2fcs[1] + Ttop[2,1]*V2fcs[2]), $
      -1.*(Ttop[0,2]*V2fcs[0] + Ttop[1,2]*V2fcs[1] + Ttop[2,2]*V2fcs[2])]
    Vt3bcs = [-1.*(Ttop[0,0]*V3fcs[0] + Ttop[1,0]*V3fcs[1] + Ttop[2,0]*V3fcs[2]), $
      -1.*(Ttop[0,1]*V3fcs[0] + Ttop[1,1]*V3fcs[1] + Ttop[2,1]*V3fcs[2]), $
      -1.*(Ttop[0,2]*V3fcs[0] + Ttop[1,2]*V3fcs[1] + Ttop[2,2]*V3fcs[2])]
    Vt4bcs = [-1.*(Ttop[0,0]*V4fcs[0] + Ttop[1,0]*V4fcs[1] + Ttop[2,0]*V4fcs[2]), $
      -1.*(Ttop[0,1]*V4fcs[0] + Ttop[1,1]*V4fcs[1] + Ttop[2,1]*V4fcs[2]), $
      -1.*(Ttop[0,2]*V4fcs[0] + Ttop[1,2]*V4fcs[1] + Ttop[2,2]*V4fcs[2])]
    Vt5bcs = [-1.*(Ttop[0,0]*V5fcs[0] + Ttop[1,0]*V5fcs[1] + Ttop[2,0]*V5fcs[2]), $
      -1.*(Ttop[0,1]*V5fcs[0] + Ttop[1,1]*V5fcs[1] + Ttop[2,1]*V5fcs[2]), $
      -1.*( Ttop[0,2]*V5fcs[0] + Ttop[1,2]*V5fcs[1] + Ttop[2,2]*V5fcs[2])]
    Vt9bcs = [-1.*(Ttop[0,0]*V9fcs[0] + Ttop[1,0]*V9fcs[1] + Ttop[2,0]*V9fcs[2]), $
      -1.*(Ttop[0,1]*V9fcs[0] + Ttop[1,1]*V9fcs[1] + Ttop[2,1]*V9fcs[2]), $
      -1.*(Ttop[0,2]*V9fcs[0] + Ttop[1,2]*V9fcs[1] + Ttop[2,2]*V9fcs[2])]
    Vt10bcs = [-1.*(Ttop[0,0]*V10fcs[0] + Ttop[1,0]*V10fcs[1] + Ttop[2,0]*V10fcs[2]), $
      -1.*(Ttop[0,1]*V10fcs[0] + Ttop[1,1]*V10fcs[1] + Ttop[2,1]*V10fcs[2]), $
      -1.*(Ttop[0,2]*V10fcs[0] + Ttop[1,2]*V10fcs[1] + Ttop[2,2]*V10fcs[2])]
    Vt11bcs = [-1.*(Ttop[0,0]*V11fcs[0] + Ttop[1,0]*V11fcs[1] + Ttop[2,0]*V11fcs[2]), $
      -1.*(Ttop[0,1]*V11fcs[0] + Ttop[1,1]*V11fcs[1] + Ttop[2,1]*V11fcs[2]), $
      -1.*(Ttop[0,2]*V11fcs[0] + Ttop[1,2]*V11fcs[1] + Ttop[2,2]*V11fcs[2])]
    Vt12bcs = [-1.*(Ttop[0,0]*V12fcs[0] + Ttop[1,0]*V12fcs[1] + Ttop[2,0]*V12fcs[2]), $
      -1.*(Ttop[0,1]*V12fcs[0] + Ttop[1,1]*V12fcs[1] + Ttop[2,1]*V12fcs[2]), $
      -1.*(Ttop[0,2]*V12fcs[0] + Ttop[1,2]*V12fcs[1] + Ttop[2,2]*V12fcs[2])]
    ; Bottom:
    Vb1bcs = [-1.*(Tbot[0,0]*V1fcs[0] + Tbot[1,0]*V1fcs[1] + Tbot[2,0]*V1fcs[2]), $
      -1.*(Tbot[0,1]*V1fcs[0] + Tbot[1,1]*V1fcs[1] + Tbot[2,1]*V1fcs[2]), $
      -1.*(Tbot[0,2]*V1fcs[0] + Tbot[1,2]*V1fcs[1] + Tbot[2,2]*V1fcs[2])]
    Vb2bcs = [-1.*(Tbot[0,0]*V2fcs[0] + Tbot[1,0]*V2fcs[1] + Tbot[2,0]*V2fcs[2]), $
      -1.*(Tbot[0,1]*V2fcs[0] + Tbot[1,1]*V2fcs[1] + Tbot[2,1]*V2fcs[2]), $
      -1.*(Tbot[0,2]*V2fcs[0] + Tbot[1,2]*V2fcs[1] + Tbot[2,2]*V2fcs[2])]
    Vb3bcs = [-1.*(Tbot[0,0]*V3fcs[0] + Tbot[1,0]*V3fcs[1] + Tbot[2,0]*V3fcs[2]), $
      -1.*(Tbot[0,1]*V3fcs[0] + Tbot[1,1]*V3fcs[1] + Tbot[2,1]*V3fcs[2]), $
      -1.*(Tbot[0,2]*V3fcs[0] + Tbot[1,2]*V3fcs[1] + Tbot[2,2]*V3fcs[2])]
    Vb4bcs = [-1.*(Tbot[0,0]*V4fcs[0] + Tbot[1,0]*V4fcs[1] + Tbot[2,0]*V4fcs[2]), $
      -1.*(Tbot[0,1]*V4fcs[0] + Tbot[1,1]*V4fcs[1] + Tbot[2,1]*V4fcs[2]), $
      -1.*(Tbot[0,2]*V4fcs[0] + Tbot[1,2]*V4fcs[1] + Tbot[2,2]*V4fcs[2])]
    Vb5bcs = [-1.*(Tbot[0,0]*V5fcs[0] + Tbot[1,0]*V5fcs[1] + Tbot[2,0]*V5fcs[2]), $
      -1.*(Tbot[0,1]*V5fcs[0] + Tbot[1,1]*V5fcs[1] + Tbot[2,1]*V5fcs[2]), $
      -1.*(Tbot[0,2]*V5fcs[0] + Tbot[1,2]*V5fcs[1] + Tbot[2,2]*V5fcs[2])]
    Vb9bcs = [-1.*(Tbot[0,0]*V9fcs[0] + Tbot[1,0]*V9fcs[1] + Tbot[2,0]*V9fcs[2]), $
      -1.*(Tbot[0,1]*V9fcs[0] + Tbot[1,1]*V9fcs[1] + Tbot[2,1]*V9fcs[2]), $
      -1.*(Tbot[0,2]*V9fcs[0] + Tbot[1,2]*V9fcs[1] + Tbot[2,2]*V9fcs[2])]
    Vb10bcs = [-1.*(Tbot[0,0]*V10fcs[0] + Tbot[1,0]*V10fcs[1] + Tbot[2,0]*V10fcs[2]), $
      -1.*(Tbot[0,1]*V10fcs[0] + Tbot[1,1]*V10fcs[1] + Tbot[2,1]*V10fcs[2]), $
      -1.*(Tbot[0,2]*V10fcs[0] + Tbot[1,2]*V10fcs[1] + Tbot[2,2]*V10fcs[2])]
    Vb11bcs = [-1.*(Tbot[0,0]*V11fcs[0] + Tbot[1,0]*V11fcs[1] + Tbot[2,0]*V11fcs[2]), $
      -1.*(Tbot[0,1]*V11fcs[0] + Tbot[1,1]*V11fcs[1] + Tbot[2,1]*V11fcs[2]), $
      -1.*(Tbot[0,2]*V11fcs[0] + Tbot[1,2]*V11fcs[1] + Tbot[2,2]*V11fcs[2])]
    Vb12bcs = [-1.*(Tbot[0,0]*V12fcs[0] + Tbot[1,0]*V12fcs[1] + Tbot[2,0]*V12fcs[2]), $
      -1.*(Tbot[0,1]*V12fcs[0] + Tbot[1,1]*V12fcs[1] + Tbot[2,1]*V12fcs[2]), $
      -1.*(Tbot[0,2]*V12fcs[0] + Tbot[1,2]*V12fcs[1] + Tbot[2,2]*V12fcs[2])]
      
    for i = 0,17 do begin
      if i eq 0 then begin
        Vbcs = Vt1bcs
      endif
      if i eq 1 then begin
        Vbcs = Vt2bcs
      endif
      if i eq 2 then begin
        Vbcs = Vt3bcs
      endif
      if i eq 3 then begin
        Vbcs = Vt4bcs
      endif
      if i eq 4 then begin
        Vbcs = Vt5bcs
      endif
      if i eq 5 then begin
        Vbcs = Vt9bcs
      endif
      if i eq 6 then begin
        Vbcs = Vt10bcs
      endif
      if i eq 7 then begin
        Vbcs = Vt11bcs
      endif
      if i eq 8 then begin
        Vbcs = Vt12bcs
      endif
      if i eq 9 then begin
        Vbcs = Vb1bcs
      endif
      if i eq 10 then begin
        Vbcs = Vb2bcs
      endif
      if i eq 11 then begin
        Vbcs = Vb3bcs
      endif
      if i eq 12 then begin
        Vbcs = Vb4bcs
      endif
      if i eq 13 then begin
        Vbcs = Vb5bcs
      endif
      if i eq 14 then begin
        Vbcs = Vb9bcs
      endif
      if i eq 15 then begin
        Vbcs = Vb10bcs
      endif
      if i eq 16 then begin
        Vbcs = Vb11bcs
      endif
      if i eq 17 then begin
        Vbcs = Vb12bcs
      endif
      pas[*, i] = 180.0/!dpi * acos((Vbcs[0]*Bbcs[*,0] + Vbcs[1]*Bbcs[*,1] + Vbcs[2]*Bbcs[*,2])/(sqrt(Vbcs[0]^2+Vbcs[1]^2+Vbcs[2]^2) * sqrt(Bbcs[*,0]^2+Bbcs[*,1]^2+Bbcs[*,2]^2)))
    endfor
    if data_rate eq 'srvy' then begin
      ; srvy data only loads the sensor IDs: ['3', '4', '5', '11', '12'] 
      new_pas = dblarr(n_elements(b_field_data.X), 10)
      ; top first
      new_pas[*, 0] = pas[*, 2]
      new_pas[*, 1] = pas[*, 3]
      new_pas[*, 2] = pas[*, 4]
      new_pas[*, 3] = pas[*, 7]
      new_pas[*, 4] = pas[*, 8]
      ; now bottom
      new_pas[*, 5] = pas[*, 11]
      new_pas[*, 6] = pas[*, 12]
      new_pas[*, 7] = pas[*, 13]
      new_pas[*, 8] = pas[*, 16]
      new_pas[*, 9] = pas[*, 17]
    endif else new_pas = pas
  endif else if datatype eq 'ion' then begin
    pas = dblarr(n_elements(b_field_data.X), 6)   ; pitch angles at each time
    ; Telescope vectors in Body Coordinate System:
    ;   Factors of -1 account for 180 deg shift between particle velocity and telescope normal direction:
    ; Top:
    Vt6bcs = [-1.*(Ttop[0,0]*V6fcs[0] + Ttop[1,0]*V6fcs[1] + Ttop[2,0]*V6fcs[2]), $
      -1.*(Ttop[0,1]*V6fcs[0] + Ttop[1,1]*V6fcs[1] + Ttop[2,1]*V6fcs[2]), $
      -1.*(Ttop[0,2]*V6fcs[0] + Ttop[1,2]*V6fcs[1] + Ttop[2,2]*V6fcs[2])]
    Vt7bcs = [-1.*(Ttop[0,0]*V7fcs[0] + Ttop[1,0]*V7fcs[1] + Ttop[2,0]*V7fcs[2]), $
      -1.*(Ttop[0,1]*V7fcs[0] + Ttop[1,1]*V7fcs[1] + Ttop[2,1]*V7fcs[2]), $
      -1.*(Ttop[0,2]*V7fcs[0] + Ttop[1,2]*V7fcs[1] + Ttop[2,2]*V7fcs[2])]
    Vt8bcs = [-1.*(Ttop[0,0]*V8fcs[0] + Ttop[1,0]*V8fcs[1] + Ttop[2,0]*V8fcs[2]), $
      -1.*( Ttop[0,1]*V8fcs[0] + Ttop[1,1]*V8fcs[1] + Ttop[2,1]*V8fcs[2]), $
      -1.*(Ttop[0,2]*V8fcs[0] + Ttop[1,2]*V8fcs[1] + Ttop[2,2]*V8fcs[2])]
    ; Bottom:
    Vb6bcs = [-1.*(Tbot[0,0]*V6fcs[0] + Tbot[1,0]*V6fcs[1] + Tbot[2,0]*V6fcs[2]), $
      -1.*(Tbot[0,1]*V6fcs[0] + Tbot[1,1]*V6fcs[1] + Tbot[2,1]*V6fcs[2]), $
      -1.*( Tbot[0,2]*V6fcs[0] + Tbot[1,2]*V6fcs[1] + Tbot[2,2]*V6fcs[2])]
    Vb7bcs = [-1.*(Tbot[0,0]*V7fcs[0] + Tbot[1,0]*V7fcs[1] + Tbot[2,0]*V7fcs[2]), $
      -1.*(Tbot[0,1]*V7fcs[0] + Tbot[1,1]*V7fcs[1] + Tbot[2,1]*V7fcs[2]), $
      -1.*(Tbot[0,2]*V7fcs[0] + Tbot[1,2]*V7fcs[1] + Tbot[2,2]*V7fcs[2])]
    Vb8bcs = [-1.*(Tbot[0,0]*V8fcs[0] + Tbot[1,0]*V8fcs[1] + Tbot[2,0]*V8fcs[2]), $
      -1.*(Tbot[0,1]*V8fcs[0] + Tbot[1,1]*V8fcs[1] + Tbot[2,1]*V8fcs[2]), $
      -1.*(Tbot[0,2]*V8fcs[0] + Tbot[1,2]*V8fcs[1] + Tbot[2,2]*V8fcs[2])]
      
    for i = 0,5 do begin
      if i eq 0 then begin
        Vbcs = Vt6bcs
      endif
      if i eq 1 then begin
        Vbcs = Vt7bcs
      endif
      if i eq 2 then begin
        Vbcs = Vt8bcs
      endif
      if i eq 3 then begin
        Vbcs = Vb6bcs
      endif
      if i eq 4 then begin
        Vbcs = Vb7bcs
      endif
      if i eq 5 then begin
        Vbcs = Vb8bcs
      endif

      pas[*, i] = 180.0/!dpi * acos((Vbcs[0]*Bbcs[*,0] + Vbcs[1]*Bbcs[*,1] + Vbcs[2]*Bbcs[*,2])/(sqrt(Vbcs[0]^2+Vbcs[1]^2+Vbcs[2]^2) * sqrt(Bbcs[*,0]^2+Bbcs[*,1]^2+Bbcs[*,2]^2)))
    endfor
    new_pas = pas
  endif
  outvar = 'mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pa'+suffix
  store_data, outvar, data={x: b_field_data.X, y: new_pas}, dlimits=pad_dl
  
  ; interpolate onto the FEEPS timestamps
  tinterpol, outvar, 'mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pitch_angle'+suffix, /overwrite
  
end