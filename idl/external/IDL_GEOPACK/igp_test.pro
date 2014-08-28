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
; $LastChangedDate: 2014-03-17 09:54:36 -0700 (Mon, 17 Mar 2014) $
; $LastChangedRevision: 14547 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/igp_test.pro $
;-

function igp_test, geopack_2008=geopack_2008

help, /dlm, output = out

; the current version, v9.2, was released on 2/26/2014
v_string = '9.2'

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
if ~stregex(out[filter+1],v_string,/boolean) && ~undefined(geopack_2008) then begin
  message, /continue, 'Old version of Geopack found'
  message, /continue, 'Version ' + v_string + ' expected'
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

return, 1
  
end
