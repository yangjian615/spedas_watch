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
;      rotation_angle (optional): angle to rotate about the Z axis to point into the solar wind
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
; $LastChangedDate: 2013-12-16 10:46:21 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13675 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/gse2agsm.pro $
;-
pro gse2agsm, data_in, data_out, sw_velocity = sw_velocity, rotation_angle = rotation_angle

    cotrans_lib
    if ~is_struct(data_in) then begin
        dprint, dlevel = 1, 'Error in gse2agsm, input data must be a structure'
        return
    endif

    dprint, 'GSE -> aGSM'

    ; first do the aberration in GSE coordinates
    ; rotate about the z-GSE axis by an angle, rotation_angle
    if ~undefined(rotation_angle) then begin
        ; user provided the rotation angle
        rot_y = rotation_angle
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
    dprint, dlevel = 4, 'rotating about the z-axis by: ' + string(rot_y/!dtor) + ' degrees'

    sin_rot = sin(rot_y)
    cos_rot = cos(rot_y)

    ; now do the aberration in GSE
    x_out = cos_rot*data_in.Y[*,0]+sin_rot*data_in.Y[*,1]
    y_out = -sin_rot*data_in.Y[*,0]+cos_rot*data_in.Y[*,1]
    z_out = data_in.Y[*,2]
   
    ; now rotate into aGSM
    sub_GSE2GSM,{x: data_in.X, y: [[x_out],[y_out],[z_out]]},agsm_out
    
    data_out = agsm_out
end