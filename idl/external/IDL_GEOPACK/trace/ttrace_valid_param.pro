;+
;Procedure : ttrace_valid_param
;
;Purpose: Helper function used by ttrace2equator and ttrace2iono
;        
; $LastChangedBy: lphilpott $
; $LastChangedDate: 2012-06-15 11:25:01 -0700 (Fri, 15 Jun 2012) $
; $LastChangedRevision: 10567 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/trace/ttrace_valid_param.pro $
;-
function ttrace_valid_param, in_val, name_string, pos_name

  COMPILE_OPT HIDDEN, IDL2

  if n_elements(in_val) gt 0 then begin

    ;if in_val is a string, assume in_val is stored in a tplot variable

    if size(in_val, /type) eq 7 then begin

      if tnames(in_val) eq '' then begin

        message, /continue, name_string + $

' is of type string but no tplot variable of that name exists'

        return, -1L

      endif

      ;make sure there are an appropriate number of pdyn values in the

;array

      tinterpol_mxn, in_val, pos_name, out=d_verify, error =$

 e

      if e ne 0 then begin

        return, d_verify.y

      endif else begin

        message, /continue, 'error interpolating ' + name_string + $

' onto position data'

        return, -1L

      endelse

    endif else return, in_val

  endif

  message, /continue, 'Warning: Unable to read ' + name_string + $

' defaulting to 0.'

  get_data, pos_name, data = d

  return, dblarr(n_elements(d.x))

end
