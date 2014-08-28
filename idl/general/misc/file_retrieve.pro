;+
; FUNCTION: FILE_RETRIEVE
; Purpose:
;  FILE_RETRIEVE will download files from a remote web server and copy them into a local (cache) directory 
;  maintaining the directory structure. It returns the list of local file names. 
;  By default files are only downloaded if the remote file is more recent or of different size. 
;  
;Usage:
; files = file_retrieve(pathnames,local_data_dir=local_data_dir,remote_data_dir=remote_data_dir)
;
;Suggested usage:
;  source = file_retrieve(/struct)
;  source.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/' 
;  ;   Set other options on source as needed
;  
;  pathname = 'relativedir1/dir2/filename.ext'
;  files = file_retrieve(pathname,_extra=source)
;
;Arguments:
;    pathnames: String or string array with partial path to the remote file. 
;               (will be appended to remote_data_dir)
;    [newpathnames]: (optional) String or string array with partial path to file destination.
;                   (Will be appended to local_data_dir)
;
;Keywords:
;    local_data_dir:  String or string array w/ local data directory(s)
;                     If newpathnames is set it will be appended to this variable; if not, 
;                     pathnames will be appended. 
;    remote_data_dir:  String or string array w/ remote data directory(s)
;                      Pathnames will be appended to this variable.
;    
;   PRESERVE_MTIME(optional):  Uses the serve modification time instead of local modification time.  This keyword is ignored
;        on windows machines that don't have touch installed. (No cygwin or GNU utils)
;History: 
;    2012-6-25:  local_data_dir and remote_data_dir accept array inputs 
;                with the same # of elements as pathnames/newpathnames
;
;$LastChangedBy: davin-mac $
;$LastChangedDate: 2014-03-20 08:39:09 -0700 (Thu, 20 Mar 2014) $
;$LastChangedRevision: 14612 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_retrieve.pro $
;-
function file_retrieve,pathnames, newpathnames, structure_format=structure_format,  $
    use_wget=use_wget, nowait=nowait, $
    local_data_dir=local_data_dir,remote_data_dir=remote_data_dir, $
    min_age_limit=min_age_limit , $
    last_version = last_version , $
    file_mode = file_mode,  $
    recurse_limit=recurse_limit, $
    dir_mode = dir_mode,   $
    user_agent=user_agent,   $
    preserve_mtime=preserve_mtime,  $
    restore_mtime=restore_mtime, $
    ascii_mode=ascii_mode,   $
    no_download=no_download,no_server=no_server, $
    no_update=no_update, $
    archive_ext=archive_ext, $
    archive_dir=archive_dir, $
    force_download=force_download,$
    no_clobber=no_clobber, ignore_filesize=ignore_filesize, $
    verbose=verbose,progress=progress,progobj=progobj

dprint,dlevel=4,verbose=verbose,'Start; $Id: file_retrieve.pro 14612 2014-03-20 15:39:09Z davin-mac $'
if keyword_set(structure_format) then begin
   user_agent =  'FILE_RETRIEVE: IDL'+!version.release + ' ' + !VERSION.OS + '/' + !VERSION.ARCH+ ' (' + (getenv('USER') ? getenv('USER') : getenv('USERNAME'))+')'
   str= {   $
      retrieve_struct,       $
      init:0,                $
      local_data_dir:root_data_dir(),  $ ;getenv('ROOT_DATA_DIR'),
      remote_data_dir:'',    $
      progress: 1    ,       $    ; Currently unused keyword   (progress is printed by default)
      user_agent:user_agent, $    ; User agent text to be sent to web server.
      file_mode:'666'o  ,    $    ; permissions for new files. (if non-zero)
      dir_mode: '777'o  ,    $    ; permissions for newly created directories.
      preserve_mtime: 1 ,    $    ; Set file modification to same as on file on server  (uses file_touch executable)
      progobj: obj_new(),    $    ; Experimental option for a progress bar widget.  (please ignore for now)
      min_age_limit: 30L   , $    ;   Files younger than this age (in seconds) are assumed current (avoids the need to recheck server)
      no_server:0     ,      $    ; Set to 1 to prevent any contact with a remote server.
      no_download:0   ,      $    ; similar to NO_SERVER keyword. Should still allow remote directory retrieval - but not files.
      no_update:0     ,      $    ; Set to 1 to prevent contact to server if local file already exists. (this is similar to no_clobber)
      no_clobber:0    ,      $    ; Set to 1 to prevent existing files from being overwritten. (A warning message will be displayed if remote server has)
      archive_ext:''  ,      $    ; Set archiving extension. (i.e.:  '.arc'). to rename old files instead of deleting them. Prevents accidental file deletion.
      archive_dir:''  ,      $    ; Set archiving subdirectory. (i.e.:  'archive/') 
      ignore_filesize:0 ,    $    ; Set to 1 to ignore the remote/local file sizes when determining if updates are needed.
      ignore_filedate:0 ,    $    ; Not yet operational.
      downloadonly:0  ,      $    ; Set to 1 to only download files but not load files into memory.
      use_wget:0          ,   $   ; Experimental option (uses the routine WGET instead of file_http_copy)
      nowait:0        ,      $    ; Used with wget to download files in the background.
      verbose:2 ,             $
      force_download: 0       $   ;Allows download to be forced no matter modification time.  Useful when moving between different repositories(e.g. QA and production data)
   }
   return, str
