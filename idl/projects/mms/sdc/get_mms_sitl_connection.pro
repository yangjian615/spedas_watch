; Get an IDLnetUrl object with login credentials.
; The user should only be prompted once per IDL session to login.
; Use common block to manage a singleton instance of a IDLnetURL
; so it will remain alive in the IDL session unless it has expired.
function get_mms_sitl_connection, host=host, port=port, authentication=authentication, $
  group_leader=group_leader, username=username, password=password
  common mms_sitl_connection, netUrl, connection_time, login_source
  
  ; Define the length of time the login will remain valid, in seconds.
  expire_duration = 86400 ;24 hours
  
  ; Test if login has expired. If so, destroy the IDLnetURL object and replace it with -1
  ; so the login will be triggered below.
  if (n_elements(connection_time) eq 1) then begin
    duration = systime(/seconds) - connection_time
    if (duration gt expire_duration) then mms_sitl_logout
  endif
  
  if n_elements(host) eq 0 then host = "lasp.colorado.edu"  ;"sdc-web1"  ;"dmz-shib1"
  if n_elements(port) eq 0 then port = 80
  if n_elements(authentication) eq 0 then authentication = 1 ;basic
  
  ;Make sure the singleton instance has been created
  ;TODO: consider error cases, avoid leaving incomplete netURL in common block
  type = size(netUrl, /type) ;will be 11 if object has been created
  if (type ne 11) then begin
    ; Construct the IDLnetURL object and set the login properties.
    netUrl = OBJ_NEW('IDLnetUrl')
    netUrl->SetProperty, URL_HOST = host
    netUrl->SetProperty, URL_PORT = port
    
    ;If authentication is requested, get login from user and add to netURL properties
    if authentication gt 0 then begin
      ;If we have a failed or expired login, make sure we use the gui if we did last time
      if (n_elements(login_source) eq 1) then group_leader = login_source
      
      ;If the caller requested the gui login option, save that in the common block
      ;so we can use the same login mechanism if the login fails or expires.
      if n_elements(group_leader) eq 1 then login_source = group_leader
      
      if n_elements(username) eq 0 or n_elements(password) eq 0 then begin
        ;Get the login credentials
        login = mms_sitl_login(group_leader=group_leader)
        username = login.username
        password = login.password
      endif

      netUrl->SetProperty, URL_SCHEME = 'https'
      netUrl->SetProperty, SSL_VERIFY_HOST = 0 ;don't worry about certificate
      netUrl->SetProperty, SSL_VERIFY_PEER = 0
      netUrl->SetProperty, AUTHENTICATION = authentication
      ;1: basic only, 2: digest
      netUrl->SetProperty, URL_USERNAME = username
      netUrl->SetProperty, URL_PASSWORD = password
      
;      ;Try up to 3 times to authenticate the login.
;      ;Need limit since automated tests will keep trying same login.
;      ;TODO: skip if gui user selects cancel
;      for try = 1, 3 do begin
;        if authenticate() break  $ ;worked
;        else begin
;          mms_sitl_logout ;clear the common block
;          c = get_mms_sitl_connection(host=host, port=port, authentication=authentication, gui=gui)
;     ;TODO: recursive, loop of 3 tries won't help?
;        endelse
;      endfor
      
    endif
    
    ; Set the time of the login so we can make it expire.
    connection_time = systime(/seconds)
  endif

  ; check that the connection is valid
  status = validate_mms_sitl_connection(netUrl)
  if status ne 0 then begin
    return, status
  endif
  
  ;TODO: if parameters are set and netURL already exists, reset properties

  return, netUrl
end


