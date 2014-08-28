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

;pro spice_install
   dlmdir = !dlm_path
   no_download=0
   OS = file_basename(dlmdir)
   serverdir = 'http://sprg.ssl.berkeley.edu/data/misc/spice/lib/'+OS+'/'
   localdir  = 'temp/spicelibtest/'
   localdir = dlmdir+'/'
;   localdir =''
   modules='icy.*'
 ; modules='test.*'
   file_http_copy,modules,serverdir=serverdir,localdir=localdir,url_info=ui,archive_ext='.arc',/preserve_mtime,no_download=no_download
;printdat,ui   
   if n_elements(ui) eq 1 && ui.localname eq '' then begin
      dprint,'Sorry. No icy library found for your system.'
   endif else begin
      dprint, 'Found: ',ui.localname
   endelse
   
   
   


end
