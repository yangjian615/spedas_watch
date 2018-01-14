;+
;
;;+
; PROCEDURE:
;         tplot2ap
;
; PURPOSE:
;         Send tplot variables to Autoplot
;         
; INPUT:
;         tvars:  string or array of tplot variables to send to Autoplot
;         
; KEYWORDS:
;         port: Autoplot server port (default: 12345)
;         connect_timeout: connection timeout time in seconds (default: 6s)
;         read_timeout: read timeout time in seconds (default: 30s)
;
; EXAMPLE:
;         IDL> tplot2ap, 'tplot_variable'
;         
; NOTES:
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;         
;         This routine sends the tplot data to Autoplot via a CDF file stored in your 
;         IDL working directory (so this creates a 'temporary' file every time you
;         send data to Autoplot)
;
;         On Windows, you'll have to allow Autoplot / SPEDAS to have access to the 
;         local network via the Firewall (it should prompt automatically, simply 
;         click 'Allow' for private networks)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-01-13 13:18:45 -0800 (Sat, 13 Jan 2018) $
; $LastChangedRevision: 24517 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/tplot2ap/tplot2ap.pro $
;-

pro tplot2ap, tvars, port=port, connect_timeout=connect_timeout, read_timeout=read_timeout
  if undefined(port) then port = 12345
  if undefined(connect_timeout) then connect_timeout = 6 ; seconds
  if undefined(read_timeout) then read_timeout = 30 ; seconds
  if undefined(tvars) then begin
    dprint, dlevel=0, 'Error - no tplot variables specified'
    dprint, dlevel=0, 'Syntax: tplot2ap, ["variable"]'
    return
  endif

  cdf_filename = 'test' + strcompress(string(randomu(seed, 1, /long)), /rem)
  tplot2cdf2, filename=cdf_filename, tvars=tvars, /default 
  
  socket, unit, '127.0.0.1', port, /get_lun, error=error, read_timeout=read_timeout, connect_timeout=connect_timeout
  
  if error ne 0 then begin
    dprint, dlevel=0, 'Error - problem connecting to Autoplot'
    dprint, dlevel=0, 'Ensure the server feature is enabled'
    return
  endif
  
  cd,c=current_working_dir
  
  for tvar_idx=0, n_elements(tvars)-1 do begin
    printf, unit, 'plot('+strcompress(string(tvar_idx), /rem)+', "'+current_working_dir+'/'+cdf_filename+'.cdf?'+tvars[tvar_idx]+'");'

  endfor

  ; pause required on Windows before freeing the handle, otherwise the previous plot() command fails
  wait, 1
  free_lun, unit
end