;+
;NAME:
; thm_check_valid_name
;
;
;PURPOSE:
; Temporary fix
; Calls ssl_check_valid_name
;

;-
Function thm_check_valid_name, names_in, valid_names, include_all = include_all, $
                               ignore_case = ignore_case, invalid=invalid, $
                               loose_interpretation = loose_interpretation, $
                               type=type, no_warning = no_warning

  otp = ssl_check_valid_name(names_in, valid_names, include_all = include_all, $
                               ignore_case = ignore_case, invalid=invalid, $
                               loose_interpretation = loose_interpretation, $
                               type=type, no_warning = no_warning)  
  
  Return, otp
End

