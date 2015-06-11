;+
;Function:
;  spd_download
;
;
;Purpose:
;  Download one or more remote files and return their local paths.
;  This function can be used in place of file_retrieve.
;
;
;Calling Sequence:
;  
;    paths = spd_download( [remote_file=remote_file] | [,remote_path=remote_path]
;                          [,local_file=local_file]  [,local_path=local_path] ... )
;
;
;Example Usage:
;
;  Download file to current directory
;  ------------------------------------  
;    ;"file.dat" will be placed in current directory 
;    paths = spd_download( remote_file='http://www.example.com/file.dat' )
;  
;  Download file to specific location
;  ------------------------------------
;    ;remote file downloaded to "c:\data\file.dat"
;    paths = spd_download( remote_file='http://www.example.com/file.dat', $
;                          local_path='c:\data\')
;
;  Download multiple files to specified location and preserve remote file structure
;  -------------------------------------
;    ;remote files downloaded to "c:\data\folder1\file1.dat"
;    ;                           "c"\data\folder2\file2.dat"
;    paths = spd_download( remote_file = ['folder1/file1.dat','folder2/folder2.dat'], $
;                          remote_path = 'http://www.example.com/', $
;                          local_path = 'c:\data\')
;
; 
;Input:
;
;  Specifying File names
;  ---------------------
;    remote_file:  String or string array of URLs to remote files
;    remote_path:  String consisting of a common URL base for all remote files
;
;      -The full remote URL(s) will be:  remote_path + remote_file
;      -If no url scheme is recognized (e.g. 'http') then it is 
;       assumed that the url is a path to a local resource (e.g. /mount/data/)
;  
;    local_file:  String or string array of local destination file names
;    local_path:  String constisting of a common local path for all local files
;
;      -The final local path(s) will be:  local_path + local_file
;      -The final path(s) can be full or relative
;      -If local_file is not set then remote_file is used
;      -If remote_file is a full URL then only the file name is used
;
;      -Remote and local file names may contain wildcards:  *  ?  [  ]
;
;  Download Options
;  ---------------------
;    last_version:  Flag to only download the last in file in a lexically sorted 
;                   list when multiple matches are found using wildcards
;    no_update:  Flag to not overwrite existing file
;    force_download:  Flag to always overwrite existing file
;    no_download:  Flag to not download remote files
;
;    user_agent:  Specifies user agent reported to remote server. (string)
;
;    file_mode:  Bit mask specifying permissions for new files (see file_chmod)
;    dir_mode:  Bit mask specifying permissions for new directories (see file_chmod)
;
;  IDLnetURL Properties
;  ---------------------
;    All IDLnetURL properties may be specified as keywords to this routine.
;    See "IDLnetURL Properties" in the IDL documentation for more information.
;    Some examples are:
;    ------------------
;      url_query
;      url_username       
;      url_password
;      url_port
;      proxy_hostname
;      proxy_username
;      proxy_password
;
;  Other
;  ---------------------
;    progress_object:  Object reference for status updates
;
;  Backward Support
;  ---------------------
;    local_data_dir:  mapped to local_path
;    remote_data_dir:  mapped to remote_path
;    no_server:  mapped to no_download
;    no_clobber:  mapped to no_update    
;    valid_only:  only return paths to files that exist (ideally this would be default)
;
;
;Output:
;  return value:  String array specifying the full local path to all requested files
;
;
;Notes:
;  -unsupported file_retrieve keywords:
;     progress, preserve_mtime, progobj, ignore_filesize, 
;     ignore_filedate, archive_ext, archive_dir, min_age_limit
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-08 11:26:49 -0700 (Fri, 08 May 2015) $
;$LastChangedRevision: 17524 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_download/spd_download.pro $
;
;-

function spd_download, $

              remote_path = remote_path, $
              remote_file = remote_file, $

              local_path = local_path, $
              local_file = local_file, $

              progress_object = progress_object, $
              
              no_download = no_download, $
              no_update = no_update, $
              force_download = force_download, $
              user_agent = user_agent, $
              min_age_limit = min_age_limit, $
              last_version = last_version, $
 
              file_mode = file_mode, $
              dir_mode = dir_mode, $

              ;backward support
              local_data_dir = local_data_dir,  $
              remote_data_dir = remote_data_dir,  $
              no_server = no_server, $
              no_clobber = no_clobber, $    
              valid_only = valid_only, $



              _extra=_extra

    compile_opt idl2, hidden


; Defaults and backward compatibility
;---------------------------------------------

output = ''

if undefined(no_download) && ~undefined(no_server) then begin
  no_download = no_server
endif

if undefined(remote_path) && ~undefined(remote_data_dir) then begin
  remote_path = remote_data_dir
endif

if undefined(local_path) && ~undefined(local_data_dir) then begin
  local_path = local_data_dir
endif

if undefined(no_update) && ~undefined(no_clobber) then begin
  no_update = no_clobber
endif

if undefined(min_age_limit) then begin
  min_age_limit = 0
endif


; Existence checks and logic for combining remote and local file names
;---------------------------------------------------------------------

if undefined(remote_path) and undefined(remote_file) then begin
  return, output
endif

;ensure all necessary paths are defined
;local_file is checked later
if undefined(remote_path) then remote_path = ''
if undefined(remote_file) then remote_file = ''
if undefined(local_path) then local_path = ''

;remote path must by singular
if n_elements(remote_path) ne 1 then begin
  dprint, dlevel=1, 'Remote path must be singular'
  return, output
endif

;local path must be singular
if n_elements(local_path) ne 1 then begin
  dprint, dlevel=1, 'Local path must be singular'
  return, output
endif


;complete remote file path(s)
url = remote_path + remote_file


if array_equal(url,'') then begin
  dprint, dlevel=1, 'No remote file specified'
  return, output
endif

;if wildcards are used then contact the server(s) and expand list to include all matches
if ~keyword_set(no_download) then begin

  spd_download_expand, url, last_version=last_version
  
  if array_equal(url,'') then begin
    dprint, dlevel=1, 'No matching remote files found.'
    return, output
  endif

endif

;automatically use remote_file locally if local_file is not specified
if undefined(local_file) then begin
  ;if remote_file is the entire url then only use the filename
  if array_equal(remote_path,'') then begin
    ;this should catch the end of urls and windows file paths
    local_file = (stregex(url, '[/\]([^/\]+$)',/subexpr,/extract))[1,*]
  endif else begin
    local_file = (stregex(url, escape_string(remote_path)+'(.+$)',/fold_case,/subexp,/extract))[1,*]
  endelse
endif
  

;complete local file path(s)
filename = local_path + local_file


;there's no good way to continue if # of elements do not match
if n_elements(url) ne n_elements(filename) then begin
  dprint, dlevel=1, 'URL dimensions do not match local filename dimensions'
  return, output
endif


;initialize complete list of files for output (downloaded and/or found locally)
file_list = strarr(n_elements(filename))


; Loop over URLs to download 
;--------------------------------------------

if ~keyword_set(no_download) then begin

  for i=0, n_elements(url)-1 do begin

    ;if a url scheme is not recognized then assume the
    ;reference is to a local resource and copy
    if stregex(url[i], '^(http|ftp)s?://', /bool) then begin  

      file_tmp = spd_download_file( $
                         url = url[i], $
                         filename = filename[i], $
  
                         user_agent = user_agent, $
                         headers = headers, $
                         
                         no_update = no_update, $
                         force_download = force_download, $
                         min_age_limit = min_age_limit, $
                         
                         file_mode = file_mode, $
                         dir_mode = dir_mode, $
                         
                         progress_object = progress_object, $
                         
                         _extra=_extra )
    endif else begin

      file_tmp = spd_copy_file( $
                         source = url[i], $
                         destination = filename[i], $
                         
                         file_mode = file_mode, $
                         dir_mode = dir_mode, $
                         
                         force_copy = force_download, $
                         no_update = no_update )
      
    endelse

    if ~undefined(file_tmp) then begin
      file_list[i] = file_tmp
    endif
  
  endfor

endif



; Aggregate filenames
;--------------------------------------------

;if a file was not downloaded then check destination for pre-existing file
not_downloaded = where(file_list eq '', nnd)

if nnd ne 0 then begin

  for i=0, nnd-1 do begin

    ;this will catch any wild cards left behind if /no_download was set
    local_matches = file_search(filename[not_downloaded[i]], count=n_local)

    ;this is, hopefully, temporary support for an awful, backwards 
    ;feature of file_retrieve that returns imaginary paths to files
    ;that were not downloaded and do not exist on the file system
    if n_local eq 0 && ~keyword_set(valid_only) then begin
      file_list[not_downloaded[i]] = filename[not_downloaded[i]]
    endif

    ;use last in (lexically sorted) list if requested
    if keyword_set(last_version) then begin
      local_matches = local_matches[n_local-1 > 0]
    endif

    ;append matches for simplicity, empty strings will be trimmed later
    file_list = array_concat(local_matches,file_list)

  endfor

endif


;trim the list and copy to output variable
found = where(file_list ne '', nf)

if nf ne 0 then begin
  output = file_list[found]
endif

return, output

end