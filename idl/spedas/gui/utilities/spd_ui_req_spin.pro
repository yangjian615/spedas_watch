
;+ 
;NAME:
; spd_ui_req_spin
;
;PURPOSE:
; Determines availability of parameters for spin model.
;
;CALLING SEQUENCE:
; if spd_ui_req_spin((coordSys,value,probe,trange,loadedData) then begin
;   thm_load_state,probe=probe,trange=trange,/get_support
; endif
;
;INPUT:
; value:  a string storing the destination coordinate system
; active: the set of variables to be transformed
; loadedData: the loadedData object
; sobj: the status bar object to which messages should be sent
; silent(optional): set this keyword to suppress popup messages.(Used during replay)
; 
; 
;OUTPUT:
; none
; 
; SIDE EFFECT: New active variable for each prior active stored in loaded data
;   and transformed into the new coordinate system with suffix added/changed
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-02-21 13:54:28 -0800 (Fri, 21 Feb 2014) $
;$LastChangedRevision: 14413 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_req_spin.pro $
;
;---------------------------------------------------------------------------------



;helper function for spin tvar requirement checking to simplify code organization
function spd_ui_cotrans_new_req_spin_tvars_helper,in_coord,out_coord,trange,loadedData,varname

  compile_opt idl2,hidden
  
  varList = loadedData->getAll(/parent)
  
 ; left_coords = ['gse','gsm','sm','gei','geo','sse','sel','mag']
 ; right_coords = ['spg','ssl','dsl']
  coordSysObj = obj_new('spd_ui_coordinate_systems')
  left_coords = coordSysObj->makeCoordSysListForSpinModel()
  right_coords = coordSysObj->makeCoordSysListforTHEMIS(/include_dsl)
  obj_destroy, coordSysObj
  
  in_coord_tmp = strlowcase(in_coord[0])
  out_coord_tmp = strlowcase(out_coord[0])
  
  overlap_margin = 120. ;how many seconds can the spin variables not overlap on an end before fail
    
  ;if transforming from one set to the other, spinras & spindec vars are required
  if (in_set(in_coord_tmp,left_coords) && in_set(out_coord_tmp,right_coords)) || $
     (in_set(out_coord_tmp,left_coords) && in_set(in_coord_tmp,right_coords)) then begin
       
    ;first check availability on the command line
    tvarname = tnames(varname,trange=var_trange)   
    ;if command line tplot variable is unavailable
    ;uses 60 second margin on each end, 60 seconds in the state data cadence 
    if ~is_string(tvarname) || $
       var_trange[0] - overlap_margin gt trange[0] || $
       var_trange[1] + overlap_margin lt trange[1] then begin
       
       ;check gui loadedData
       if ~in_set(varname,varList) then begin
         return,1
       endif else begin
       
         ;var with correct name found, export and verify times.
         tmp = loadedData->getTvarData(varname)       
         tvarname = tnames(varname,trange=var_trange)
         
         ;export unsuccessful or times out of range
         ;uses 60 second margin on each end, 60 seconds in the state data cadence
         if ~is_string(tvarname) || $
            var_trange[0] - overlap_margin gt trange[0] || $
            var_trange[1] + overlap_margin lt trange[1] then begin
              return,1
         endif
       endelse
    endif ;if block is passed without returning, var found
    
  endif
  
  return,0

end

;determine if spin tplot variables are required for transformation
;Needed for any transformations that require 'gse2dsl' or 'dsl2gse'
;If variables are found in gui loadedData, will also be exported to command line for use with tplot
function spd_ui_cotrans_new_req_spin_tvars,in_coord,out_coord,probe,trange,loadedData

  compile_opt idl2,hidden

  ;name of the variables required
  spinras_cor = 'th'+probe+'_state_spinras_corrected'
  spindec_cor = 'th'+probe+'_state_spindec_corrected'
  spinras = 'th'+probe+'_state_spinras'
  spindec = 'th'+probe+'_state_spindec'
  
  
  if (~spd_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,loadedData,spinras_cor) && $
      ~spd_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,loadedData,spindec_cor)) || $
      (~spd_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,loadedData,spinras) && $
       ~spd_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,loadedData,spindec)) then begin
    return,0
  endif else begin
    return,1
  endelse

end

;determine if spin model is required for transformation
;Needed for any transformations that require 'ssl2dsl' or 'dsl2ssl'
function spd_ui_cotrans_new_req_spin_model,in_coord,out_coord,probe,trange

  compile_opt idl2,hidden

  ;left_coords = ['dsl','gse','gsm','sm','gei','geo','sse']
  ;right_coords = ['spg','ssl']
  coordsysobj = obj_new('spd_ui_coordinate_systems')
  left_coords = coordsysobj->makeCoordSysListForSpinModel(/include_dsl)
  right_coords = coordsysobj->makeCoordSysListForTHEMIS()
  obj_destroy, coordsysobj
  
  in_coord_tmp = strlowcase(in_coord[0])
  out_coord_tmp = strlowcase(out_coord[0])
  
  overlap_margin = 120. ;how many seconds can the spin variables not overlap on an end before fail
  
  ;if transforming from one set to the other, spinras & spindec vars are required
  if (in_set(in_coord_tmp,left_coords) && in_set(out_coord_tmp,right_coords)) || $
     (in_set(out_coord_tmp,left_coords) && in_set(in_coord_tmp,right_coords)) then begin
  
    spinmodel_ptr = spinmodel_get_ptr(probe)
    
    if ~obj_valid(spinmodel_ptr) then begin
      return,1
    endif
    
    spinmodel_get_info,model=spinmodel_ptr,start_time=model_start,end_time=model_end
    
    ;uses 60 second margin on each end, 60 seconds in the state data cadence
    if model_start - overlap_margin gt trange[0] || model_end + overlap_margin lt trange[1] then begin
      return,1
    endif
  
  endif
  return,0
end

function spd_ui_req_spin,in_coord,out_coord,probe,trange,loadedData

  compile_opt idl2,hidden
  
  return,spd_ui_cotrans_new_req_spin_tvars(in_coord,out_coord,probe,trange,loadedData) || spd_ui_cotrans_new_req_spin_model(in_coord,out_coord,probe,trange)
  
end
