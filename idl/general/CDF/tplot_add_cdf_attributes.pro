;+
;
; Warning: this file is under development!
;
; Create default CDF attibutes in the tplot variable
; tplot2cdf2 function requires additional CDF attribute structure
; The attibutes are stored in CDF structure in the tplot limits
; The possible fields are:
; CDF.VARS - default field that describe the data (tplot y variable)
; CDF.DEPEND_0 - this field correspond to time (tplot x variable)   
; CDF.DEPEND_1 - supporting data (tplot v variable)
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2017-12-22 00:21:43 -0800 (Fri, 22 Dec 2017) $
; $LastChangedRevision: 24456 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/tplot_add_cdf_attributes.pro $
;-

pro tplot_add_cdf_attributes, tplot_vars, tt2000=tt2000
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
    ; d has x and y and 1d v
    ; d has x and y and 2d v
    
    if ~undefined(x) then begin
      depend_0.name = 'Epoch'      
      depend_0.datatype = 'EPOCH16'
      depend_0.attrptr = ptr_new(CREATE_STRUCT($
         'FILLVAL',-1.0E31,$
         'VALIDMIN',time_epoch(time_double('0000-01-01:00:00:00.000000000000')),$
         'VALIDMAX',time_epoch(time_double('9999-12-31:23:59:59.999999999999')),$
          *depend_0.attrptr))
    endif
    
    if KEYWORD_SET(tt2000) then begin
      ; TODO: fix tt2000 case
      depend_0.datatype = 'TT2000'
      attr = *(depend_0.attrptr)
      attr.FILLVAL = -9223372036854775808LL
      attr.VALIDMIN = time_epoch(time_double('0000-01-01:00:00:00.000000000')) ; this is most likely incorrect
      attr.VALIDMAX = time_epoch(time_double('9999-12-31:23:59:59.999999999')) ; this is most likely incorrect      
      depend_0.attrptr = ptr_new(attr)
    endif
        
    if ~undefined(y) then begin
      vars.name = tplot_vars(i)     
      vars.datatype = idl2cdftype(y, validmax_out=vmax, validmin_out=vmin, fillval_out=vfill)  
      vars.attrptr = ptr_new(CREATE_STRUCT($
         'DEPEND_0','Epoch',$
         'FILLVAL',vfill,$
         'VALIDMIN',vmin,$
         'VALIDMAX',vmax,$
          *vars.attrptr))
    endif else begin
      ; this case if tplot is 1d
      vars = depend_0
      UNDEFINE, depend_0
    endelse
    
    if ~undefined(v) then begin
      depend_1 = cdf_default_vars_structure()
      depend_1.name = tplot_vars(i) + '_v'
      depend_1.datatype = idl2cdftype(v, validmax_out=vmax, validmim_out=vmin, fillval_out=vfill)
      depend_1.attrptr = ptr_new(CREATE_STRUCT($        
        'FILLVAL',vfill,$
        'VALIDMIN',vmin,$
        'VALIDMAX',vmax,$
        *depend_1.attrptr))
        
      vars.attrptr = ptr_new(CREATE_STRUCT($
        'DEPEND_1',depend_1.name,$       
        *vars.attrptr))
       
     ; if v is 2d
     if dimen(v) eq 2 then begin
       vars.attrptr = ptr_new(CREATE_STRUCT($
         'DEPEND_0','Epoch',$
         *vars.attrptr))      
     endif      
    endif
    
    ; This function does not rewrite existing VARS, DEPEND_0 and DEPEND_1 
    if is_struct(cdf_struct) then t = STRUPCASE(TAG_NAMES(cdf_struct)) else t = ''
    if ~array_contains(t, 'VARS') then cdf_struct = CREATE_STRUCT(cdf_struct, {VARS:vars})
    if ~undefined(depend_0) and ~array_contains(t, 'DEPEND_0') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_0:depend_0})
    if ~undefined(depend_1) and ~array_contains(t, 'DEPEND_1') then cdf_struct = CREATE_STRUCT(cdf_struct, {DEPEND_1:depend_1})    
    options,tplot_vars(i),'CDF',cdf_struct
  endfor
end
