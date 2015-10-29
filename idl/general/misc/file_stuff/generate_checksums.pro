;+
;Procedure generate_checksums
;Purpose: recursively creates checksum files in subdirectories.
;    These files are produced using the "shasum" program. The same program can be used to check file integrity
;    Files are not regenerated if the chksum file is newer than all of its dependents.
;Usage:
;Typical usage:
;    generate_checksums,directorypath,file_format='*.cdf'  
;    input:  directorypath - scaler string  filepath (must end with '/')
;    
;    FILE_FORMAT :  string(s)   file format string(s) use for search
;    DIR_FORMAT :  string(s)   directory format to be searched  recursively
;    
;    RECURSE_LIMIT :  default is 10.  Set to 0 to create a single checksum file containing all files found. 
;    
;    FORCE_REGEN : Set this keyword to force regeneration of all checksums
;    INCLUDE_DIRECTORY : Set this keyword to compute the checksum of the checksum files in subdirectories.
;    FULL_PATH : set this keyword to include the full path in the checksum file.
;    
;    VERBOSE:  set verbosity level
;    
;    
;    
;
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


pro generate_checksums,startpath,file_format=file_format,dir_format=dir_format,recurse_limit=recurse_limit,checksum_file=checksum_file, $
    verbose=verbose,tab=tab,force_regen=force_regen,full_path=full_path,include_directory=include_directory


default_name = 'chksum.sha1'

if n_elements(recurse_limit) eq 0 then begin
  recurse_limit = 10
  if n_elements(checksum_file) eq 0 then checksum_file=default_name
endif 

if size(/type,file_format) ne 7 then file_format = '*'
if n_elements(tab) eq 0 then tab=''

if recurse_limit eq 0  then begin
  if n_elements(checksum_file) eq 0 then checksum_file='all_'+default_name
  if keyword_set(tab) then dprint,dlevel=1,verbose=verbose,'Exeeded recursion limit. Use the RECURSE_LIMIT keyword to increase it.'
  for i=0,n_elements(file_format)-1 do    append_array,  files , file_search(startpath,file_format[i])
  w = where(files ne '',nfiles)
  files= (nfiles eq 0)  ?  '' : files[w]
  
endif else begin
  if n_elements(checksum_file) eq 0 then checksum_file=default_name

  dprint,verbose=verbose,dlevel=3,tab+startpath

  dirs=''
  for i=0,n_elements(dir_format)-1 do begin
    append_array, dirs, file_search(startpath + dir_format[i] )
  endfor

  w = where( file_test(/directory,dirs), ndirs)
  dirs = (ndirs eq 0) ?  ''  :  dirs[w]
  dprint,verbose=verbose,dlevel=3,tab+strtrim(ndirs,2)+' Directories match ["'+strjoin(dir_format,'", "')+'"]'

  for i = 0,ndirs-1 do begin
    generate_checksums,dirs[i]+'/',file_format=file_format,dir_format=dir_format,recurse_limit=recurse_limit-1,checksum_file=checksum_file,tab=tab+'    ',$
        full_path=full_path,force_regen=force_regen,verbose=verbose,include_directory=include_directory
  endfor

  files=''
  if keyword_set(include_directory) then for i=0,n_elements(dir_format)-1  do begin
    append_array, files, file_search(startpath+dir_format[i]+'/'+checksum_file)
  endfor

  for i=0,n_elements(file_format)-1 do begin
    append_array, files, file_search(startpath+file_format[i])
  endfor

  w = where( file_test(/regular, files)  and (files ne startpath+checksum_file), nfiles )
  files = nfiles eq 0 ?  ''  : files[w]

endelse


if nfiles ne 0  then begin
  sum_info = file_info(startpath+checksum_file)
;  fi = file_info([files,startpath+'.'])    ; test of the modificaton time of directory is really the only test needed.
  fi = file_info(files)    
  last = max([fi.mtime,fi.ctime])
  if sum_info.mtime lt last  || keyword_set(force_regen) then begin
    dprint,verbose=verbose,dlevel=2,tab+startpath+':  '+strtrim(nfiles,2)+' files match ["'+strjoin(file_format,'",  "')+'"]'
    checksum = file_checksum(files,verbose=verbose,relative_position = keyword_set(full_path) ? 0 : strlen(startpath)  )
    if size(/type,checksum_file) eq 7 then begin
      openw,unit,/get_lun,startpath+checksum_file
      for i=0,n_elements(checksum)-1 do printf,unit,checksum[i]
      free_lun,unit
    endif
  endif
end

end

