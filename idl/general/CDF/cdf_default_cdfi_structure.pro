;+
;
; Warning: this file is under development!
;
; Number of functions that generate default structured for CDF files 
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-12 19:07:58 -0800 (Fri, 12 Jan 2018) $
; $LastChangedRevision: 24516 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/cdf_default_cdfi_structure.pro $
;-

function cdf_default_inq_structure
  ;   Basic parameters are requred by cdf_save_vars
  ;   CDFI.INQ.DECODING = 'HOST_DECODING' (can be network or host)
  ;   CDFI.INQ.ENCODING = 'NETWORK_ENCODING' (can be network or host)
  ;   CDFI.INQ.MAJORITY = 'ROW_MAJOR' (can be row or column)
  inq = {$
    DECODING:'HOST_DECODING',$
    ENCODING:'HOST_ENCODING',$
    MAJORITY:'ROW_MAJOR'$
  }
  return, inq
end

function cdf_default_g_attributes_structure
  g_attributes ={$
    Data_type: 'tplot',$
    Data_version: '1',$ 
    Descriptor:'tplot',$
    Discipline: 'Space Physics',$
    Instrument_type: 'tplot',$
    Logical_file_id:'',$ 
    Logical_source: 'tplot',$
    Logical_source_description:'cdf generated from tplot variable',$
    Mission_group: 'SPEDAS',$
    PI_affiliation: 'undefined',$
    PI_name: 'undefined',$
    Project:'SPEDAS',$
    Source_name:'SPEDAS',$
    TEXT: 'none'$
  }
  return, g_attributes
end

function cdf_default_attr_structure
attr = {$
  CATDESC:'none',$
  ;DEPEND_0:'',$
  ;DEPEND_1:'',$
  ;DEPEND_2:'',$
  ;DEPEND_3:'',$
  DISPLAY_TYPE:'undefined',$
  FIELDNAM:'none',$ ; type dependent
  ;FILLVAL:'undefined',$ ; type dependent
  FORMAT:'undefined',$
  LABLAXIS:'undefined',$
  ;LABL_PTR_1:'',$
  ;LABL_PTR_2:'',$
  ;LABL_PTR_3:'',$
  UNITS:'undefined',$ 
  ;VALIDMIN:'undefined',$ ; type dependent
  ;VALIDMAX:'undefined',$ ; type dependent
  VAR_TYPE:'data'$
}
return, attr
end

function cdf_default_vars_structure
  vars = {$
    NAME:'',$
    NUM:0,$
    IS_ZVAR:0,$
    DATATYPE:'',$
    TYPE:0,$
    NUMATTR:-1,$
    NUMELEM:0,$
    RECVARY:1b,$
    NUMREC:01,$
    NDIMEN:0,$
    D:lonarr(6),$
    DATAPTR:ptr_new(),$
    ATTRPTR:ptr_new(cdf_default_attr_structure())$
  }
  return, vars
end

function cdf_default_cdfi_structure
  ;   CDFI.FILENAME = Name of the CDF file
  ;   CDFI.INQ = A structure with information about the file
  ;   CDFI.g_atttributes = A structure, CDF global attributes
  ;   CDFI.NV = Number of variables
  ;   CDFI.VARS = AN array of CDFI.NV structures, one for each zvariable:

  cdfi = {FILENAME:'',$
    INQ: cdf_default_inq_structure(),$
    g_attributes: cdf_default_g_attributes_structure(),$
    NV: 0$
    ; VARS: array of vars
  }
  return, cdfi
end