;+
;Procedure:
;  mms_cotrans_qtransformer
;
;Purpose:
;  Helps simplify transformation logic code using a recursive formulation.
;  Rather than specifying the set of transformations for each combination of
;  in_coord & out_coord, this routine will perform only the nearest transformation
;  then make a recursive call to itself, with each call performing one additional
;  step in the chain.  This makes it so only neighboring coordinate transforms
;  need be specified.
;
;  All possible transformations currently go through ECI coordinates 
;
;Input:
;  in_name:  name ofvariable to be transformed
;  out_name:  output name for transformed variable
;  in_coord:  coordinate system of the input
;  out_coord:  coordinate system of the output
;  probe:  probe designation for input variable
;
;Output:
;  No explicit output, calls transformation routines and itself
;
;Notes:
;  Modeled after thm_cotrans_transform_helper
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-10 18:47:10 -0700 (Tue, 10 May 2016) $
;$LastChangedRevision: 21057 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_cotrans_qtransformer.pro $
;-

pro mms_cotrans_qtransformer, $

  ; names and coords
  in_name, $
  out_name, $
  in_coord, $
  out_coord, $
  probe, $

  ; other
  ignore_dlimits=ignore_dlimits


  compile_opt idl2, hidden


  ; Do not transform to/from spinning frames if quaternion time resulotion 
  ; is lower than nyquist rate.  All transforms have a single middle step (ECI)
  ; so this should catch all cases w/o leaving a partially transformed var.
  if mms_qcotrans_check_rate(in_coord,out_coord,probe) then return


  ; Final coordinate system reached
  ;------------------------------------------------
  if in_coord eq out_coord then begin
    if in_name ne out_name then begin
      copy_data, in_name, out_name
    endif
    return
  endif


  ; Execute next step in transformation tree
  ;   -everything goes through ECI at the moment, so this is very simple
  ;------------------------------------------------
  case in_coord of

    ; ECI
    ;----------
    'eci': begin
      if in_set(out_coord[0],['bcs','dbcs','dmpa','smpa','dsl','ssl','gse','gse2000','gsm','sm','geo']) then begin
        q_name = 'mms'+probe+'_mec_quat_eci_to_'+out_coord
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        mms_cotrans_qrotate, in_name, q_name, out_name
        recursive_in_coord = out_coord
      endif else begin
        dprint, dlevel=0, sublevel=1, 'Unknown transformation: "'+ in_coord+'" to "'+out_coord+'"'
        recursive_in_coord = out_coord
      endelse
    end


    ; Other
    ;---------------------------
    else: begin
      if in_set(in_coord[0],['bcs','dbcs','dmpa','smpa','dsl','ssl','gse','gse2000','gsm','sm','geo']) then begin
        q_name = 'mms'+probe+'_mec_quat_eci_to_'+in_coord
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        mms_cotrans_qrotate, in_name, q_name, out_name, /inverse
        recursive_in_coord = 'eci'
      endif else begin
        dprint, dlevel=0, sublevel=1, 'Unknown transformation: "'+ in_coord+'" to "'+out_coord+'"'
        recursive_in_coord = out_coord
      endelse
    endelse

  endcase


  ; Recurse
  ;   -if this was the final step then the next iteration will return
  ;------------------------------------------------
  mms_cotrans_qtransformer,$
    out_name, $  ;don't create new vars as we iterate
    out_name, $
    recursive_in_coord, $  ;result of this iteration
    out_coord, $
    probe, $
    ignore_dlimits=ignore_dlimits

end