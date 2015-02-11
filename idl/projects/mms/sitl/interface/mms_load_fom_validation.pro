function mms_load_fom_validation

; Here are the validation parameters for the FOM
  fom_gmax = 200                ; Maximum FOM size based on guidlines
  fom_bounds = [0, 255]         ; Absolute FOM range
  seg_bounds = [1, 60]         ; Absolute segment size range
  buff_max = 1000.              ; Maximum number of selectable buffers
  p1_percent = 33.              ; Percentage of selections which are priority 1 before warning
  nominal_seg_range = [2, 200]   ; Nominal range for segment lengths, warning if exceeded
  type1_range = [100, 199]      ; Fom range for priority 1 events, as defined in the SITL manual
  type2_range = [50, 99]        ; Fom range for priority 2 events, as defined in the SITL manual
  type3_range = [25, 49]        ; Fom range for priority 3 events, as defined in the SITL manual
  type4_range = [0, 24]         ; Fom range for priority 4 events, as defined in the SITL manual
 
  fom_del_max = 100             ; When working with the backstructure, deleting burst segments with
                                ; a FOM over this value will lead to a warning.
  fom_mod_percent = 0.4         ; When modifying an existing FOM value, a warning will appear if the
                                ; new FOM is within this fraction of the original value.

  validation_struct = {fom_gmax: fom_gmax, $
                       fom_bounds: fom_bounds, $
                       seg_bounds: seg_bounds, $
                       buff_max: buff_max, $
                       p1_percent: p1_percent, $
                       nominal_seg_range: nominal_seg_range, $
                       type1_range: type1_range, $
                       type2_range: type2_range, $
                       type3_range: type3_range, $
                       type4_range: type4_range, $
                       fom_del_max: fom_del_max, $
                       fom_mod_percent: fom_mod_percent}
                       
return, validation_struct


end
