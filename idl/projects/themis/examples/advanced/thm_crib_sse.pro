;+
;Procedure: sse_crib.pro
;
;Purpose:  A crib showing how to transform data from GSE to SSE coordinate system. 
;   SSE is defined as:
;        X: Moon->Sun Line projected into the ecliptic plane
;        Y: Z x X
;        Z: Ecliptic north
;
;Notes:
;
;  Code heavily based on make_mat_Rxy.pro & transform_gsm_to_rxy.pro by Christine Gabrielse(cgabrielse@ucla.edu)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 10:56:58 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13080 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_sse.pro $
;-

probe = 'a'
timespan,'2008-03-23'

thm_load_slp

cotrans,'slp_sun_pos','slp_sun_pos_gse',/gei2gse
cotrans,'slp_lun_pos','slp_lun_pos_gse',/gei2gse

sse_matrix_make,'slp_sun_pos_gse','slp_lun_pos_gse',newname='sse_mat'

;load fgm data to be transformed
thm_load_fgm,probe=probe,coord='gse'

;----------------------------------------------
;simple rotation

;because fgm data is not specified relative to the coordinate system's frame of reference
;transformation is rotational only
tvector_rotate,'sse_mat','th'+probe+'_fgl_gse'

tplot,['th'+probe+'_fgl_gse','th'+probe+'_fgl_gse_rot']

;----------------------------------------------

;----------------------------------------------
;inverse rotation

tvector_rotate,'sse_mat','th'+probe+'_fgl_gse_rot',newname='th'+probe+'_fgl_gse_inv',/invert

tplot,['th'+probe+'_fgl_gse','th'+probe+'_fgl_gse_inv','th'+probe+'_fgl_gse_rot']

;----------------------------------------------

;load state data to be transformed
thm_load_state,probe=probe
cotrans,'th'+probe+'_state_pos','th'+probe+'_state_pos',/gei2gse

;----------------------------------------------
;position transformation

;position is trickier, because it is measured with respect to coordinate center
;We need to perform an affine transformation which we do in 3 steps.

;first interpolate the moon position onto state position
tinterpol_mxn,'slp_lun_pos_gse','th'+probe+'_state_pos'

;next subtract the moon position from the state position to account for relative position of coordinate frames
calc,'"th'+probe+'_state_pos_sub"="th'+probe+'_state_pos"-"slp_lun_pos_gse_interp"',/verbose

;last perform the rotational component of the transformation.
tvector_rotate,'sse_mat','th'+probe+'_state_pos_sub',newname='th'+probe+'_state_pos_sse'

;----------------------------------------------
;velocity transformation

;velocity is even trickier, because the coordinate systems are in motion themselves.

;first generate spacecraft velocity in gse coordinates.
;Cotrans cannot properly account for relative velocity of coordinate systems
;when transforming, thus this is best done with derivative not cotrans or thm_cotrans.
deriv_data,'th'+probe+'_state_pos',newname='th'+probe+'_state_vel'

;second generate the lunar velocity in gse coordinates by
;taking the derivative of the lunar position in gse coordinates
deriv_data,'slp_lun_pos_gse',newname='slp_lun_vel_gse'

;third interpolate lunar velocity onto state velocity
tinterpol_mxn,'slp_lun_vel_gse','th'+probe+'_state_vel' 

;next subtract moon velocity from the state velocity to account for relative motion of coordinate frames
calc,'"th'+probe+'_state_vel_sub"="th'+probe+'_state_vel"-"slp_lun_vel_gse_interp"',/verbose

;finally rotate the data into the new coordinate system
tvector_rotate,'sse_mat','th'+probe+'_state_vel_sub',newname='th'+probe+'_state_vel_sse'

;----------------------------------------------

;----------------------------------------------
;inverse velocity transformation

;just do the transformation backwards.  First invert rotation, then invert offset

tvector_rotate,'sse_mat','th'+probe+'_state_vel_sse',newname='th'+probe+'_state_vel_sub_inv',/invert

calc,'"th'+probe+'_state_vel_sse_inv"="th'+probe+'_state_vel_sub_inv"+"slp_lun_vel_gse_interp"',/verbose

;Note:
; 1. This same affine transformation can be done for accelerations, by taking an additional
;derivative
; 2. Taking discrete derivatives will lead to approximation errors on the edges of the time series
end

