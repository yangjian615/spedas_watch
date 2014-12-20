;+
;function FILE_CHECKSUM
;Purpose: Returns: SHA1 CHECKSUM string for a file 
;Usage:
;    output = file_checksum( filename, [/add_mtime] )
;Typical usage:
;    file_hash( file_search('*') ,/add_mtime )  ;
; Origin:  Mostly copied from file_touch
; Limitations:
;    Currently works only on Linux and MacOs systems by calling the shasum command in a shell.
;    This module is under development.
; Author: Davin Larson (davin@ssl.berkeley.edu)  copyright - March 2014
; Changes:
;    December 2014 - Name changed from file_hash to file_checksum because is better reflects its true purpose
; License:
;   All users are granted permission to use this unaltered code.
;   It may NOT be modified without the consent of the author. However the author welcomes input for bug fixes or upgrades.
;-
function file_checksum,files,method=method,add_mtime=add_mtime,mtime_format=mtime_format,verbose=verbose,executable=executable;,cd_to=cd_to
common file_hash_com2, hash_init,hash_version,hash_executable,hash_error

if ~keyword_set(hash_init)   then begin
    hash_executable = 'shasum'
    spawn,hash_executable+' --version',hash_version,hash_error
    hash_init = 4
    if keyword_set(hash_error) then begin
      dprint,dlevel=0,verbose=verbose,'checksum executable: '+hash_executable+' Error:',hash_error
      wait,3
    endif else  dprint,dlevel=2,'Using shell executable: '+hash_executable+' Version: ',hash_version[0]
endif

if size(/type,files) ne 7 then begin
    dprint,verbose=verbose,'filename required.'
    return,''
endif

commands = hash_executable
;if keyword_set(cd_to) then spawn,'cd '+cd_to
   
outputs = ''
for i=0,n_elements(files)-1 do begin
file = files[i]
if file_test(/regular,file) eq 0 then begin 
   output = 'FileDoesNotExist                          '+file
endif else if keyword_set(hash_error) then output ='ChecksumExecutableNotAvailable            '+ file else begin
  if !version.os_family eq 'unix' then begin
    dprint,verbose=verbose,dlevel=4,commands
    spawn,[commands,file] ,/noshell,/stderr,output,exit_status=status
  endif else if !version.os_family eq 'Windows' then begin
    dprint,verbose=verbose,dlevel=3,'Not tested on Windows OS yet - feel free to fix this!'      
    filestring = '"' + file + '"'
    command = strjoin([commands,filestring],' ')
    dprint,verbose=verbose,dlevel=4,command
    spawn,command ,/noshell,/stderr, /hide,output ,exit_status=status
  endif
endelse
output =output[0]
if keyword_set(mtime_format) or keyword_set(add_mtime) then begin
   stat = file_info(file)
   output = time_string(stat.mtime,tformat=mtime_format)+string(stat.size,format='(i12)')+' '+output
endif
if keyword_set(output) then dprint,dlevel=3,verbose=verbose,output
append_array,outputs,output
endfor

if n_elements(files) eq 1 then outputs=outputs[0]

return,outputs
end

