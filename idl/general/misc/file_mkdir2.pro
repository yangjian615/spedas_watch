;+
;PROCEDURE  FILE_MKDIR2, dir
;PURPOSE:  Wrapper for FILE_MKDIR that also sets the mode for each newly created directory.
;   dir must be a scalar.
;D. Larson, April, 2008
;
pro file_mkdir2,dir,_extra=ex,mode=mode,writeable=writeable $
    ,dlevel=dlevel,verbose=verbose

fi = file_info(dir)
writeable = fi.write
if fi.directory then  return
if (~fi.directory and fi.exists) then begin ;if it is an existing file, return
  dprint, 'File exists but it is not a directory: ',  dir, dlevel=dlevel,verbose=verbose
  writable=0
  return
endif
parent_dir = file_dirname(dir)
;dprint,parent_dir
if parent_dir ne dir then file_mkdir2,parent_dir,mode=mode,writeable=writeable   ; else message,'Unable to determine parent directory!'
if writeable then begin
  dprint,'Creating new directory: ',dir,dlevel=dlevel,verbose=verbose
  file_mkdir,dir
  if keyword_set(mode) then file_chmod,dir,mode
  writeable = 1b
endif else dprint,dlevel=dlevel,verbose=verbose,'Unable to create Directory: ',dir
return

end

