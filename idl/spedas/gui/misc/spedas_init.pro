;+
;PROCEDURE:  spedas_init
;PURPOSE:    Initializes system variables for spedas data.  Can be called from idl_startup to set
;            custom locations.
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2013-10-26 12:08:47 -0700 (Sat, 26 Oct 2013) $
;$LastChangedRevision: 13403 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/api_examples/file_configuration_tab/spedas_init.pro $
;-
pro spedas_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, use_spdf = use_spdf, no_color_setup

defsysv,'!spedas',exists=exists
if not keyword_set(exists) then begin
   ;defsysv,'!spedas',  file_retrieve(/structure_format)
   tmp_struct=file_retrieve(/structure_format)
   str_element,tmp_struct,'browser_exe','',/add 
   str_element,tmp_struct,'temp_dir','',/add 
   defsysv,'!spedas',tmp_struct
endif

if keyword_set(reset) then !spedas.init=0

if !spedas.init ne 0 then return

tmp_struct = file_retrieve(/structure_format)     
str_element,tmp_struct,'browser_exe','',/add  
str_element,tmp_struct,'temp_dir','',/add 
!spedas=tmp_struct
  
;Read saved values from file
;ftest = yyy_read_config()

If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !spedas.local_data_dir = ftest.local_data_dir
    !spedas.remote_data_dir = ftest.remote_data_dir
    !spedas.no_download = ftest.no_download
    !spedas.no_update = ftest.no_update
    !spedas.downloadonly = ftest.downloadonly
    !spedas.verbose = ftest.verbose
    !spedas.browser_exe = ''
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting spedas to default configuration'
    endif else begin
      print,'No spedas config found...creating default configuration'
    endelse
    !spedas.local_data_dir = root_data_dir()
    !spedas.remote_data_dir = ''
    !spedas.browser_exe = ''
endelse

if file_test(!spedas.local_data_dir+'spedas/.master') then !spedas.no_download=1  ; Local directory IS the master directory

;libs,'spedas_config',routine=name
;if keyword_set(name) then call_procedure,name

!spedas.init = 1

printdat,/values,!spedas,varname='!spedas


end
