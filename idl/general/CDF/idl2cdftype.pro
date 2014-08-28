;+
;NAME:
; idl2cdftype
;PURPOSE:
; Given an IDL variable, return the appropriate CDF type code
;CALLING SEQUENCE:
; code = idl2cdftype(var)
;INPUT:
; var = an IDL variable
;OUTPUT:
; code = the CDF data type code for that variable, if applicable, for
;        objects, complex,  and similar vars a null string is returned.
;    IDL_TYPE             CDF_TYPE
;    1 (byte)             'CDF_UINT1'
;    2 (int)              'CDF_INT2'
;    3 (long)             'CDF_INT4'
;    4 (float)            'CDF_FLOAT'
;    5 (double)           'CDF_DOUBLE'
;    7 (string)           'CDF_CHAR'
;    12 (unsigned int)    'CDF_UINT2'
;    13 (unsigned long)   'CDF_UINT4'
;    14 (long64)          'CDF_INT8'
;    15 (unsigned long64) 'CDF_UINT8'
;
;HISTORY:
; 26-nov-2013, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2013-11-26 11:46:46 -0800 (Tue, 26 Nov 2013) $
; $LastChangedRevision: 13596 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/idl2cdftype.pro $
;-
Function idl2cdftype, var

otp = ''
Case(size(var, /type)) Of        ;text code for type
    1: otp = 'CDF_UINT1'
    2: otp = 'CDF_INT2'
    3: otp = 'CDF_INT4'
    4: otp = 'CDF_FLOAT'
    5: otp = 'CDF_DOUBLE'
    7: otp = 'CDF_CHAR'
    12: otp = 'CDF_UINT2'
    13: otp = 'CDF_UINT4'
    14: otp = 'CDF_INT8'
    15: otp = 'CDF_UINT8'
    Else: otp = ''
Endcase

Return, otp
End
