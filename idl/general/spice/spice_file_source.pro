;+
;NAME:
; spice_file_source
;PURPOSE:
; Provides a structure that contains information pertinent to the locaton (and downloading) of SPICE data files
;CALLING SEQUENCE:
;  source=spice_file_source() 
;TYPICAL USAGE:
;  pathname = 'MAVEN/kernels/sclk/MVN_SCLKSCET.?????.tsc''
;  sclk_kernel = file_retrieve(pathname,_extra = spice_file_source() ,/last_version)
;INPUT:
;  None required.
;  If default_source is provided then the relevant structure elements are copied and used in the output
;KEYWORDS:
;  SET  : If set, then the values in DEFAULT_SOURCE are made permanent.
;OUTPUT: 
; Structure:
;  see FILE_RETRIEVE for a description of the elements
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2015-10-21 12:07:29 -0700 (Wed, 21 Oct 2015) $
; $LastChangedRevision: 19127 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_file_source.pro $
;-



function spice_file_source,DEFAULT_SOURCE,set=set,reset=reset,_extra=ex
common spice_file_source_com,  psource

if keyword_set(reset) then psource=0

if not keyword_set(psource) then begin
    psource = file_retrieve(/struct)
    psource.remote_data_dir = 'http://naif.jpl.nasa.gov/pub/naif/'
    psource.local_data_dir  += 'misc/spice/naif/'
    if file_test(psource.local_data_dir+'.master',/regular) then psource.no_server =1    ; local directory IS the server directory
    psource.archive_ext = '.arc'   ; archive old files instead of deleting them
    psource.archive_dir = 'archive/'  ; archive directory
    psource.preserve_mtime = 1
;    psource.no_update = 1
    psource.verbose=2
    psource.min_age_limit=3600  ; one hour delay before checking again
    str_element,/add,psource,'strict_html',0
;    str_element,/add,psource,'LAST_VERSION',1        
endif

if size(/type,default_source) eq 8 then  source= default_source  else source = psource

if keyword_set(ex) then begin
    tags = tag_names(ex)
    for i=0,n_elements(tags)-1 do begin
       str_element,/add,source,tags[i],ex.(i)
    endfor
endif

if keyword_set(set) then begin 
    psource = source      
endif 


return,source
end
