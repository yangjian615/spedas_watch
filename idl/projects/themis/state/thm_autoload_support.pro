;+
;NAME:
; thm_autoload_support
;PURPOSE:
; given a THEMIS tplot variable name, check to see if spin period and
; phase exist, for coordinate transformations, If they do not, load
; the state data for the appropriate time period
;CALLING SEQUENCE:
; thm_autoload_support, vname, /spinmodel, /spinaxis, /slp, probe_in=probe,
;     trange=[tmin, tmax], history_out=hist_string
;INPUT:
; vname = tplot variable name
;OUTPUT:
;KEYWORDS:
; probe_in: Specifies the probe name to load support data for (required
;           for /spinmodel and /spinaxis)
; spinmodel: if set, ensure spinmodel data is loaded and covers the
;           requested time interval
; spinaxis: if set, ensure state (spinras, spindec) data is loaded and 
;           covers the requested time interval
; slp:  if set, ensure sun & moon data are loaded and cover the requested
;       time interval (not yet implemented)
; trange: Specify a time range for which support data should be loaded
;        (required if vname is not supplied)
; history_out = a history string, if data needs loading
;HISTORY:
; 2013-12-19: Adapted from thm_ui_check4spin by jwl
; 
; NOTES:
; 
;$LastChangedBy: jwl $
;$LastChangedDate: 2014-01-24 16:07:46 -0800 (Fri, 24 Jan 2014) $
;$LastChangedRevision: 14013 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/thm_autoload_support.pro $
;
;-
Pro thm_autoload_support, vname=vname, spinmodel=spinmodel, spinaxis=spinaxis, slp=slp, history_out=history_out, probe_in=probe_in, trange=trange, progobj=progobj, _extra=_extra

; Check to see if input variable name is specified
if (not keyword_set(vname)) then begin
  if (not keyword_set(trange)) then begin
    message, 'The trange keyword must be used if no input variable name is supplied.'
  endif
  if (not keyword_set(probe_in)) then begin
    message, 'The probe_in keyword must be used if no input variable name is supplied.'
  endif
endif




; Set probe letter (from input tplot variable, if necessary)
  If(keyword_set(probe_in)) Then probe = probe_in $
  Else probe = strmid(vname, 2, 1)

; Set trange (from input tplot variable, if necessary)
  If(not keyword_set(trange)) then begin
    get_data,vname,trange=trange
    if n_elements(trange) NE 2 then begin
       message,'Tplot variable name ' + vname + ' not found.'
    endif
  endif


  ; Maximum allowable extrapolation time (seconds) outside range of support data
  slop=120.0D

; If state support data is needed, set loadstate to 1
; If slp (lunar) support data is needed, set loadslp to 1.

  loadstate = 0b
  loadslp = 0b

; Does loaded spin model data cover the time range?

  if (keyword_set(spinmodel)) then begin
    smp=spinmodel_get_ptr(probe)
    if (not obj_valid(smp)) then loadstate=1b else begin
       smp->get_info,start_time=st, end_time=et
       st = st-slop
       et = et+slop
       if ((trange[0] LT st) OR (trange[1] GT et)) then begin
          loadstate=1b
       endif
    endelse
  endif

; Does loaded spin axis data cover the time range?

  if (keyword_set(spinaxis)) then begin
     all_names = tnames()
     var1 = 'th'+probe+'_state_spinras'
     var2 = 'th'+probe+'_state_spindec'
     var3 = 'th'+probe+'_state_spinras_corrected'
     var4 = 'th'+probe+'_state_spindec_corrected'
     get_data,var1,trange=tr1
     get_data,var2,trange=tr2
     get_data,var3,trange=tr3
     get_data,var4,trange=tr4
     if ( (n_elements(tr1) NE 2) OR (n_elements(tr2) NE 2) OR $
          (n_elements(tr3) NE 2) OR (n_elements(tr4) NE 2)) then begin
        loadstate=1b
     endif else begin
        tr1 += [-slop,slop]
        tr2 += [-slop,slop]
        tr3 += [-slop,slop]
        tr4 += [-slop,slop]
        if ((trange[0] LT tr1[0]) OR (trange[1] GT tr1[1])) then begin
          loadstate=1b
        endif
        if ((trange[0] LT tr2[0]) OR (trange[1] GT tr2[1])) then begin
          loadstate=1b
        endif
        if ((trange[0] LT tr3[0]) OR (trange[1] GT tr3[1])) then begin
          loadstate=1b
        endif
        if ((trange[0] LT tr4[0]) OR (trange[1] GT tr4[1])) then begin
          loadstate=1b
        endif
     endelse
  Endif

  if (keyword_set(slp)) then begin
  endif
 
  If(loadstate) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0,  $
      text = 'Loading State data for Calibration, Probe: '+probe
    thm_load_state, probe = probe, /get_support_data, trange = trange
    tj = time_string(trange)        ;for history
    history_out = 'thm_load_state, probe = '+''''+probe+''''+$
      ', trange = ['+''''+tj[0]+''''+', '+''''+tj[1]+''''+$
      '], /get_support_data'
    If(obj_valid(progobj)) Then progobj -> update, 100.0,  $
      text = 'Finished Loading State data for Calibration, Probe: '+probe
  Endif Else history_out = ''
  Return
End
