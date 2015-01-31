;+
; function: time_ephemeris(t)
; Purpose: conversion between unix time and ephemeris time
; Usage:   et = time_ephemeris(ut)          ; Converts from UT (unix/posix time) to ephemeris time
; Or:      ut = time_ephemeris(et,/et2ut)   ; Converts from ephemeris time to UT double precision (UNIX time)
;
; Does NOT require the ICY DLM to be loaded
;Author: Davin Larson
;-


function time_ephemeris,t,et2ut=et2ut,ut2et=ut2et,et2string=et2string
common time_ephemeris_com, ls_num,  ls_utimes, ls_etimes, utc_et_diff  ;, ls_etimes
;ls_num=0
if not keyword_set(ls_num) then begin
     ls_utimes = time_double(['0200-1-1','1972-1-1','1972-7-1','1973-1-1','1974-1-1','1975-1-1','1976-1-1','1977-1-1','1978-1-1','1979-1-1','1980-1-1',  $
     '1981-7-1','1982-7-1','1983-7-1','1985-7-1','1988-1-1','1990-1-1','1991-1-1','1992-7-1','1993-7-1','1994-7-1', $
     '1996-1-1','1997-7-1','1999-1-1','2006-1-1','2009-1-1','2012-7-1','2015-7-1','3000-1-1'])
    ls_num = dindgen(n_elements(ls_utimes)) + 9
    utc_et_diff = time_double('2000-1-1/12:00:00') -32.184   ;  -32.18392728
    ls_etimes = ls_utimes + ls_num - utc_et_diff 
;  printdat,ls_num,ls_utimes,ls_etimes,utc_et_diff
endif

if keyword_set(et2ut) then begin
    return, t -  floor( interp(ls_num,ls_etimes,t) ) + utc_et_diff   ; Not verified...
endif
;if keyword_set(ut2et) then begin
    ut = time_double(t)
    return, ut + floor( interp(ls_num,ls_utimes,ut) ) - utc_et_diff
;endif
message,'Must set at least one keyword!)
end





