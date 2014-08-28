;+
;NAME:
; goes_read_config
;PURPOSE:
; Reads the goes_config file
;CALLING SEQUENCE:
; cstruct = goes_read_config()
;INPUT:
; none, the filename is hardcoded, 'goes_config.txt',and is s put in a
; folder given by the routine goes_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/themis/goes_config-4-linux
;OUTPUT:
; cstruct = a structure with the changeable fields of the !goes
;           structure
;HISTORY:
; 17-may-2007, jmm, jimm@ssl.berkeley.edu
; 2-jul-2007, jmm, 'Add trailing slash to data directories, if necessary
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-02-28 14:10:44 -0800 (Fri, 28 Feb 2014) $
;$LastChangedRevision: 14467 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/goesmag/goes_read_config_old.pro $
;-
Function goes_config_template_old

  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000, $
         DATASTART:3l, $
         DELIMITER:61b, $
         MISSINGVALUE:anan[0], $
         COMMENTSYMBOL:'', $
         FIELDCOUNT:2l, $
         FIELDTYPES:[7l, 7l], $
         FIELDNAMES:['FIELD1', 'FIELD2'], $
         FIELDLOCATIONS:[0l, 15l], $
         FIELDGROUPS:[0l, 1l]}

  Return, ppp
End
Function goes_read_config_old, header = hhh
  otp = -1
;First step is to get the filename
  dir = goes_config_filedir(/app_query)
  If(dir[0] Ne '') Then Begin
;Is there a trailing slash? Not for linux or windows, not sure about Mac
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Eq '/' Or ll Eq '\') Then filex = dir+'goes_config.txt' $
    Else filex = dir+'/'+'goes_config.txt'
;Does the file exist?
    If(file_search(filex) Ne '') Then Begin
      template = goes_config_template()
      fff = file_search(filex)
      strfx = read_ascii(filex, template = template, header = hhh)
      If(size(strfx, /type) Eq 8) Then Begin
        otp = create_struct(strtrim(strfx.field1[0], 2), $
                            strtrim(strfx.field2[0], 2), $
                            strtrim(strfx.field1[1], 2), $
                            strtrim(strfx.field2[1], 2))
        For j = 2, n_elements(strfx.field1)-1 Do $
          str_element, otp, strtrim(strfx.field1[j], 2), $
          fix(strfx.field2[j]), /add
      Endif
    Endif
  Endif; Else message, /info, 'NO APP_USER_DIR'
;check for slashes, add if necessary
  temp_string = strtrim(!goes.local_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
  !goes.local_data_dir = temporary(temp_string)
  temp_string = strtrim(!goes.remote_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
  !goes.remote_data_dir = temporary(temp_string)

  Return, otp
End


