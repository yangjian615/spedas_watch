;+
;program: SPICE_INSTALL
;
;Purpose:  Installs SPICE dlm and binary
;
;
; Author: Davin Larson   
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
pro spice_install,no_download=no_download,force=force
   
   dlmdir = !dlm_path
   help,/dlm,'icy'
   if spice_test() then begin
      dprint,'SPICE/ICY already installed in '+dlmdir
      if ~keyword_set(force) then return
   endif else begin
      dprint,'Attempting to install SPICE/ICY'
   endelse
   OS = file_basename(dlmdir)
   serverdir = 'http://sprg.ssl.berkeley.edu/data/misc/spice/lib/'+OS+'/'
;  localdir  = 'temp/spicelibtest/'
   localdir = dlmdir+'/'
   if file_test(localdir,/write,/direc) ne 1 then message,dlmdir+' is write protected'
;   localdir =''
   modules='icy.*'
   file_http_copy,modules,serverdir=serverdir,localdir=localdir,url_info=ui,archive_ext='.arc',/preserve_mtime,no_download=no_download,force_download=force,verbose=3
;printdat,ui   
   if n_elements(ui) eq 1 && ui.localname eq '' then begin
      dprint,'Sorry. No icy library found for your system.'
   endif else begin
      dprint, 'Found: ',ui.localname
   endelse
   
   
   


end
