;+
; Procedure: string_var_preprocess
;
; Purpose: Preprocesses tokenized input from the mini-language to extract strings from variables containing strings
;   Right now only works for variables containing single strings. 
;   If variables containing arrays of strings are used it will kinda work, but will multiply overwrite the output
;   
; Inputs: l : The token list after lexical analyzer.
;
; Outputs: sl : The list of token lists after string var preprocessing.
;
; Keywords: error: Returns an error struct if problem occurred.
; 
; Verbose: Set to get more detailed output
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-09-12 11:37:24 -0700 (Sat, 12 Sep 2015) $
; $LastChangedRevision: 18778 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/string_var_preprocess.pro $
;-

pro string_var_preprocess,l,sl,error=error,verbose=verbose

  compile_opt idl2,hidden
  
  mini_predicates

  ;right now disabled, cause it doesn't quite work
  sl = reform(l,1,n_elements(l))
  return 
  
  if n_elements(l) lt 3 then return ;doesn't work on less than 3 elements
 
  
  max_n = 1
  ;first pass, scan inputs to get size of output data structure 
  for i = 2l, n_elements(l)-1 do begin
    
    if is_identifier_type(l[i]) then begin
      
      if(is_string(scope_varfetch((l[i]).value,level=!mini_globals.scope_level))) then begin ;don't copy until we id type
        val = scope_varfetch((l[i]).value,level=!mini_globals.scope_level)
        if max_n eq 1 then begin
          if n_elements(val) gt 1 then max_n = n_elements(val)
        endif else begin
          if n_elements(val) ne max_n then begin
            error = {type:'error',name:'Mismatched string array sizes',value:l[i].value}
            if keyword_set(verbose) then begin
              dprint,'Error: Mismatched string array sizes: '  + l[i].value
            endif
            return
          endif
        endelse
      endif
      
    endif
    
  endfor

  sl = replicate(l[0],max_n,n_elements(l))

  sl[*,0] = l[0]
  sl[*,1] = l[1]
  
  for i = 2l, n_elements(l)-1 do begin

    ;must use && because short circuiting
    if is_identifier_type(l[i]) && (is_string(scope_varfetch((l[i]).value,level=!mini_globals.scope_level))) then begin
      val = scope_varfetch((l[i]).value,level=!mini_globals.scope_level)
      if n_elements(val) eq 1 then begin
        s = {type:'string',name:'"'+val+'"',value:'"'+val+'"',index:i}
        sl[*,i] = s
      endif else begin
        for j = 0,n_elements(val)-1 do begin
          s = {type:'string',name:'"'+val[j]+'"',value:'"'+val[j]+'"',index:i}
          sl[j,i] = s
        endfor
      endelse
    endif else begin
      sl[*,i] = l[i]
    endelse
  endfor
  
end