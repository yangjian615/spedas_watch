;+
;Function:
;  spd_download_file
;
;
;Purpose:
;  Primarily a helper function for spd_download.  This function will download
;  a single file and return the path to that file.  If a local file exists it 
;  will only download if the remote file is newer.
;
;
;Calling Sequence:
;  path = spd_download_file(url=url, [,filename=filename] ... )
;
;
;Input:
;  url:  URL to remote file. (string)
;  filename:  Specifies local file path and name.  If a full path is not 
;             provided it will assumes a relative path. (string)
;  
;  user_agent:  Specifies user agent reported to remote server. (string)
;  headers:  Array of HTML headers to be sent to remote server.  
;              -"User-Agent" is added by default
;              -"If-Modified-Since" is added if file age is checked
;  
;  no_update:  Flag to not overwrite existing file 
;  force_download:  Flag to always overwrite existing file
;  string_array:  Flag to download remote file and load into memory as an
;                 array of strings.
;  
;  min_age_limit:  Files younger than this (in seconds) are assumed current
;  
;  file_mode:  Bit mask specifying permissions for new files (see file_chmod)
;  dir_mode:  Bit mask specifying permissions for new directories (see file_chmod)
;  
;  progress_object:  Status update object
;
;  _extra:  Any idlneturl property (except callback_*) can be passed via _extra
;           
;
;
;Output:
;  return value:
;    local file path (string) - if a file is downloaded or a local file is found
;    empty string (string) - if no file is found
;    file contents (string array)  - if /string_array is set
;
;
;Notes:
;  -precedence of boolean keywords:
;     string_array > force_download > no_update > default behavior
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-18 16:27:58 -0800 (Wed, 18 Feb 2015) $
;$LastChangedRevision: 17004 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_download/spd_download_file.pro $
;
;-

function spd_download_file, $

                  url = url_in, $
                  filename = filename_in, $

                  user_agent = user_agent, $
                  headers = headers, $
                  
                  no_update = no_update, $
                  force_download = force_download, $
                  min_age_limit = min_age_limit, $
                  
                  file_mode = file_mode, $
                  dir_mode = dir_mode, $
                  
                  progress_object = progress_object, $
                  
                  string_array = string_array, $
                  
                  _extra = _extra


    compile_opt idl2, hidden


output = ''

if undefined(url_in) || ~is_string(url_in) then begin
  dprint, dlevel=1, 'No URL supplied'
  return, output
endif

if n_elements(url_in) gt 1 or n_elements(filename_in) gt 1 then begin
  dprint, dlevel=1, 'Single file downloads only, use SPD_DOWNLOAD for multiple files'
  return, output
endif

;if file name is empty or not defined then attempt to pull file name from url
if ~keyword_set(filename_in) then begin
  ;allow empty string output for remote index downloads
  filename_in = (stregex(url_in, '/([^/]*$)',/subexpr,/extract))[1]
endif

if ~is_string(filename_in,/blank) then begin
  dprint, dlevel=1, 'Invalid local file name'
  return, output
endif

;this must be defined later
if undefined(progress_object) then begin
  progress_object = obj_new()
endif

url = url_in
filename = filename_in

local_info = file_info(filename)



; Initialize idlneturl object
;----------------------------------------
net_object = obj_new('idlneturl')



; Form custom header
;----------------------------------------

;user agent is required sometimes
if keyword_set(user_agent) then begin
  headers = array_concat('User-Agent: '+user_agent)
endif else begin
  headers = array_concat('User-Agent: '+'IDL/'+!version.release+' ('+!version.os+' '+!version.arch+')', headers)
endelse

;The file will automatically be overwritten if server is not querried for 
;its modification time.  If no_update is set and a file is found then there 
;is nothing left to do.  If downloading to string array then no checks are needed 
if ~keyword_set(string_array) && ~keyword_set(force_download) && local_info.exists then begin

  if keyword_set(no_update) then begin
    dprint, dlevel=2, 'Found existing file: '+filename
    return, filename
  endif

  reference_time = time_string(local_info.mtime,tformat='DOW, DD MTH YYYY hh:mm:ss GMT')
  headers = array_concat('If-Modified-Since: '+reference_time,headers)

endif



; Set neturl object properties
;  -if "url" keyword is passed to get() then all "url_*" properties are ignored,
;   set them manually here to avoid that
;  -any keywords passed through _extra will take precedent
;----------------------------------------

;flag to tell if there was an exception thrown in the idlneturl callback function
callback_error = ptr_new(0b)

url_struct = parse_url(url)

net_object->setproperty, $
            
            headers=headers, $
            
            url_scheme=url_struct.scheme, $
            url_host=url_struct.host, $
            url_path=url_struct.path, $
            url_query=url_struct.query, $
            url_port=url_struct.port, $
            url_username=url_struct.username, $
            url_password=url_struct.password, $
            
            timeout=timeout, $
            
            _extra=_extra

;keep core properties from being overwritten by _extra
net_object->setproperty, $
            callback_function='spd_download_callback', $
            callback_data={ $
                           net_object: net_object, $
                           msg_time: ptr_new(systime(/sec)), $
                           msg_data: ptr_new(0ul), $
                           progress_object: progress_object, $
                           error: callback_error $
                           }


; Download
;  -an unsuccessful get will throw an exception and halt execution, 
;   the catch should allow these to be handled gracefully
;----------------------------------------

dprint, dlevel=2, 'Downloading: '+url

;manually create any new directories so that permissions can be set
if ~keyword_set(string_array) then begin
  spd_download_mkdir, file_dirname(filename), dir_mode
endif

catch, error
if error eq 0 then begin

  ;get the file
  filepath = net_object->get(filename=filename,string_array=string_array)
  
  if ~keyword_set(string_array) then begin
    
    dprint, dlevel=2, 'Download complete:  '+filepath
    
    ;set permissions for downloaded file
    if ~undefined(file_mode) then begin
      file_chmod, filepath, file_mode
    endif

  endif

  output = filepath

endif else begin
  catch, /cancel

  ;handle exceptions from idlneturl
  spd_download_handler, net_object=net_object, $
                        url=url, $
                        filename=filename, $
                        callback_error=*callback_error

endelse

obj_destroy, net_object

return, output

end