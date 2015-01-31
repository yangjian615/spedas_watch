;+ 
;NAME:
; spd_ui_dproc
;PURPOSE:
; handles data processing requests
;CALLING SEQUENCE:
; spd_ui_dproc, info, uval
;INPUT:
; info = the info structure for the calling widget, the loadeddata
;        object, statusbar object and historywin object need to have
;        been initialized.
; uval = the string value for the data processing task that is to be
;        done. Good values are:  ['subavg', 'submed', 'smooth', 'blkavg',
;        'clip','deflag','degap','spike','deriv','pwrspc','wave',
;        'hpfilt']
;KEYWORDS:
; ext_statusbar = the default is to output messages to the main GUI
;                 statusbar. If ext_statusbar is a valid object, then
;                 updates go here
; group_leader = the calling widget id, the default is to use the main
;                GUI
; ptree = pointer to copy data tree
;
;OUTPUT:
; Returns 1 for successful output, 0 for unsuccessful, otherwise, 
; tasks are preformed, active data are updated, messages are updated.
; 
;NOTES:
;  If you add any operations,  be sure to put code in place
;  so that we can recall the operation when a spedas document is loaded without data.
;
;
;HISTORY:
; 20-oct-2008, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-01-27 12:45:00 -0800 (Tue, 27 Jan 2015) $
;$LastChangedRevision: 16755 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_dproc.pro $


;This routine simplifies some of the recall code
function call_dproc, dp_task, dp_pars, names_out = names_out, no_setactive = no_setactive, $
                     hwin = hwin, sbar = sbar, call_sequence=call_sequence,$
                     loadedData=loadedData,gui_id = gui_id, dpr_extra = _extra

  compile_opt idl2,hidden

  ;First get the active data names:
  in_vars = loadedData->getactive(/parent) ;all you want is parents
  If(is_string(in_vars) Eq 0) Then Begin
      hwin -> update, 'No active data, Returning'
      sbar -> update, 'No active data, Returning'
      Return, otp
  Endif
  
  otp = loadedData->dproc(dp_task, dp_pars,callSequence=call_sequence, names_out = names_out, in_vars=in_vars, $
                   no_setactive = no_setactive, hwin = hwin, sbar = sbar, gui_id = gui_id)
   
  return,otp

end


Function spd_ui_dproc, info, uval, $
                           group_leader = group_leader, ext_statusbar = ext_statusbar, $
                           ptree = ptree


;Initialize output
  otp = 0b

  err0 = 0
  catch, err0
  If(err0 Ne 0) Then Begin
    catch, /cancel
    ok = error_message(traceback = 1, /noname, title = 'Error in Data Processing: ')
    Return, 0b
  Endif

;Fall hard if the info structure doesn't exist here
  If(is_struct(info) Eq 0) Then message, 'Invalid info structure?'

  uv0 = ['subavg', 'submed', 'smooth', 'blkavg', 'clip', 'deflag', $
         'degap', 'spike', 'deriv', 'pwrspc', 'wave', 'hpfilt', $
         'interpol','split','join']
  uvlong = ['Average subtraction', 'Median subtraction', $
            'Time smoothing', 'Block average', 'Clip', 'Deflag', $
            'Degap', 'De-spike', 'Time derivative', $
            'Dynamic Power spectrum', 'Wavelet transform', $
            'High-pass filter', 'Interpolate']

  hwin = info.historywin
  If(obj_valid(ext_statusbar)) Then sbar = ext_statusbar $
  Else sbar = info.statusbar
;This is not likely to happen,
  If(is_string(uval) Eq 0) Then Begin
    msg = 'SPD_UI_DPROC: No user value.'
    sbar -> update, msg
    info.historywin -> update, msg
    Return, otp
  Endif

  uv = strcompress(/remove_all, strlowcase(uval))

