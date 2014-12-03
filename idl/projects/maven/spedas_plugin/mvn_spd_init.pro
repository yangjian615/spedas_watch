;+
;NAME:
;mvn_spd_init
;PURPOSE:
;Initializes SPEDAS system variables for MAVEN SPD data. Can be called
;from idl_startup to set custom locations.
;KEYWORDS:
;reset=resets configuration data already in place on the machine
;local_data_dir=location to save data files on the local machine
;remote_data_dir=location of the data on the remote machine
;no_color_setup=skip setting up the graphics configuration
;HISTORY:
;2014-12-01 - Hacked from various _init programs, mostly goes_init,
;             jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-12-01 13:53:09 -0800 (Mon, 01 Dec 2014) $
;$LastChangedRevision: 16329 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_init.pro $
;-
Pro mvn_spd_init, reset=reset, local_data_dir=local_data_dir, $
                  remote_data_dir=remote_data_dir, $
                  no_color_setup = no_color_setup

  defsysv,'!maven_spd',exists=exists
  If(~keyword_set(exists)) Then Begin
     defsysv,'!maven_spd',  file_retrieve(/structure_format)
  Endif

  If(keyword_set(reset)) Then !maven_spd.init=0

  If(!maven_spd.init Ne 0) Then Return

  !maven_spd = file_retrieve(/structure_format)
;Read saved values from file
  ftest = mvn_spd_read_config()
  If(is_struct(ftest) && ~keyword_set(reset)) Then Begin
     !maven_spd.local_data_dir = ftest.local_data_dir
     !maven_spd.remote_data_dir = ftest.remote_data_dir
     !maven_spd.no_download = ftest.no_download
     !maven_spd.no_update = ftest.no_update
     !maven_spd.downloadonly = ftest.downloadonly
     !maven_spd.verbose = ftest.verbose
  Endif Else Begin              ; use defaults
     If(keyword_set(reset)) Then Begin
        dprint, 'Resetting !MAVEN_SPD to default configuration'
     Endif Else Begin
        dprint,'No !MAVEN_SPD config found...creating default configuration'
     Endelse
     !maven_spd.local_data_dir  = spd_default_local_data_dir() + 'maven' + path_sep()
     !maven_spd.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/maven/data/sci/'
  Endelse
  !maven_spd.min_age_limit = 900 ; Don't check for new files if local file is less than 900 seconds old.

;if keyword_set(local_data_dir) then  $
;   !istp.local_data_dir = local_data_dir

  If(file_test(!maven_spd.local_data_dir+'.master')) Then Begin ; Local directory IS the master directory
     !maven_spd.no_server = 1
  Endif

  !maven_spd.init = 1

  printdat, /values, !maven_spd, varname='!maven_spd'

  Return
End


