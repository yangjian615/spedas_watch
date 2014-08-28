;+
; Procedure: gse2agsm
;
; Purpose: 
;      Converts between GSE coordinates and aberrated GSM coordinates
;
; Inputs:
;      in_data: structure containing data to be transformed in GSE coordinates
;   
; Output: 
;      out_data: structure containing the transformed data in aberrated GSM coordinates
;   
; Keywords:
;      sw_velocity (optional): vector containing solar wind velocity data, [Vx, Vy, Vz] in GSE coordinates
;      rotation_angle (optional): angle to rotate about the Z axis to point into the solar wind (degrees)
;
;
; Notes:
;     Either the solar wind velocity (/sw_velocity) or rotation angle (/rotation_angle) keyword
;     needs to be defined to do the transformation
;      
; Examples:
;    In the following example, the data to be transformed into aGSM coordinates 
;      is in a standard tplot variable named 'position_gse'. 
;    
;    get_data, 'position_gse', data=position_gse
;     
;    ; load solar wind velocity data using OMNI (GSE coordinates, km/s)
;    omni_hro_load, varformat=['Vx', 'Vy', 'Vz']
;    
;    ; remove NaNs from the solar wind velocity
;    tdeflag, ['OMNI_HRO_1min_Vx', 'OMNI_HRO_1min_Vy', 'OMNI_HRO_1min_Vz'], 'remove_nan'
;
;    ; get the IDL structures containing the velocity components
;    get_data, 'OMNI_HRO_1min_Vx_deflag', data=Vx_data
;    get_data, 'OMNI_HRO_1min_Vy_deflag', data=Vy_data
;    get_data, 'OMNI_HRO_1min_Vz_deflag', data=Vz_data
;    
;    option 1:
;        ; do the transformation to aberrated GSM (aGSM) using a rotation angle
;        gse2agsm, position_gse, agsm_pos_from_angle, rotation_angle=4.0
;    
;    option 2:
;        ; do the transformation to aberrated GSM (aGSM) using solar wind velocity loaded from OMNI
;        gse2agsm, position_gse, agsm_pos_from_vel, sw_velocity = [[Vx_data.Y], [Vy_data.Y], [Vz_data.Y]]
;    
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-25 15:48:12 -0800 (Tue, 25 Feb 2014) $
; $LastChangedRevision: 14436 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/gse2agsm.pro $
;-
pro gse2agsm, data_in, data_out, sw_velocity = sw_velocity, rotation_angle = rotation_angle, aGSM2GSE = aGSM2GSE

    cotrans_lib
    ; check the input
    if is_string(data_in) then begin
        ; received a tplot variable as input
        
        if n_elements(tnames(data_in)) gt 1 then begin
            dprint, dlevel = 1, 'gse2agsm only supports one input at a time'
            return
        endif
        if ~tnames(data_in) then begin
            dprint, dlevel = 1, 'string input is not a valid tplot variable'
            return
        endif
        
        in_name = data_in
        out_name = data_out
        
        get_data, data_in, data=in_data_struct, dlimits=in_dlimits_struct, limits=in_limits_struct

    endif else if is_struct(data_in) then begin
        ; received a structure as input
        in_data_struct = data_in
    endif else begin
        dprint, dlevel = 1, 'Error in gse2agsm, input data must be a structure'
        return
    endelse

    if undefined(aGSM2GSE) then begin
        dprint, 'GSE -> aGSM'
    endif else begin
        dprint, 'aGSM -> GSE'
    endelse

    ; first do the aberration in GSE coordinates
    ; rotate about the z-GSE axis by an angle, rotation_angle
    if ~undefined(rotation_angle) then begin
        ; user provided the rotation angle
        rot_y = rotation_angle*!dtor
    endif else if ~undefined(sw_velocity) then begin
        ; user provided the solar wind velocity
        ; rotation angle about Z-GSE axis
        ; assumes Earth's orbital velocity relative to the sun is ~30km/s
        rot_y = atan((float(sw_velocity[*,1])+30.)/abs(float(sw_velocity[*,0])))

    endif else begin
        ; the user did not provide a rotation angle or solar wind velocity
        dprint, dlevel = 1, 'Error converting between GSE and aGSM coordinates - no rotation angle provided'
        return
    endelse 

    if ~undefined(aGSM2GSE) then begin
        rot_y = -rot_y
    endif
    dprint, 'rotating about the z-axis by: ' + string(rot_y/!dtor) + ' degrees'

    sin_rot = sin(rot_y)
    cos_rot = cos(rot_y)

    thematrix = [[cos_rot, -sin_rot, 0],[sin_rot, cos_rot, 0], [0, 0, 1]]
    
    in_data = [[in_data_struct.Y[*,0]], [in_data_struct.Y[*,1]], [in_data_struct.Y[*,2]]]

    ; now do the aberration in GSE
    the_arr = thematrix#transpose(in_data)
    x_out = transpose(the_arr[0,*])
    y_out = transpose(the_arr[1,*])
    z_out = transpose(the_arr[2,*])

    if ~undefined(aGSM2GSE) then begin
        data_att = in_dlimits_struct.data_att
        str_element, data_att, 'coord_sys', 'gse', /add_replace
        str_element, in_dlimits_struct, 'data_att', data_att, /add_replace
    endif else begin
        data_att = in_dlimits_struct.data_att
        str_element, data_att, 'coord_sys', 'agsm', /add_replace
        str_element, in_dlimits_struct, 'data_att', data_att, /add_replace
    endelse
    
    
    ; now rotate into aGSM
    sub_GSE2aGSM,{x: in_data_struct.X, y: [[x_out],[y_out],[z_out]]},agsm_out,aGSM2GSE=aGSM2GSE
    store_data, data_out, data=agsm_out, dlimits=in_dlimits_struct
    
    ;data_out = agsm_out
    if ~undefined(in_name) then data_in = in_name 
    if ~undefined(out_name) then data_out = out_name
    
end