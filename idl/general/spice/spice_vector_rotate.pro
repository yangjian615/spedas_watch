;+
;Function: SPICE_VECTOR_ROTATE
;Purpose:  Rotate a vector from one frame to another frame
;Usage:   vector_prime = spice_vector_rotate(ut,vector,from_frame,to_frame, check_objects='Frame')
;Inputs:    VECTOR:  3xN array
;           FROM_FRAME:  String or id - valid SPICE FRAME
;           TO_FRAME:    string or id - valid SPICE FRAME
;Output:    VECTOR_PRIME:  3xN array - vector as measured in the TO_FRAME
;  Note: time is in the last dimension  (not like tplot storage)
; 
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function spice_vector_rotate,utc,vector,et=et,from_frame,to_frame,check_objects=check_objects,verbose=verbose

ut = time_double(utc)
et = time_ephemeris(ut,/ut2et)
dprint,dlevel=3,verbose=verbose,'Obtaining rotations'
qrot =  spice_body_att(from_frame,to_frame,ut,/quaternion,check_object=check_objects,verbose=verbose) 
dprint,dlevel=3,verbose=verbose,'Start Vector Rotations'
vector_prime = quaternion_rotation(vector,qrot,/last_ind)     
dprint,dlevel=3,verbose=verbose,'Done with Rotations'
return,vector_prime
end


