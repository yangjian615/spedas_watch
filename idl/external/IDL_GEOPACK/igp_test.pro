;+
;Function: igp_test
;
;Purpose:  Tests whether the idl/geopack module is installed
;          Provides installation message if not installed
;
;Keywords:
;         geopack_2008: set to use the 2008 version of the Geopack library. 
;             Must have version 9.2 of the IDL Geopack DLM installed to use 
;             the geopack_2008 keyword
;         
;
;Returns: 1 on success 0 on failure
;
;Example:
;   if(igp_test() eq 0) then return
;   
;Notes:
;  Should be called in all idl geopack wrapper routines
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-10-31 12:54:36 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16105 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/igp_test.pro $
;-

function igp_test, geopack_2008=geopack_2008

    help, /dlm, output = out
    
    ; Geopack 2008 support was introduced in version 9.0, released on 2/26/2014
    version_geopack08 = [9, 0]
    
    filter = strfilter(out, '*GEOPACK*',/index)
    
    ; check that the Geopack DLM is installed
    if(filter[0] eq -1) then begin
      message, /continue, 'Required module IDL/GEOPACK not installed'
      message, /continue, 'To install geopack please download a copy'
      message, /continue, 'Place the module binary and the .dlm in:'
      message, /continue, !DLM_PATH
      message, /continue, 'and restart IDL to install the package'
      message, /continue, 'more detailed installation instructions'
      message, /continue, 'can be found on the Geopack DLM web site (http://ampere.jhuapl.edu/code/idl_geopack.html), or'
      message, /continue, 'in the Themis software distribution at'
      message, /continue, 'external/IDL_GEOPACK/README.txt'
      return, 0
    endif
    
    ; check the version of the Geopack DLM if the user requested Geopack 2008
    geopack_version = stregex(out[filter+1], '([0-9.]+[0-9]?), Build', /extract)
    version_num = (strsplit(geopack_version[0], ', ', /extract))[0]
    version_num_pieces = strsplit(version_num, '.', /extract)
    if version_num_pieces[0] lt version_geopack08[0] || $
      (version_num_pieces[0] eq version_geopack08[0] && version_num_pieces[1] lt version_geopack08[1]) then begin
      message, /continue, 'Old version of Geopack found'
      message, /continue, 'Version 9.2+ expected when using the Geopack 2008 keyword'
      message,/continue, 'Please download the newest version and'
      message, /continue, 'place the binary(.dll,.so,.etc..) and the .dlm in:'
      message, /continue, !DLM_PATH
      message, /continue, 'then restart IDL to install the package'
      message, /continue, 'More detailed installation instructions'
      message, /continue, 'can be found on the Geopack DLM web site (http://ampere.jhuapl.edu/code/idl_geopack.html), or'
      message, /continue, 'in the Themis software distribution at'
      message, /continue, 'external/IDL_GEOPACK/README.txt'
      return, 0
    endif
    
    ; If the user has the Geopack DLM installed, but can't load it for some reason 
    ; (e.g., missing/wrong dependencies), the igp_test() routine will still 
    ; return 1 and a crash will occur when the user tries to load Geopack. 
    ; The following 'catch', 'dlm_load 'sequence is meant to avoid this by
    ; catching the error thrown by loading the DLM
    ; this error case was initially seen trying to load Geopack 9.2 on CentOS 6.5
    catch, geopack_dlm_error
    
    if geopack_dlm_error ne 0 then begin
        catch, /cancel
        help, /last_message, output=err_msg
        message, /continue, 'The Geopack DLM was found, but there was a problem loading it.'
        for line_num=0, n_elements(err_msg)-1 do begin
            message, /continue, err_msg[line_num]
        endfor
        return, 0
    endif
    dlm_load, 'geopack'
    
    return, 1
end
