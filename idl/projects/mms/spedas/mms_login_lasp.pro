;+
; PROCEDURE:
;         mms_login_lasp
;
; PURPOSE:
;         Authenticates the user with the SDC at LASP; if no keywords are provided, 
;             the user is prompted for their MMS user/password, and that is saved
;             locally in a sav file
;
; KEYWORDS:
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-23 09:55:18 -0700 (Thu, 23 Jul 2015) $
;$LastChangedRevision: 18218 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_login_lasp.pro $
;-

function mms_login_lasp, login_info = login_info
    ; halt and warn the user if they're using IDL before 7.1 due to SSL/TLS issue
    if double(!version.release) lt 7.1d then begin
        dprint, dlevel = 0, 'Error, IDL 7.1 or later is required to use mms_load_data.'
        return, -1
    endif

    ; restore the login info
    if undefined(login_info) then login_info = 'mms_auth_vassilis.sav'

    ; check that the auth file exists before trying to restore it
    file_exists = file_test(login_info, /regular)

    if file_exists eq 1 then begin
        restore, login_info
    endif else begin
        ; prompt the user for their SDC username/password
        login_info_widget = login_widget(title='MMS SDC Login')

        if is_struct(login_info_widget) then begin
            auth_info = {user: login_info_widget.username, password: login_info_widget.password}

            ; now save the user/pass to a sav file to remember it in future sessions
            save, auth_info, filename = login_info
        endif
    endelse

    if is_struct(auth_info) then begin
        username = auth_info.user
        password = auth_info.password
    endif else begin
        ; need to login to access the web services API
        dprint, dlevel = 0, 'Error, need to provide login information to access the web services API via the login_info keyword'
        return, -1
    endelse

    ; the IDLnetURL object returned here is also stored in the common block
    ; (this is why we never use net_object after this line, but this call is still
    ; necessary to login)
    net_object = get_mms_sitl_connection(username=username, password=password)
    return, 1
end