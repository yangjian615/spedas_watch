;+
;Function: spice_test
;
;Purpose:  Tests whether the SPICE (idl/icy) module is installed
;          Provides installation message if not installed
;
;Keywords:
;         None
;
;Returns: 1 on success 0 on failure
;
;Example:
;   if(spice_test() eq 0) then return
;Notes:
;  Should be called in all idl spice wrapper routines
;
; Author: Davin Larson   (copied from icy_test.pro by Peter S.)
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function spice_test,files,verbose=verbose,set_flag=set_flag
common spice_test_com, tested

if n_elements(set_flag) ne 0 then tested=set_flag
;if n_elements(tested) eq 0 then return,0       ; temporary disable.  This line will be disabled in the future.

if n_elements(tested) ne 0 then return,tested

help, 'icy', /dlm, output = out

dprint,verbose=verbose,dlevel=3,out
filter = strfilter(out, '*ICY*',/index)
no_icy = filter[0] eq -1

if(no_icy) then begin
  message, /continue, 'Required module IDL/ICY is not installed!'
  message, /continue, 'To install ICY please download a copy of the'
  message, /continue, 'DLM files and Module libraries found at:'
  message, /continue, 'http://naif.jpl.nasa.gov/pub/naif/toolkit/IDL/'
  message, /continue, 'Uncompress/Unzip the file (ticy.zip or whatever)'
  message, /continue, 'Find the binary (.so or .dll) and the .dlm file'
  message, /continue, 'These are usually in the "lib" directory.'  
  message, /continue, 'Place the module binary (.so or .dll) and the .dlm in:'
  message, /continue, !DLM_PATH
  message, /continue, 'and restart IDL to install the package.'
  message, /continue, 'There are other installation instructions (IDL version 6.4 and below)'
  message, /continue, 'on the NAIF web site:'
  message, /continue, 'Please see both:
  message, /continue, 'http://naif.jpl.nasa.gov/naif/toolkit_IDL.html'
  message, /continue, 'AND'
  message, /continue, 'http://naif.jpl.nasa.gov/pub/naif/toolkit_docs/IDL/req/icy.html#Using Icy'
  message, /continue,''
     message,/continue, 'Special Note for MAC OS X users:'
     message,/continue, 'See note at: http://naif.jpl.nasa.gov/naif/bugs.html'
     message,/continue, 'Use a special build at: '
     message,/continue, 'http://naif.jpl.nasa.gov/pub/naif/misc/tmp/edw/ticy.zip
  
  

  return, 0
endif

if !version.os eq 'darwin' && out[1] lt '    Version: 1.6.6' then begin
   for i=0,n_elements(out)-1 do dprint,out[i]
   dprint,'Warning! This version of ICY is known to have a major bug.'
   dprint,'Please download a special build from: '
   dprint,'http://naif.jpl.nasa.gov/pub/naif/misc/tmp/edw/ticy.zip'
   message,'SORRY!!'
endif


if keyword_set(files) then begin
   kind = 'ALL'
   cspice_ktotal,kind,count
   if count gt 0 then kernels = strarr(count) else kernels=''
   kind = 'ALL'
   for i=0,count-1 do begin
      cspice_kdata,i,kind,filename,ft,source,handle,found
      kernels[i] = filename
   endfor
;   printdat,kernels
   mf = strfilter(kernels,files)
   return,mf
endif

return, 1
  
end
