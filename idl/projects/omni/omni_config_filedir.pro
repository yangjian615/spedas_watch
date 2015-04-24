;+
;Function: omni_config_filedir.pro
;Purpose: Get the applications user directory for OMNI data
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-22 15:41:37 -0700 (Wed, 22 Apr 2015) $
;$LastChangedRevision: 17398 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_config_filedir.pro $
;-
Function omni_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the SPEDAS Data Analysis Software']

  Return, app_user_dir('omni', 'OMNI Configuration', $
                       'omni_config', $
                       'omni configuration Directory', $
                       readme_txt, 1, /restrict_os)

End
