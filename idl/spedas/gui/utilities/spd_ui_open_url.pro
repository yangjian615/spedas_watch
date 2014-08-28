;+
;NAME:
; spd_ui_open_url
;
;PURPOSE:
; Open an url in the default web browser. On Windows and Mac this is easy. 
; On UNIX platforms, the script tries to find an appropriate browser.
; 
; In a future update we may use a configuration variable to store the browser in the preferences.
;
;CALLING SEQUENCE:
; spd_ui_open_url, url
;
;INPUT:
;    url : string, the full url, for example http://spedas.ssl.berkeley.edu
;
;$LastChangedBy: $
;$LastChangedDate:  $
;$LastChangedRevision: $
;$URL: $
;-

function get_linux_browser
  ;check browsers till we find one of them

  spawn, 'which firefox|grep ''not found''', browserstr
  if browserstr eq '' then return, "firefox"
  
  spawn, 'which google-chrome|grep ''not found''', browserstr
  if browserstr eq '' then return, "google-chrome"
  
  spawn, 'which opera|grep ''not found''', browserstr
  if browserstr eq '' then return, "opera"
 
  spawn, 'which epiphany|grep ''not found''', browserstr
  if browserstr eq '' then return, "epiphany"
  
  spawn, 'which konqueror|grep ''not found''', browserstr
  if browserstr eq '' then return, "konqueror"
  
  spawn, 'which xdg-open|grep ''not found''', browserstr
  if browserstr eq '' then return, "xdg-open"
  
  return, ""
end


pro spd_ui_open_url, url
  if !version.os_family eq 'Windows' then begin    ; Windows
    spawn, 'start ' + url, /hide, /nowait
  endif else begin
    if !version.os_name eq 'Mac OS X' then begin    ; MacOS
      spawn, 'open ' + url
    endif else begin  ; unix, linux
      browser_name = get_linux_browser()
      if browser_name ne '' then begin
        spawn, browser_name + ' ''' + url + ''''
      endif else begin
        print, 'Web browser not found. Cannot open ', url
      endelse
    endelse
  endelse
  
end
