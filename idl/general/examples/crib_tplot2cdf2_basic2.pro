;
; This crib demonstrates work with tplot2cdf2 when v variable is defined
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-23 20:38:14 -0800 (Tue, 23 Jan 2018) $
; $LastChangedRevision: 24575 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot2cdf2_basic2.pro $

del_data, 'vector_variable' ; clear

; Let's create a tplot variable that has 3 lines
store_data,'vector_variable',data={x:time_double('2007-03-23')+dindgen(120),y:dindgen(120,3)^2}

; Create CDF structure
tplot_add_cdf_attributes, 'vector_variable'

; Becasue we y is 2d array, but v is not defined, tplot_add_cdf_attributes automatically add v variable (index on the line)
get_data, 'vector_variable', data=d, limits=s
help, d, /struct  

; Let's define the attibutes   

; === DEPEND_0 is x ===
cdf_x_attr_struct = *s.CDF.DEPEND_0.attrptr
cdf_x_attr_struct.CATDESC = 'Time of the vector'
cdf_x_attr_struct.LABLAXIS = 'Time'
s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)

; === VARS is y ===
cdf_y_attr_struct = *s.CDF.VARS.attrptr
cdf_y_attr_struct.CATDESC = '3 Vectors'
cdf_y_attr_struct.LABLAXIS = 'Vector Value'
cdf_y_attr_struct.UNITS = 'arb. unit.'
s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

; === DEPEND_1 is v ===
cdf_v_attr_struct = *s.CDF.DEPEND_1.attrptr
cdf_v_attr_struct.CATDESC = 'Vector index'
cdf_v_attr_struct.LABLAXIS = 'Index'
cdf_v_attr_struct.UNITS = '#'
; add additional attibute
str_element,cdf_v_attr_struct,'VAR_NOTES','Index of the vectors was automatically created by tplot_add_cdf_attributes function',/add
s.CDF.DEPEND_1.attrptr = ptr_new(cdf_v_attr_struct)

; Save CDF structure into tplot variable
options,'vector_variable','CDF', s.CDF

; Save cdf file 
tplot2cdf2, filename='vector_variable', tvars='vector_variable'
; Now you can use program like autoplot to read vector_variable.cdf 
stop

; Now let's add some general properties of the cdf file
general_structure = {PI_affiliation:'UCLA',Acknowledgement:'SPEDAS development team'}
tplot2cdf2, filename='vector_variable_general', tvars='vector_variable', g_attributes=general_structure

stop

; Finally, let save compressed cdf file
; compress_cdf flag correspond to SET_COMPRESSION parameter of CDF_COMPRESSION
; In this case GZIP compression is used
tplot2cdf2, filename='vector_variable_compressed', tvars='vector_variable', g_attributes=general_structure, compress=5

end