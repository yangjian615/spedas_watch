;+
;PROCEDURE:
;  TPLOT_ADD_CDF_STRUCTURE, tplot_vars, ...
;   
;PURPOSE:  
;  In order to be saved in CDF file using TPLOT2CDF2, tplot variable must have CDF structure as a tplot option (see OPTIONS) 
;  The attributes of the tplot data (x, y or v) are stored in the CDF structure
;  CDF.VARS     - structure of attributes that describe the data (tplot y variable)
;  CDF.DEPEND_0 - structure of attributes that describe the time (tplot x variable)
;  CDF.DEPEND_1 - structure of attributes that supporting data (tplot v variable)
;  
;  Each structure of attributes must have following fileds:
;  CATDESC, DISPLAY_TYPE ,FIELDNAM, LABLAXIS, UNITS (automatically defined for time), VAR_TYPE
;  FILLVAL, VALIDMIN, VALIDMAX, FORMAT defined based on the nature of the data
;  
;  TPLOT_ADD_CDF_STRUCTURE adds appropriate CDF structure and defines some of the attributes base on the tplot data
;  This procedure must be called before tplot2cdf2. Alternatively, keyword /default of tplto2cdf2 can be used.
;  Most of the attributes are defined as 'undefined' ans should be specify.  
;  
;  If tplot has 2d y but v, that suppose to describe second dimension is absent, then v will be created and an index of the second dimension of y
;   
;INPUT:
;   tplot_vars: (string or array of strings) Tplot variable name, or list of the tplot variables  
;   
;KEYWORDS:
;   TT2000: (flag) Reserved for future use
;
;EXAMPLES:   
;   store_date, 'example_tplot',data={x:time_double('2001-01-01')+[1, 2, 3],y:[10, 20, 30]}
;   tplot_add_cdf_structure, 'example_plot'  
;   tplot2cdf2, filename='example_cdf_file', tvars='example_plot'
;  
;  See crib_tplot2cdf2_basic for additional examples 
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-26 13:24:32 -0800 (Fri, 26 Jan 2018) $
; $LastChangedRevision: 24598 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/tplot_add_cdf_structure.pro $
;-

pro tplot_add_cdf_structure, tplot_vars, tt2000=tt2000

  ; resolve dependences
  FORWARD_FUNCTION cdf_default_vars_structure, cdf_default_vars_structure
  RESOLVE_ROUTINE, 'cdf_default_cdfi_structure', /IS_FUNCTION, /NO_RECOMPILE

  for i=0,n_elements(tplot_vars)-1 do begin
    get_data,tplot_vars(i),data=d,alimits=s
    
    if is_struct(s) then t = STRUPCASE(TAG_NAMES(s)) else t = ''
           
    ; get original structure if exist
    if array_contains(t, 'CDF') then cdf_struct = s.cdf else cdf_struct = {}
    vars = cdf_default_vars_structure()
    depend_0 = cdf_default_vars_structure()
    
    ; extract data
    str_element,d,'x',value=x
    str_element,d,'y',value=y
    str_element,d,'v',value=v            
    if ~is_struct(d) then x = d
    
    ; cases:
    ; d is an array
    ; d has x
    ; d has x and y
    ; d has x and 2d y but no v
    ; d has x and y and 1d v     
    ; d has x and y and 2d v
    
; === CDF_EPOCH ===    
    if ~undefined(x) then begin
      depend_0.name = 'Epoch'
      depend_0.datatype = 'CDF_EPOCH'           
      attr = *depend_0.attrptr
      str_element,attr,'FILLVAL',-1.0d31 ,/add
      str_element,attr,'VALIDMIN',0.0d ,/add
      str_element,attr,'VALIDMAX',time_epoch('9999-12-31:23:59:59.999'),/add
      attr.FORMAT = ' '      
      attr.UNITS  = 'ms'      
      str_element, attr,'TIME_BASE','0AD',/add  ; Additional attibute is added for netCDF files
      depend_0.attrptr = ptr_new(attr)  
    endif
    
