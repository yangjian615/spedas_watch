;+
; NAME:
;   FILE_ARCHIVE
; PURPOSE:
;   Archives files by renaming them and optionally moving them to another directory.
; CALLING SEQUENCE:
;   FILE_ARCHIVE,'old_file',archive_ext = '.arc'
; KEYWORDS:
;   ARCHIVE_EXT = '.arc'
;   ARCHIVE_DIR = 'archive_dir/'  ; name of subdirectory to move files into.
;   VERBOSE
;   DLEVEL
;   MAX_ARCS = n  ; max number of archives to produce
; Author:
;   Davin Larson  June 2013   
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-03-20 08:39:42 -0700 (Thu, 20 Mar 2014) $
; $LastChangedRevision: 14613 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_archive.pro $
;-
 

pro file_archive,filename,archive_ext=archive_ext,archive_dir=archive_dir,verbose=verbose,dlevel=dlevel  ,max_arcs=max_arcs
  if size(/type,archive_ext) ne 7 then return
  if not keyword_set(archive_ext) then return
  dl = n_elements(dlevel) ? dlevel : 3
  if not keyword_set(max_arcs) then max_arcs = 99
  
for i = 0L,n_elements(filename)-1 do begin
  fi = file_info(filename[i])
  if fi.exists eq 0 then break   ; no file to archive
  dir = file_dirname(fi.name)+'/'
  bname = file_basename(fi.name)
  arc_format = dir+( keyword_set(archive_dir) ? archive_dir : '')+bname+archive_ext
;  arc_format = fi.name+archive_ext
  arc_names = file_search(arc_format+'*',count=n_arc)
  if n_arc ne 0 then begin
     arc_nums = fix( strmid(arc_names,strlen(arc_format) ) )
     n_arc = max(arc_nums) + 1
     dprint,verbose=verbose,dlevel=dl,'Consider deleting '+strtrim(n_arc,2)+" archived files: '"+arc_format+"*'"
  endif
  arc_name = arc_format+strtrim(n_arc < max_arcs,2)
  dprint,verbose=verbose,dlevel=dl,'Archiving old file: '+fi.name+' renamed to '+arc_name
;  file_delete,arc_name,/allow_nonexistent    ;   delete archive if it exists
  if keyword_set(archive_dir) then file_mkdir2,dir+archive_dir,mode='777'o
  file_move,fi.name,arc_name               ;   rename old file
endfor

end



