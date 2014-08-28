;+
;NAME: SPICE_STANDARD_KERNELs
;USAGE:  files = spice_standard_kernels(/load)
;PURPOSE:
; Provides standard spice kernel filenames
; 
;CALLING SEQUENCE:
;  files=spice_standard_kernels(/load) 
;TYPICAL USAGE:
;INPUT:
;  none 
;KEYWORDS:
; LOAD:   Set keyword to retrieve and load file
;OUTPUT:
; fully qualified kernel filename(s)
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function spice_standard_kernels,load=load,source=source,reset=reset,verbose=verbose,mars=mars
common spice_standard_kernels_com, kernels,retrievetime,tranges
if ~spice_test()  then return,''
if keyword_set(reset) then kernels=0
ct = systime(1)
waittime = -300.           ; always check      ; search no more often than this number of seconds
if ~keyword_set(kernels) || (ct - retrievetime) gt waittime then begin     ; 
    naif = naif_file_source()
;    sprg = mvn_file_source()
    if not keyword_set(source) then source=naif
    source.no_update =1      ;  Don't check for file if it exists
    if keyword_set(verbose) then source.verbose=verbose
    kernels=0
;        WARNING!!!!!  ALL FILE NAMES LISTED BELOW ARE SUBJECT TO CHANGE AND DO CHANGE REGULARLY
    append_array,kernels,  file_retrieve('generic_kernels/lsk/naif0010.tls',_extra=source)        ; naif0010.tls is most recent as of 2013/12/16
    append_array,kernels,  file_retrieve('generic_kernels/pck/pck00010.tpc',_extra=source)        ; pck00010.tpc is most recent as of 2013/12/16
;    append_array,kernels,  file_retrieve('generic_kernels/spk/planets/de421.bsp',_extra=source)   ; Now obsolete ....  No longer on NAIF site!
;    append_array,kernels,  file_retrieve('generic_kernels/spk/planets/a_old_versions/de421.bsp',_extra=source)   ; archived location of de421.bsp
    append_array,kernels,  file_retrieve('generic_kernels/spk/planets/de430.bsp',_extra=source)   ; de430.bsp is most recent as of 2013/12/16     
    if keyword_set(mars) then  append_array,kernels,  file_retrieve('generic_kernels/spk/satellites/mar097.bsp',_extra=source)   ; mar097.bsp is most recent as of 2014/1/1 ??    
    retrievetime = ct
;    kernels = file_search(kernels)
endif
if keyword_set(load) then    spice_kernel_load,kernels,verbose=verbose
return,kernels
end
