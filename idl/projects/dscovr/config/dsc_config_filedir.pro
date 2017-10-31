;+
;NAME: DSC_CONFIG_FILEDIR
;
;DESCRIPTION:
; Get the applications user directory for DSCOVR
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-


FUNCTION DSC_CONFIG_FILEDIR, APP_QUERY = app_query, _EXTRA=_extra

COMPILE_OPT IDL2
  readme_txt = ['Directory for configuration files for use by DSCOVR']

  if (keyword_set(app_query)) then begin
    tdir = app_user_dir_query('dsc', 'dsc_config', /restrict_os)
    if (n_elements(tdir) EQ 1) then tdir = tdir[0]
    RETURN, tdir
  endif else begin
    RETURN, app_user_dir('dsc', 'DSCOVR Configuration',$
      'dsc_config', $
      'DSCOVR configuration directory',$
      readme_txt, 1, /restrict_os)
  endelse

END

