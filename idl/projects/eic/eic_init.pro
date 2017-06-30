;+
;PROCEDURE:  eic_init
;PURPOSE:    Initializes system variables for eic.
;
;HISTORY
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-02-13 08:50:37 -0800 (Mon, 13 Feb 2017) $
;$LastChangedRevision: 22761 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/eic/eic_init.pro $
;-
pro eic_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

; need !cdf_leap_seconds to convert CDFs with TT2000 times
cdf_leap_second_init

defsysv,'!eic',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!eic',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !eic.init=0

if !eic.init ne 0 then return

!eic = file_retrieve(/structure_format)
;Read saved values from file
ftest = eic_read_config()
If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !eic.local_data_dir = ftest.local_data_dir
    !eic.remote_data_dir = ftest.remote_data_dir
    !eic.no_download = ftest.no_download
    !eic.no_update = ftest.no_update
    !eic.downloadonly = ftest.downloadonly
    !eic.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting eic to default configuration'
    endif else begin
      print,'No eic config found...creating default configuration'
    endelse

    !eic.local_data_dir = 'C:/data/eic/'
    !eic.remote_data_dir = 'http://vmo.igpp.ucla.edu/data1/SECS/'
endelse
;if file_test(!eic.local_data_dir+'eic/.master') then begin  ; Local directory IS the master directory
;   !eic.no_server=1    ;   
;   !eic.no_download=1  ; This line is superfluous
;endif

!eic.remote_data_dir = 'http://vmo.igpp.ucla.edu/data1/SECS/'

!eic.init = 1

printdat,/values,!eic,varname='!eic'

end

