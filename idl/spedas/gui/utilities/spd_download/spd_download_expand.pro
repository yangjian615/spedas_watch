;+
;Procedure:
;  spd_download_expand
;
;Purpose:
;  Check remote host for requested files and apply wildcards
;  by downloading and parsing remote index file.
;
;Calling Sequence:
;  spd_download_extract, url, last_version=last_version
;
;Input:
;  url:  String array of URLs to remote files.
;  last_version:  Flag to only use the last file in a lexically sorted list 
;                 when wildcards result in multiple matches. 
;
;Output:
;  url:  String array of matching remote files or emptry string if no matches are found.
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-27 11:22:51 -0700 (Mon, 27 Apr 2015) $
;$LastChangedRevision: 17432 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_download/spd_download_expand.pro $
;
;-

pro spd_download_expand, url, last_version=last_version

    compile_opt idl2, hidden


;no need to query if there are no wildcards
if total( stregex(url, '[]*?[]',/bool) ) eq 0 then return

;split URLs into base and filename
url_base = (stregex(url, '(^.*/)[^/]*$',/subexpr,/extract))[1,*]
filenames = (stregex(url, '/([^/]*$)',/subexpr,/extract))[1,*]

;get and loop over unique bases
unique_bases = url_base[uniq(url_base, sort(url_base))]

for i=0, n_elements(unique_bases)-1 do begin

  ;download index file for current base
  current = spd_download_file(url=unique_bases[i], /string_array)
  
  ;extract URLs from index file
  links = spd_download_extract(current,/relative,/normal,no_parent=unique_bases[i])

  ;perform searches for this base   
  base_idx = where(url_base eq unique_bases[i], n_bases) 

  for k=0, n_bases-1 do begin

    matches = where( strmatch(links, filenames[base_idx[k]], /fold_case), n_matches)

    if n_matches eq 0 then continue

    ;use last in (lexically sorted) list if requested
    if keyword_set(last_version) then begin
      matches = matches[ (sort(links[matches]))[n_matches-1] ]
    endif

    ;aggregate all matches
    all_matches = array_concat( unique_bases[i] + links[matches], all_matches)

  endfor

endfor

;return array with all matches from the server(s)
if undefined(all_matches) then begin
  url = ''
endif else begin
  url = all_matches
endelse


end