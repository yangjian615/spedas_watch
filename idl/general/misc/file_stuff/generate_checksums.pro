;+
;Procedure generate_checksums
;Purpose: creates a checksum file
;Usage:
;Typical usage:
;    generate_checksums,directorypath,file_format='*.cdf',dir_format='*',/basename_only,/force
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
    verbose=verbose,tab=tab,current_dir=current_dir,force_regen=force_regen,basename_only=basename_only,include_directory=include_directory


if n_elements(recurse_limit) eq 0 then recurse_limit = 10
if recurse_limit lt 0 then message,'Exeeded recursion limit'

if n_elements(tab) eq 0 then tab=''
if n_elements(checksum_file) eq 0 then checksum_file='sum.sha1'

dprint,verbose=verbose,dlevel=3,tab+startpath

dirs=''
for i=0,n_elements(dir_format)-1 do begin
  append_array, dirs, file_search(startpath + dir_format[i] ) 
endfor

w = where( file_test(/directory,dirs), ndirs)
dirs = ndirs eq 0 ?  ''  :  dirs[w]
dprint,verbose=verbose,dlevel=3,tab+strtrim(ndirs,2)+' Directories match ["'+strjoin(dir_format,'", "')+'"]'


for i = 0,ndirs-1 do begin
  generate_checksums,dirs[i]+'/',file_format=file_format,dir_format=dir_format,recurse_limit=recurse_limit-1,checksum_file=checksum_file,tab=tab+'    ',$
     basename_only=basename_only,force_regen=force_regen,verbose=verbose,include_directory=include_directory
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


if nfiles ne 0  then begin
  sum_info = file_info(startpath+checksum_file)
  fi = file_info([files,startpath+'.'])    ; test of the modificaton time of directory is really the only test needed.
  last = max(fi.mtime)
  if sum_info.mtime lt last  || keyword_set(force_regen) then begin
    dprint,verbose=verbose,dlevel=2,tab+startpath+':  '+strtrim(nfiles,2)+' files match ["'+strjoin(file_format,'",  "')+'"]'
    checksum = file_checksum(files,verbose=verbose,relative_position=keyword_set(basename_only) ? strlen(startpath) : 0  )
    if size(/type,checksum_file) eq 7 then begin
      openw,unit,/get_lun,startpath+checksum_file
      for i=0,n_elements(checksum)-1 do printf,unit,checksum[i]
      free_lun,unit
    endif
  endif
end

end