; === CDF_EPOCH16 is disabled ===    
;    if ~undefined(x) then begin
;      depend_0.name = 'Epoch'      
;      depend_0.datatype = 'CDF_EPOCH16'
;      tformat = 'YYYY-MM-DD:hh:mm:ss.ffffffffffff'            
;      depend_0.attrptr = ptr_new(CREATE_STRUCT($
;         'FILLVAL',-1.0E31,$
;         'VALIDMIN',time_epoch16('0000-01-01:00:00:00.000000000000',tformat=tformat),$
;         'VALIDMAX',time_epoch16('9999-12-31:23:59:59.999999999999',tformat=tformat),$
;         'UNITS',''
;          *depend_0.attrptr))
;    endif
    
; === CDF_TIME_TT2000 ===    
    if KEYWORD_SET(tt2000) then begin
      ; TODO: fix tt2000 case
;      depend_0.datatype = 'CDF_TIME_TT2000'
;      attr = *(depend_0.attrptr)
;      attr.FILLVAL = -9223372036854775808LL
;      attr.VALIDMIN = time_epoch(time_double('0000-01-01:00:00:00.000000000')) ; this is most likely incorrect
;      attr.VALIDMAX = time_epoch(time_double('9999-12-31:23:59:59.999999999')) ; this is most likely incorrect      
;      'UNITS',''
;      depend_0.attrptr = ptr_new(attr)
    endif
        
    if ~undefined(y) then begin
      vars.name = tplot_vars(i)     
      vars.datatype = idl2cdftype(y, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill, format_out=format_out)  
      attr = *vars.attrptr 
      str_element,attr,'FILLVAL',vfill,/add
      str_element,attr,'VALIDMIN',vmin,/add
      str_element,attr,'VALIDMAX',vmax,/add
      attr.FORMAT = format_out      
      str_element, attr,'DEPEND_0','Epoch',/add
      vars.attrptr = ptr_new(attr)       
      
      ;  === Checking the missing v if we have 2d y ===      
      if ndimen(y) gt 1 && undefined(v) then begin
        ; Here we will assume that it is not a spectrogram
        dy = dimen(d.y)
        ny = dy[1]
        v = INDGEN(ny) ; just indexing                  
        if ~undefined(x) then ds = {x:x,y:y,v:v} else ds = {y:y,v:v}
        store_data, tplot_vars(i),data= ds ; save v into the tplot variable
      endif
      
    endif else begin ; no y
      ; this case if tplot is 1d
      vars = depend_0
      UNDEFINE, depend_0
    endelse


    if ~undefined(v) then begin
      depend_1 = cdf_default_vars_structure()
      depend_1.name = tplot_vars(i) + '_v'
      depend_1.datatype = idl2cdftype(v, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill, format_out=format_out)
      attr = *depend_1.attrptr    
      str_element,attr,'FILLVAL',vfill,/add
      str_element,attr,'VALIDMIN',vmin,/add
      str_element,attr,'VALIDMAX',vmax,/add
      attr.FORMAT = format_out
      depend_1.attrptr = ptr_new(attr)         
      ;vars.attrptr = ptr_new(CREATE_STRUCT('DEPEND_1',depend_1.name,*vars.attrptr)) ; one line addition to the attribute structure
      str_element, *vars.attrptr,'DEPEND_1',depend_1.name,/add
               
     ; if v is 2d
     if ndimen(v) gt 1 then begin
       ; in this case first dimension of v is time (we don't check the actual number of records)
       ; vars.attrptr = ptr_new(CREATE_STRUCT('DEPEND_0','Epoch',*vars.attrptr)) ; one line addition to the attribute structure             
       str_element, *vars.attrptr,'DEPEND_0','Epoch',/add
       
       
     endif else begin
       ; if v is 1d then it does not change in time
        depend_1.recvary = 0b
     endelse
       
    endif
    
    ; This function does not rewrite existing VARS, DEPEND_0 and DEPEND_1 
    if is_struct(cdf_struct) then t = STRUPCASE(TAG_NAMES(cdf_struct)) else t = ''
    if ~array_contains(t, 'VARS') then cdf_struct = CREATE_STRUCT(cdf_struct, {VARS:vars})
    if ~undefined(depend_0) and ~array_contains(t, 'DEPEND_0') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_0:depend_0})
    if ~undefined(depend_1) and ~array_contains(t, 'DEPEND_1') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_1:depend_1})    
    options,tplot_vars(i),'CDF',cdf_struct
  endfor
end
