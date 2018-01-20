;
; This crib demonstrates basic work with tplot2cdf2
; 
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-19 14:52:43 -0800 (Fri, 19 Jan 2018) $
; $LastChangedRevision: 24552 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot2cdf2_basic.pro $

; Let's create simple data set, an example of a simple wave
time_start   = '2001-01-01'
time_sec_arr = indgen(200) / 10.
time_arr = time_double(time_start) + time_sec_arr

omega = 1./10. * 2. * !pi ; 100 mHz
amp   = 1.

var = amp * sin(omega * time_sec_arr)

; Create a tplot variable 
store_data, 'mHz_sin_wave', data={x:time_arr,y:var}

; Save cdf file with default (undefined) attibutes
tplot2cdf2, filename='mHz_wave_default', tvars='mHz_sin_wave', /default
stop

;
; Now we add some attibutes to the tplot vatiable
; 

; Create a fresh new tplot variable
del_data, 'mHz_sin_wave'
store_data, 'mHz_sin_wave', data={x:time_arr,y:var}

; Create CDF structure with default (undefined) attibutes of the tplot variables
; Note: CDF structure is created automatically if tplot2cdf2 with /default keyword has been used before
tplot_add_cdf_attributes, 'mHz_sin_wave'

; Now we can retrieve the CDF structure
get_data, 'mHz_sin_wave', alimits=s

; tplot variable should have the following fields of CDF structure:
; CDF.VARS - field that describe the data (tplot y variable)
; CDF.DEPEND_0 - this field correspond to the time (tplot x variable); 
; CDF.DEPEND_1 - supporting data (tplot v variable, it is not included into tplot variables in this example)
print, "CDF structure:"
help, s.CDF, /structure

; Now we can retrive the attibutes stucture that is stored in "attrptr" pointer
cdf_y_attr_struct = *s.CDF.VARS.attrptr

; Following attributes can be defined:
; CATDESC, DISPLAY_TYPE ,FIELDNAM, FORMAT, LABLAXIS, UNITS, VAR_TYPE
; FILLVAL, VALIDMIN, VALIDMAX are already defined based on the nature of the data (y variable)
; DEPEND_0 is also defined automatically
print, "Default (undefined) attibutes of the data:"
help, cdf_y_attr_struct, /structure

; Let's define some of the fields
cdf_y_attr_struct.CATDESC = '100 mHz wave'
cdf_y_attr_struct.LABLAXIS = 'Amplitude'
cdf_y_attr_struct.UNITS = '#'

; Now we need to save the attributes 
s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

; and include them in the tplot variable
options,'mHz_sin_wave','CDF', s.CDF

; Save cdf file with new attibutes
tplot2cdf2, filename='mHz_wave', tvars='mHz_sin_wave'
stop

;
; Now let add multiple variables into cdf file
;

; Let's create a second variable using the same time series
var = amp * cos(omega * time_sec_arr)
store_data, 'mHz_cos_wave', data={x:time_arr,y:var}

; CDF structure mus be defined for the new variable
tplot_add_cdf_attributes, 'mHz_cos_wave'

; Let's define the attibuted of the time variable. The CDF structure was alrready retiven from 'mHz_sin_wave' tplot variable
; Get attibuted for the time
cdf_x_attr_struct = *s.CDF.DEPEND_0.attrptr

; Define the field and save it in tplot varaible 
cdf_x_attr_struct.CATDESC = 'Time'
s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)
options,'mHz_sin_wave','CDF', s.CDF

; Since 'mHz_sin_wave' and 'mHz_cos_wave' are defined using the same time variable, tplot2cdf2 will determine that and will save only one Epoch
; Since 'mHz_sin_wave' goes first in the list of tvars, the attibutes of the Epoch will be taked from CDF structure of 'mHz_sin_wave'  
tplot2cdf2, filename='mHz_wave', tvars=['mHz_sin_wave', 'mHz_cos_wave']
end