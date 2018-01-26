;+
;
; Warning: this file is under development!
;
; Save tplot variables into cdf file
; The CDF global attributes can be specified by keywords inq and g_attributes
; The keyword default_cdf_attributes adds default variable attributes to the tplot variables
; Time (x variable of tplot) should be in SPEDAS (unix) format, please see time_double for details
; 
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-24 22:43:19 -0800 (Wed, 24 Jan 2018) $
; $LastChangedRevision: 24586 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/tplot2cdf2.pro $
;-

pro tplot2cdf2, filename=filename, tvars=tplot_vars, inq=inq_structure, g_attributes=g_attributes_custom,tt2000=tt2000, default_cdf_attributes=default_cdf_attributes, compress_cdf=compress_cdf 
  
  FORWARD_FUNCTION cdf_default_inq_structure, cdf_default_g_attributes_structure  
  RESOLVE_ROUTINE, 'cdf_default_cdfi_structure', /IS_FUNCTION, /NO_RECOMPILE
   
  if undefined(filename) then return ; todo: add error
  
  if undefined(inq_structure) then inq_structure = cdf_default_inq_structure()
  g_attributes_structure = cdf_default_g_attributes_structure()
  if ~undefined(g_attributes_custom) then begin
    g_tag = tag_names(g_attributes_custom)
    for i=0,N_ELEMENTS(g_tag)-1 do begin    
      str_element,g_attributes_structure,g_tag[i],g_attributes_custom.(i),/add
    endfor
  endif
  
  
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
  EpochType = 'CDF_EPOCH' ; default Epoch type
  if KEYWORD_SET(tt2000) then EpochType = 'TT2000'
  
  ; main loop
  for i =0,N_ELEMENTS(tplot_vars)-1 do begin    
    ; add default attributes. 
    ; this option will not overwrite existing fields
    tname = tplot_vars(i)
    if KEYWORD_SET(default_cdf_attributes) then tplot_add_cdf_attributes,tname    
    
    get_data,tname,data=d,alimit=s
    
    str_element,s,'CDF',SUCCESS=cdf_s
    if cdf_s eq 0  then begin
      print, "ERROR: Missing CDF structure in tplot variable " + tname
      print, "Use tplot_add_cdf_attributes procedure to define CDF structure or use /default_cdf_attributes keyword"
      return
    endif
        
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
    ; If user defined only one x variable in tplot we consider it as Epoch
    ; In this case CDF may contain only one field VARS wich is Epoch  
    EpochName = 'Epoch'
    if s.CDF.VARS.DATATYPE eq EpochType then begin
      EpochVAR = s.CDF.VARS      
      UNDEFINE, VAR ; remove var
    endif
    
    if array_contains(t,'DEPEND_0') then begin
      if s.CDF.DEPEND_0.DATATYPE eq EpochType then EpochVAR  = s.CDF.DEPEND_0
    endif
    
    ; === CDF_EPOCH ===
    ; 
    ; Time should be in SPEDAS format, which is UNIX time.
    ; Add variable and convert it into Epoch
    EpochVAR.DATAPTR = ptr_new(time_epoch(x), /NO_COPY)
    
    ; === CDF_TIME_TT2000 ===
    ; is long 64 ?? No? - exit!
    ; EpochVAR.DATAPTR = ptr_new(long64(x)?, /NO_COPY)
    ; str_element, *(EpochVAR.ATTRPTR),'TIME_BASE','J2000',/add
    
    
    
    InArray = 0 ; flag of having Epoch in array EpochVARS  
    for j=0,N_ELEMENTS(EpochVARS)-1 do begin
      if ARRAY_EQUAL(*EpochVARS[j].DATAPTR, *EpochVAR.DATAPTR) then begin
        InArray = 1
        EpochName = EpochVARS[j].NAME
      endif
    endfor
    
    if InArray eq 0 then begin ; add new epoch variable
      EpochN = N_ELEMENTS(EpochVARS)
      if EpochN gt 0 then EpochName = EpochName + '_' + strtrim(string(EpochN),1)
      EpochVAR.NAME = EpochName ; name      
      (*Epochvar.ATTRPTR).VAR_TYPE = 'support_data' ; Automaticaly change attributes for Epoch variable      
      EpochVARS = array_concat(EpochVAR,EpochVARS)       
    endif
    
    ;
    ; Then we work with supporting data, same scenario
    ;   
    if array_contains(t,'DEPEND_1') then begin
     SupportName = s.CDF.DEPEND_1.NAME
     SupportVAR = s.CDF.DEPEND_1
     SupportVAR.DATAPTR = ptr_new(v, /NO_COPY)
     
     InArray = 0
     for j=0,N_ELEMENTS(SupportVARS)-1 do begin
       if ARRAY_EQUAL(*SupportVARS[j].DATAPTR, *SupportVAR.DATAPTR) then begin
         InArray = 1
         SupportName = SupportVARS[j].NAME
       endif
     endfor
   
     if InArray eq 0 then begin ; add new support variable
       attr = *SupportVAR.ATTRPTR                         
       if ndimen(v) eq 2 then str_element, attr,'DEPEND_0',EpochName,/add ; if support variable is 2d, then the first dimension corresponds to time               
       if STRCMP(attr.VAR_TYPE, 'undefined') then attr.VAR_TYPE = 'support_data' ;Change attributes for support variable variable
       SupportVAR.ATTRPTR = ptr_new(attr)
       SupportVARS = array_concat(SupportVAR,SupportVARS)       
     endif
    endif
    
    ;
    ; Now work with the data
    ;
    if ~undefined(VAR) then begin
      attr = *VAR.ATTRPTR
      if STRCMP(attr.VAR_TYPE, 'undefined') then attr.VAR_TYPE = 'data' ;Change attributes for data variable variable
      if STRCMP(attr.DISPLAY_TYPE, 'undefined') then begin
        attr.DISPLAY_TYPE = 'time_series' ; if display type is not defined we assume that it is a time_series        
        if array_contains(t,'DEPEND_1') then begin
          spec = 0
          str_element,s,'spec',spec ; determine if tplot variable is a spectrogram
          if spec eq 1 then begin
            attr.DISPLAY_TYPE = 'spectrogram'
          endif else begin
            attr.DISPLAY_TYPE = 'stack_plot'
          endelse
        endif
      endif
      if array_contains(t,'DEPEND_0') then str_element, attr,'DEPEND_0',EpochName,/add            
      if array_contains(t,'DEPEND_1') then str_element, attr,'DEPEND_1',SupportName,/add 
      VAR.ATTRPTR = ptr_new(attr)
      VAR.DATAPTR = ptr_new(y, /NO_COPY)
            
      VARS = array_concat(VAR,VARS)
    endif    
  endfor
  
  VARS = array_concat(SupportVARS,VARS)
  VARS = array_concat(EpochVARS,VARS)
  
  
  idl_structure.NV = N_ELEMENTS(VARS)
  str_element, idl_structure,'VARS',VARS,/add
  ;help, idl_structure
  tplot2cdf_save_vars, idl_structure, filename, compress_cdf=compress_cdf
end   