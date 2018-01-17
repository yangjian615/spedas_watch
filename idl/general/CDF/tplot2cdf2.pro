;+
;
; Warning: this file is under development!
;
; Save tplot variables into cdf file
; The CDF global attributes can be specified by keywords inq and g_attributes
; The keyword default_cdf_attributes adds default variable attributes to the tplot variables
; 
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-16 16:31:13 -0800 (Tue, 16 Jan 2018) $
; $LastChangedRevision: 24527 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/tplot2cdf2.pro $
;-

pro tplot2cdf2, filename=filename, tvars=tplot_vars, inq=inq_structure, g_attributes=g_attributes_structure,tt2000=tt2000, default_cdf_attributes=default_cdf_attributes 
  
  FORWARD_FUNCTION cdf_default_inq_structure, cdf_default_g_attributes_structure  
  RESOLVE_ROUTINE, 'cdf_default_cdfi_structure', /IS_FUNCTION, /NO_RECOMPILE
   
  if undefined(filename) then return ; todo: add error
  
  if undefined(inq_structure) then inq_structure = cdf_default_inq_structure()
  if undefined(g_attributes_structure) then g_attributes_structure = cdf_default_g_attributes_structure()
  
  ; main structure
  idl_structure = {FILENAME:filename,$
    INQ: inq_structure,$
    g_attributes: g_attributes_structure,$
    NV: 0$
  }
      
  ; main arrays of data
  VARS = []   
  EpochVARS = []  
  SupportVARS = []
  EpochType = 'EPOCH16'
  if KEYWORD_SET(tt2000) then EpochType = 'TT2000'
  
  ; main loop
  for i =0,N_ELEMENTS(tplot_vars)-1 do begin    
    ; add default attributes. 
    ; this option will not overwrite existing fields
    tname = tplot_vars(i)
    if KEYWORD_SET(default_cdf_attributes) then tplot_add_cdf_attributes,tname    
    
    get_data,tname,data=d,alimit=s
        
    ; extract data
    str_element,d,'x',value=x
    str_element,d,'y',value=y
    str_element,d,'v',value=v
    if ~is_struct(d) then x = d

           
    ; here we don't check existence of CDF structure, it must be defined before
    ; we also don't check existence of x field
    VAR = s.CDF.VARS
    
    t = TAG_NAMES(s.CDF)
    
    ;
    ; Work with Epoch first
    ;
    EpochName = 'Epoch'
    if s.CDF.VARS.DATATYPE eq EpochType then begin
      EpochVAR = s.CDF.VARS      
      UNDEFINE, VAR ; remove var
    endif
    
    if array_contains(t,'DEPEND_0') then begin
      if s.CDF.DEPEND_0.DATATYPE eq EpochType then EpochVAR  = s.CDF.DEPEND_0
    endif
    EpochVAR.DATAPTR = ptr_new(x)
    
    InArray = 0
    for j=0,N_ELEMENTS(EpochVARS)-1 do begin
      if ARRAY_EQUAL(*EpochVARS[j].DATAPTR, *EpochVAR.DATAPTR) then begin
        InArray = 1
        EpochName = EpochVARS[j].NAME
      endif
    endfor
    
    if InArray eq 0 then begin ; add new epoch variable
      EpochN = N_ELEMENTS(EpochVARS)
      if EpochN gt 0 then EpochName = EpochName + '_' + strtrim(string(EpochN),1)
      EpochVAR.NAME = EpochName
      EpochVARS = array_concat(EpochVAR,EpochVARS)       
    endif
    
    ;
    ; Then we work with supporting data, same scenario
    ;   
    if array_contains(t,'DEPEND_1') then begin
     SupportName = s.CDF.DEPEND_1.NAME
     SupportVAR = s.CDF.DEPEND_1
     SupportVAR.DATAPTR = ptr_new(v)
     
     InArray = 0
     for j=0,N_ELEMENTS(SupportVARS)-1 do begin
       if ARRAY_EQUAL(*SupportVARS[j].DATAPTR, *SupportVARS.DATAPTR) then begin
         InArray = 1
         SupportName = SupportVARS[j].NAME
       endif
     endfor
   
     if InArray eq 0 then begin ; add new support variable              
       if ndimen(v) eq 2 then begin ; if support variable is 2d, then the first dimension corresponds to time 
        attr = *SupportVAR.ATTRPTR     
        str_element, attr,'DEPEND_0',EpochName,/add 
        SupportVAR.ATTRPTR = ptr_new(attr)
       endif
              
       SupportVARS = array_concat(SupportVAR,SupportVARS)
     endif
    endif
    
    ;
    ; Now work with the data
    ;
    if ~undefined(VAR) then begin
      attr = *VAR.ATTRPTR
      if array_contains(t,'DEPEND_0') then str_element, attr,'DEPEND_0',EpochName,/add            
      if array_contains(t,'DEPEND_1') then str_element, attr,'DEPEND_1',SupportName,/add 
      VAR.ATTRPTR = ptr_new(attr)
      VAR.DATAPTR = ptr_new(y)
            
      VARS = array_concat(VAR,VARS)
    endif    
  endfor
  
  VARS = array_concat(SupportVARS,VARS)
  VARS = array_concat(EpochVARS,VARS)
  
  
  idl_structure.NV = N_ELEMENTS(VARS)
  str_element, idl_structure,'VARS',VARS,/add
  ;help, idl_structure
  tplot2cdf_save_vars, idl_structure, filename
end   