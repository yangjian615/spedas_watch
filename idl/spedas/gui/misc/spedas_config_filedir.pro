;+
;Function: spedas_config_filedir.pro
;Purpose: Get the applications user directory for SPEDAS data analysis software
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2013-10-26 12:08:47 -0700 (Sat, 26 Oct 2013) $
;$LastChangedRevision: 13403 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/api_examples/file_configuration_tab/spedas_config_filedir.pro $
;-
Function spedas_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the SPEDAS Data Analysis Software']
   
 If(keyword_set(app_query)) Then Begin
   tdir = app_user_dir_query('spedas', 'spedas_config', /restrict_os)
   If(n_elements(tdir) Eq 1) Then tdir = tdir[0]
   Return, tdir
 Endif Else Begin
   Return, app_user_dir('spedas', 'SPEDAS Configuration Process', $
     'spedas_config', $
     'SPEDAS configuration Directory', $
     readme_txt, 1, /restrict_os)
 Endelse                     

End
