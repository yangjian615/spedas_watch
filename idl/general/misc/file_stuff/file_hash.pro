;+
;function FILE_HASH
;Purpose: Returns: SHA1 hash string for a file 
;Usage:
;    output = file_hash( filename, [/add_mtime] )
;Typical usage:
;    file_hash( file_search('*') ,/add_mtime )  ;
; Origin:  Mostly copied from file_touch
; Limitations:
;    Currently works only on Linux and MacOs systems by calling the shasum command in a shell.
;    This module is under development.
; Author: Davin Larson (davin@ssl.berkeley.edu)  copyright - March 2014
; License:
;   All users are granted permission to use this unaltered code.
;   It may NOT be modified without the consent of the author. However the author welcomes input for bug fixes or upgrades.
;-
function file_hash,files,method=method,add_mtime=add_mtime,mtime_format=mtime_format
common file_hash_com2, hash_init,hash_version,hash_executable,hash_error

if ~keyword_set(hash_init)  then begin
    hash_executable = 'shasum'
    spawn,hash_executable+' --version',hash_version,hash_error
    hash_init = 4
    if keyword_set(hash_error) then begin
      dprint,dlevel=0,'HASH executable: '+hash_executable+' Error:',hash_error
      wait,3
    endif else  dprint,dlevel=2,'Using shell executable: '+hash_executable+' Version: ',hash_version[0]
endif

if size(/type,files) ne 7 then begin
    dprint,verbose=verbose,'filename required.'
    return,''
endif

commands = hash_executable
   
for i=0,n_elements(files)-1 do begin
file = files[i]
if keyword_set(hash_error) then output ='HashNotAvailable  '+ file else begin
  if !version.os_family eq 'unix' then begin
    dprint,verbose=verbose,dlevel=4,commands
    spawn,[commands,file] ,/noshell,/stderr,output,exit_status=status
  endif else if !version.os_family eq 'Windows' then begin
    dprint,dlevel=3,'Not tested on Windows OS yet - feel free to fix this!'      
    filestring = '"' + file + '"'
    command = strjoin([commands,filestring],' ')
    dprint,verbose=verbose,dlevel=4,command
    spawn,command ,/noshell,/stderr, /hide,output ,exit_status=status
  endif
endelse
output =output[0]
if keyword_set(mtime_format) or keyword_set(add_mtime) then begin
   stat = file_info(file)
   output = time_string(stat.mtime,tformat=mtime_format)+'  '+output
endif
if keyword_set(output) then dprint,dlevel=3,verbose=verbose,output
append_array,outputs,output
endfor

return,outputs
end