;This is not likely to happen, either
  is_possible = where(uv0 Eq uv)
  If(is_possible[0] Eq -1) Then Begin
    msg = 'SPD_UI_DPROC: Invalid user value: '+uval
    sbar -> update, msg
    info.historywin -> update, msg
    Return, otp
  Endif

  info.windowStorage->getProperty,callSequence=call_sequence

  ;Get active data
  active_data = info.loadedData->getactive(/parent)

  if ~is_string(active_data[0]) then begin
    message = 'No active data.  Returning to Data Processing window.'
    sBar->update, message
    info.historyWin->update, 'SPD_UI_DPROC: ' + message
    return,''
  endif

  If(keyword_set(group_leader)) Then guiid = group_leader[0] Else guiid = info.master
;Long case statement

  Case uv Of
    'split':begin
      otp = call_dproc(uv, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
    end
    'join':begin
      values = spd_ui_join_variables_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv, values,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif
    end
    'subavg': otp = call_dproc(uv,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
    'submed': otp = call_dproc(uv,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
    'deriv': begin
      values = spd_ui_time_derivative_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv, values,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else sbar->update,'Time derivative canceled'
    end
    'spike': begin
      values = spd_ui_clean_spikes_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv, values,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else sbar->update,'Clean Spikes canceled'
    end
    'pwrspc': Begin
      overwrite_selections = 0
      popt = spd_ui_pwrspc_options(guiid, info.loadtr, info.historywin, sbar)
      if popt.success eq 0 then return,''
    
      ;Get active data
      active_data = info.loadedData->getactive(/parent)
    
      if ~is_string(active_data[0]) then begin
        message = 'No active data.  Returning to Data Processing window.'
        sBar->update, message
        info.historyWin->update, 'SPD_UI_PWRSPC: ' + message
        return,''
      endif

      spd_ui_pwrspc, popt, active_data, info.loadedData, info.historywin, $
                         sbar, guiId, fail=fail, overwrite_selections = overwrite_selections
      if ~keyword_set(fail) then begin
        call_sequence->addPwrSpecOp,popt,active_data,overwrite_selections
      endif
    End
    'smooth': Begin
;      opar = obj_new('spd_ui_dproc_par', dp_string = uv, $
;                     dp_struct = {plabel:'Smoothing Resolution (sec)', $
;                                  pvalue:'61'})
;      smooth_res = spd_ui_dproc_par_choose(opar, gui_id = guiid, $
;                                           title = 'Choose Smoothing Time Resolution')
;      obj_destroy, opar
      values = spd_ui_smooth_data_options(guiid, sbar, info.historywin)
      If ~values.ok Then Begin ;check par values
        msg = 'Operation Cancelled: '+uvlong[is_possible]
        sbar -> update, msg
        hwin -> update, msg
      Endif Else Begin
        otp = call_dproc(uv, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      Endelse
    End
    'blkavg': Begin

      datap = ptr_new(info.loadeddata)
      values = spd_ui_block_ave_options(guiid, sbar, info.historywin, datap)

      if values.ok then begin
        if obj_valid(values.trange) then str_element,values,'trange', $
          [values.trange->getStartTime(),values.trange->getEndTime()],/add_replace
        otp = call_dproc(uv, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else sbar->update,'Block Average Canceled'

    End
    'clip':Begin

      values = spd_ui_clip_data_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv,values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else sbar->update,'Clip Data Canceled'
    End

    'deflag': Begin

      values = spd_ui_deflag_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else sbar->update,'Deflag Canceled'
    End

    'degap':Begin

      values = spd_ui_degap_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else sbar->update,'Degap Canceled'
    End
    'wave':Begin
    
      ;get time range from active data if possible
      active_data = info.loadedData->getactive()
      for i=0, n_elements(active_data)-1 do begin
        info.loadeddata->getvardata, name=active_data[i], trange=tr0
        if obj_valid(tr0) then break
      endfor
      
      ;use store time range otherwise
      if ~obj_valid(tr0) then tr0 = info.loadtr

      tr = [tr0->getstarttime(),tr0->getendtime()]
      
      plabel = ['Start Time:', 'Stop Time: ', 'Max # of Samples']
      pvalue = [time_string(tr),strtrim(2l^15,2)] ;uses default maxpoints from wav_data.pro
      opar = obj_new('spd_ui_dproc_par', dp_string = uv, $
                     dp_struct = {pvalue:pvalue, plabel:plabel})
      trange0 = spd_ui_dproc_par_choose(opar, gui_id = guiid, $
                                        par_pad = 2, label_xsize = 100, $
                                        title =  'Wavelet Transform Time Range', $
                                        bottomlabel = 'Format: yyyy-mm-dd/hh:mm:ss')

      obj_destroy, opar
      
      msg = ''
      If(trange0[0] Eq 'Cancelled') Then Begin
        msg = 'Operation Cancelled: '+uvlong[is_possible]
        hwin -> update, msg
        sbar -> update, msg
      Endif Else Begin
      
        ; 'trange0' should be an array with 3 elements: 1) start time, 2) end time, 3) max # of samples
        if n_elements(trange0) ne 3 then begin
            wavelet_err_msg = 'Error calculating wavelet transform, missing some parameters. Did you leave a textbox in the wavelet panel empty?'
            hwin->update, wavelet_err_msg
            sbar->update, wavelet_err_msg
            break
        endif 
        
        t00 = spd_ui_timefix(trange0[0])
        If(is_string(t00)) Then Begin
            t00x = time_double(t00)
        Endif Else Begin
            msg = 'Invalid Start Time: "' + trange0[0] + '"'
        Endelse

        t01 = spd_ui_timefix(trange0[1])
        If(is_string(t01)) Then Begin
            t01x = time_double(t01)
        Endif Else Begin
            msg = 'Invalid End Time: "' + trange0[1] + '"'
        Endelse
        
        if msg eq '' then begin
          trange = [t00x, t01x]
          If(trange[0] Le 0) Then Begin
            msg = 'Invalid Start Time: "' + trange0[0] + '"'
          Endif Else If(trange[1] Le 0) Then Begin
            msg = 'Invalid End Time: "' + trange0[1] + '"'
          Endif Else If(trange[0] Ge trange[1]) Then Begin
            msg = 'Start Time: '+trange0[0]+' is GE End Time: '+trange0[1]
          endif else if ~is_numeric(trange0[2]) then begin
            msg = 'Invalid Max # of Samples: "' + trange0[2] + '"'
          endif else begin
            otp = call_dproc(uv,{trange:trange,maxpoints:float(trange0[2])} , hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)  
          Endelse
        endif
        
        if msg ne '' then begin
          ok = dialog_message(msg,/center,title='Error Initializing Wavelet: ')
          hwin -> update, msg
          sbar -> update, msg
        endif
      Endelse
      
    End
    'hpfilt':Begin

      values = spd_ui_high_pass_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(uv, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else begin
        msg = 'High Pass Filter Canceled'
        sbar -> update, msg
        hwin -> update, msg
      endelse
    End
    'interpol':Begin

      datap = ptr_new(info.loadeddata)

      ;get interpolate options
      result = spd_ui_interpol_options(guiid,info.historywin, sbar, datap, ptree = ptree)

      if is_struct(result) then begin
      
        if result.ok then begin
         
          ;Get active data
          active_data = info.loadedData->getactive(/parent)

          if ~is_string(active_data[0]) then begin
          
            msg = 'Interpolate: No active data.  Returned to Data Processing window.'
            sbar -> update, msg
            hwin -> update, msg

          endif else begin

            ;easier to serialize array than object
            if obj_valid(result.trange) then str_element,result,'trange', $
              [result.trange->getStartTime(),result.trange->getEndTime()],/add_replace
            
          
            spd_ui_interpolate, result,active_data, info.loadedData, info.historywin, $
                                              sbar, fail=fail, guiid=guiid, cadence_selections=cadence_selections,$
                                              overwrite_selections=overwrite_selections
            if fail eq 0 then begin
              call_sequence->addInterpOp,result,active_data,cadence_selections,overwrite_selections
            endif
          endelse
                                              
        endif
      endif

    End
  Endcase

;Update the draw object to refresh any plots
info.drawobject->update, info.windowstorage, info.loadeddata
info.drawobject->draw
info.scrollbar->update

Return, otp

End