endif

;if keyword_set(no_download) then no_server = no_download ; Leave this line commented out.  The keyword NO_SERVER is independent of the NO_DOWNLOAD keyword 
;if not keyword_set(local_data_dir) then   local_data_dir = './'
;if not keyword_set(remote_data_dir) then   remote_data_dir = ''
vb = keyword_set(verbose) ? verbose : 0
if n_elements(progress) eq 0 then progress=1

;if keyword_set(progress) then begin
;    progobj = obj_new('progressbar')
;endif


;fullnames = filepath(root_dir=local_data_dir, pathnames)
fullnames = local_data_dir + pathnames   ; trailing '/' is not required on local_data_dir
n0 = n_elements(fullnames)

if keyword_set(use_wget) and total(/preserv,strmatch(pathnames,'*[ \* \? \[ \] ]*') ) ne 0 then begin
     use_wget=0
     dprint,dlevel=1,verbose=verbose,'Warning! WGET can not be used with wildcards!'
endif


if keyword_set(remote_data_dir) and  not (keyword_set(no_server) or keyword_set(no_download)) then begin

  if keyword_set(use_wget) then $
     wget,serverdir=remote_data_dir,localdir=local_data_dir,pathname=pathnames,verbose=verbose ,nowait=nowait $
  else begin

     http0 = strmid(remote_data_dir,0,7) eq 'http://'
     If obj_valid(progobj) Then progobj -> update, 0.0, text = string(format="('Retrieving ',i0,' files from ',a)",n0,remote_data_dir) ;jmm, 15-may-2007
     for i = 0l,n0-1 do begin
         fn = fullnames[i]
         pn = pathnames[i]
         npn = keyword_set(newpathnames) ? newpathnames[i] : ''
         
         ;2012-6-25: these variables may be single value or array
         ; error checks should probably be added to check # of elements between local_data_dir and
         ; remote_data_dir (if arrays), pathnames, and newpathnames
         http = n_elements(http0) gt 1 ? http0[i]:http0
         ldd = n_elements(local_data_dir) gt 1 ? local_data_dir[i]:local_data_dir
         rdd = n_elements(remote_data_dir) gt 1 ? remote_data_dir[i]:remote_data_dir

;         if keyword_set(no_update) and file_test(fn,/regular) then continue
         if http then begin
             file_http_copy,pn,npn,url_info=url_info,serverdir=rdd,localdir=ldd,verbose=verbose, $
               no_clobber=no_clobber,no_update=no_update,ignore_filesize=ignore_filesize,progobj=progobj, $
               no_download = no_download, archive_ext=archive_ext,archive_dir=archive_dir,  $
               ascii_mode=ascii_mode, $
               recurse_limit=recurse_limit, $
               user_agent=user_agent, $
               preserve_mtime = preserve_mtime, restore_mtime=restore_mtime, $
               file_mode=file_mode,dir_mode=dir_mode,last_version=last_version, $
               min_age_limit=min_age_limit,force_download=force_download
             if url_info[0].io_error ne 0 then begin
               dprint, "File or URL i/o error detected.  See !error_state for more info"
               printdat,!error_state
               return,''
             endif
         endif  else begin
             file_copy2,serverdir=remote_data_dir,localdir=local_data_dir,pathname=pn,verbose=verbose,no_clobber=no_update
         endelse
     endfor

  endelse

endif

; The following bit of code should find the highest version number if globbing is used.

for i=0,n_elements(fullnames)-1 do begin
   ff = file_search(fullnames[i],count=c)
   case c of
   0:    dprint,dlevel=3,verbose=vb,'No matching file: "'+fullnames[i]+'"'
   1:    begin
           fullnames[i] = ff[0]
           dprint,dlevel=3,verbose=vb,'Found: "'+fullnames[i]+'"'
         end
   else: begin
           if keyword_set(last_version) then begin
             dprint,dlevel=2,verbose=vb,strtrim(c,2)+' matches found for: "'+fullnames[i]+'"  Using last version.'
             fullnames[i] = ff[n_elements(ff)-1]   ; Cluge to Use highest version number?
           endif else begin
             dprint,dlevel=2,verbose=vb,'Multiple matches found for: "'+fullnames[i]+'"'
             fullnames = ff
           endelse
         end
   endcase
endfor

   

return,fullnames
end

