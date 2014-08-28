
;+
;Procedure:
;  spd_find_file
;
;Purpose:
;  Check for the existence of a file in the current path.
;
;Calling Sequence:
;  bool = spd_find_file(file_name)
;
;Input:
;  name: (string) Name of file including type appendix
;
;Output:
;  Return Value: (bool) true if file found, false if not
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-13 18:20:24 -0800 (Thu, 13 Feb 2014) $
;$LastChangedRevision: 14377 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_find_file.pro $
;
;-
function spd_find_file, name

    compile_opt idl2, hidden

  idl_path_dirs = strsplit(!path, path_sep(/search_path), /extract)

  file_path = file_search( idl_path_dirs + path_sep() + name )

  if file_path eq '' then begin
    return, 0b
  endif else begin
    return, 1b
  endelse

end