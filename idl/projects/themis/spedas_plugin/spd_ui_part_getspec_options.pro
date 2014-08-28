

; Helper function
; Checks if input from text widget is a valid number, returns NaN if not 
; (imitates check done within spinner) 
function spd_ui_part_getspec_check_num, num

    compile_opt idl2, hidden

  if is_numeric(num,/sci) then begin
    on_ioerror, fail
    ; if we have a valid number, use calc to evaluate the expression
    calc, 'num='+num
    
    return, double(num)
    fail: return, !values.D_NAN
  endif else begin
    return,!values.D_NAN
  endelse

end


; Helper function to reset one or more widgets' value(s)
;
pro spd_ui_part_getspec_reset_widget, state, uname

    compile_opt idl2, hidden


  for i=0, n_elements(uname)-1 do begin
    id = widget_info(state.tab_id, find_by_uname=uname[i])
    
    str_element, state, uname[i], value
    
    if size(/type,value) gt 0 then begin
      widget_control, id, set_value=value
    endif else begin
      ;throw error?
    endelse
  endfor

end


; Helper function to abstract sensitization of FAC related widgets
;
pro spd_ui_part_getspec_sens_fac, top_id

    compile_opt idl2, hidden

  
  ;check status of gyro and pa buttons
  id = widget_info(top_id, find_by_uname='pa')
  pa_set = widget_info(id,/button_set)
  
  id = widget_info(top_id, find_by_uname='gyro')
  gyro_set = widget_info(id,/button_set)
  
  ;sensitize widgets accordingly
  id = widget_info(top_id, find_by_uname='fac_base')
  widget_control, id, sensitive = pa_set or gyro_set
  
  id = widget_info(top_id, find_by_uname='gyro_base')
  widget_control, id, sensitive = pa_set or gyro_set
  
  id = widget_info(top_id, find_by_uname='pa_base')
  widget_control, id, sensitive = pa_set or gyro_set
  
end



; Helper function to abstract sensitization of energy range widgets
;
pro spd_ui_part_getspec_sens_erange, top_id

    compile_opt idl2, hidden

  
  ;check selection box
  id = widget_info(top_id, find_by_uname='energy_button')
  limit_energy = widget_info(id, /button_set)

  ;sensitze widgets accordingly
  id = widget_info(top_id, find_by_uname='energy_min')
  widget_control, id, sensitive = limit_energy
  
  id = widget_info(top_id, find_by_uname='energy_max')
  widget_control, id, sensitive = limit_energy

end


;+ 
; Purpose:
; Helper function to check if strings from user input 
; contain valid numbers.
;  -returns 1 if widget contains a valid number, 0 otherwise
;  -if the input is invalid or out of range then a pop-up
;   message will be generated to notify the user
; 
; Arguments:
;   state: state data structure
;   uname: uname of the widget to check
;   namestring: string used to indentify quantity in the 
;               error message, e.g "phi min", "maximum energy"
; 
; Keywords (optional):
;   min: the minimum valid value for the quantity in question
;   max: the maximum valid value for the quantity in question
;   value: set to names keyword to return the numeric value
;          of the widget
;
;-
function spd_ui_part_getspec_check_input, state, uname, namestring, $
                                          min=min, max=max, value=value

    compile_opt idl2, hidden

  tlb = state.tab_id
  
  ;get value
  id = widget_info(tlb, find_by_uname=uname)

  widget_control, id, get_value=value
  
  ;convert to numerical if string is passed in
  if size(/type,value) eq 7 then begin
    value = spd_ui_part_getspec_check_num(value)
  endif
  
  ;if number is valid check against min & max values
  if finite(value,/nan) then begin
    msg = 'Invalid '+strlowcase(namestring)+' entered; value reset.'
  endif else if size(/type,min) gt 0 && value lt min then begin
    msg = namestring+' must be greater than or equal to ' + $
                      strtrim(string(min),1) + '; value reset.'
  endif else if size(/type,max) gt 0 && value gt max then begin
    msg = namestring+' must be less than or equal to ' + $
                      strtrim(string(min),1) + '; value reset.'
  endif else begin
    ;if we made it here then we're good to go
    return, 1
  endelse

  ;report an issues with input
  x=dialog_message(msg,/center)
  
  ;return previous (valid) value if requested
  ;this will ensure a valid value is always passed back
  if arg_present(value) then begin
    str_element, state, uname, value
  endif
  
  return, 0

end



; Helper function to copy a widget's value into the 
; appropriate variable
;
pro spd_ui_part_getspec_set_value, state, uname

    compile_opt idl2, hidden


  for i=0, n_elements(uname)-1 do begin
    id = widget_info(state.tab_id, find_by_uname=uname[i])
    
    widget_control, id, get_value=value
    
    ;strings from widget_control are often single-element arrays
    if n_elements(value) eq 1 then value=value[0]
    
    str_element, state, uname[i], value, /add
  endfor
  
end



; Helper procedure to be called when ready to load spectra.
;  -This procedure will check the applicable widgets for 
;    valid input and stores valid entries.
;  -If the input is invalid the widgets will be reset
;   
pro spd_ui_part_getspec_set_values, state

    compile_opt idl2, hidden

  tlb = state.tab_id

  ;Check phi input
  ; first check in inputs are valid, min > max allowed
  a0 = spd_ui_part_getspec_check_input(state,'phi_min','Phi min',min=0,max=360,value=pmin)
  a1 = spd_ui_part_getspec_check_input(state,'phi_max','Phi max',min=0,max=360,value=pmax)
  if ~a0 || ~a1 then begin
    spd_ui_part_getspec_reset_widget, state,['phi_min','phi_max']
  endif else begin
    spd_ui_part_getspec_set_value, state, ['phi_min','phi_max']
  endelse


  ;check start angle
  a3 = spd_ui_part_getspec_check_input(state,'start_angle','Start angle',value=sa)
  if a3 then begin
    spd_ui_part_getspec_set_value, state, 'start_angle'
  endif else begin
    spd_ui_part_getspec_reset_widget, state, 'start_angle'
  endelse


  ;check theta input
  a0 = spd_ui_part_getspec_check_input(state,'theta_min','Theta min',min=-90,max=90,value=tmin)
  a1 = spd_ui_part_getspec_check_input(state,'theta_max','Theta max',min=-90,max=90,value=tmax)
  if ~a0 || ~a1 || tmin ge tmax then begin
    if a0 && a1 && tmin ge tmax then x=dialog_message('Theta minimum must be less than maximum; values reset.',/center)
    spd_ui_part_getspec_reset_widget, state,['theta_min','theta_max']
  endif else begin
    spd_ui_part_getspec_set_value, state, ['theta_min','theta_max']
  endelse


  ;check pitch angle input
  a0 = spd_ui_part_getspec_check_input(state,'pa_min','Pitch Angle min',min=0,max=180,value=pamin)
  a1 = spd_ui_part_getspec_check_input(state,'pa_max','Pitch Angle max',min=0,max=180,value=pamax)
  if ~a0 || ~a1 || pamin ge pamax then begin
    if a0 && a1 && pamin ge pamax then x=dialog_message('Pitch angle minimum must be less than maximum; values reset.',/center)
    spd_ui_part_getspec_reset_widget, state,['pa_min','pa_max']
  endif else begin
    spd_ui_part_getspec_set_value, state, ['pa_min','pa_max']
  endelse


  ;check gyrovelocity input
  a0 = spd_ui_part_getspec_check_input(state,'gyro_min','Gyrovelocity min',min=0,max=360,value=gvmin)
  a1 = spd_ui_part_getspec_check_input(state,'gyro_max','Gyrovelocity max',min=0,max=360,value=gvmax)
  if ~a0 || ~a1 || gvmin ge gvmax then begin
    if a0 && a1 && gvmin ge gvmax then x=dialog_message('Gyrovelocity minimum must be less than maximum; values reset.',/center)
    spd_ui_part_getspec_reset_widget, state,['gyro_min','gyro_max']
  endif else begin
    spd_ui_part_getspec_set_value, state, ['gyro_min','gyro_max']
  endelse


  ;check energy limit input if option is selected
  id = widget_info(state.tab_id, find_by_uname='energy_button')
  if widget_info(id, /button_set) then begin
    e0 = spd_ui_part_getspec_check_input(state,'energy_min','Energy min',min=0,value=emin)
    e1 = spd_ui_part_getspec_check_input(state,'energy_max','Energy max',min=0,value=emax)
    if ~e0 || ~e1 || emin ge emax then begin
      if e0 && e1 && emin ge emax then x=dialog_message('Phi minimun must be less than maximum; values reset.',/center)
      spd_ui_part_getspec_reset_widget, state,['energy_min','energy_max']
    endif else begin
      spd_ui_part_getspec_set_value, state, ['energy_min','energy_max']
    endelse
  endif


  ;check regrid input
  r0 = spd_ui_part_getspec_check_input(state,'regrid_phi','Regrid dimension (long)',min=4)
  r1 = spd_ui_part_getspec_check_input(state,'regrid_theta','Regrid dimension (lat)',min=2)
  if r0 then begin
    spd_ui_part_getspec_set_value, state, 'regrid_phi'
  endif else begin
    spd_ui_part_getspec_reset_widget, state, 'regrid_phi'
  endelse
  if r1 then begin
    spd_ui_part_getspec_set_value, state, 'regrid_theta'
  endif else begin
    spd_ui_part_getspec_reset_widget, state, 'regrid_theta'
  endelse  


  ;set suffix
  ;anything can be a suffix, as long as there are no spaces
  id = widget_info(state.tab_id, find_by_uname='suffix')
  widget_control, id, get_value = suffix
  state.suffix = strcompress(/remove_all, suffix)
  
  
  ;set SST contamination removal option
  id = widget_info(state.tab_id, find_by_uname='sst_method_clean')
  state.sst_method_clean = widget_info(id, /button_set)
  
  
  ;set output types
  types = state.validoutputs
  for i=0, n_elements(types)-1 do begin
    id = widget_info(state.tab_id, find_by_uname=types[i])
    if widget_info(id, /button_set) then outputs = array_concat(types[i],outputs)
  endfor
  ;leave blank string to denote no selection
  ;must use str_element to change the number of elements in the state variable
  str_element, state, 'outputs', keyword_set(outputs) ? outputs:'', /add_replace


end


; Helper function
;-------------------------------------------------------------
;  -Sets all widget to their default states/values
;  -Called on startup and upon user requested options reset
;
pro spd_ui_part_getspec_set_defaults, state

  compile_opt idl2, hidden


  ;-------------------------------------------------------
  ; Set defaults
  ;-------------------------------------------------------

  ;Set values in state structure
  ;  -most widgets will be updated by checking the
  ;   associated value stored in the state structure
  state.suffix = ''
  str_element, state, 'outputs', ['phi','theta','energy'], /add_replace
  state.phi_min = 0.
  state.phi_max = 360.
  state.theta_min = -90.
  state.theta_max =  90.
  state.pa_min =   0.
  state.pa_max = 180.
  state.gyro_min =   0.
  state.gyro_max = 360.
  state.start_angle = 0.
  state.energy_min = 0.
  state.energy_max = 1e7
  state.regrid_phi =  16
  state.regrid_theta = 8
  state.sst_method_clean = 0b
  
  ;clear probe and data type selections
  ;  -only works once the widget it realized
  if widget_info(state.probelist, /realized) then begin
    widget_control, state.probeList , set_list_select=-1
    widget_control, state.dataTypeList, set_list_select=-1
  endif

  ;erange limits off by default
  id=widget_info(state.tab_id, find_by_uname='energy_button')
  widget_control, id, set_button=0

  ;set FAC conversion to default
  id=widget_info(state.tab_id, find_by_uname='fac_type')
  widget_control, id, set_combobox_select=0
  
  
  ;-------------------------------------------------------
  ; Update Widgets
  ;   -no defaults set in this section, only widget updates
  ;-------------------------------------------------------
  
  ;list of widgets than can be set/reset with general procedure
  widget_list = [ 'phi_min', 'phi_max', 'theta_min', 'theta_max', $
                  'pa_min', 'pa_max', 'gyro_min', 'gyro_max', $
                  'start_angle', 'energy_min', 'energy_max', $
                  'regrid_phi', 'regrid_theta', 'suffix' $
                 ]
  
  ;update applicable widgets from state structures values
  spd_ui_part_getspec_reset_widget, state, widget_list
  
  ;update spectrogram selection buttons
  for i=0, n_elements(state.validOutputs)-1 do begin
    id=widget_info(state.tab_id, find_by_uname=state.validoutputs[i])
    widget_control, id, set_button = in_set(state.validoutputs[i],state.outputs)
  endfor
  
  ;update SST contamination removal button
  id=widget_info(state.tab_id, find_by_uname='sst_method_clean')
  widget_control, id, set_button = state.sst_method_clean
  
  ;sensitize/desensitize FAC options
  spd_ui_part_getspec_sens_fac, state.tab_id

  ;sensitize/desensitize energy range options
  spd_ui_part_getspec_sens_erange, state.tab_id
  
  
  spd_ui_message, 'Using default spectrogram settings.', sb=state.statusbar, hw=state.historywin

end


; Helper function
;----------------------------------------------------------
;  -Takes the current settings and calls the lower level
;   spectrogram generation routine.
;
pro spd_ui_part_getspec_apply, state, error=error

    compile_opt idl2, hidden

  error = 1
  
  widget_control, /hourglass
  
  sb = state.statusbar
  hw = state.historywin
  

  ;check/get probe
  probe_idx = widget_info(state.probeList,/list_select)
  if probe_idx[0] eq -1 then begin
    spd_ui_message, 'Please select a probe.', sb=sb
    return
  endif
  
  if in_set(probe_idx,0) then begin
    probe = state.validProbes[1:n_elements(state.validProbes)-1]
  endif else begin
    probe = state.validProbes[probe_idx]
  endelse


  ;check/get data type
  data_idx = widget_info(state.dataTypeList,/list_select)
  if data_idx[0] eq -1 then begin
    spd_ui_message, 'Please select a datatype.', sb=sb
    return
  endif
  
  
  ;notify if no outputs have been selected
  for i=0, n_elements(state.validOutputs)-1 do begin
    id = widget_info(state.tab_id, find_by_uname=state.validOutputs[i])
    if widget_info(id, /button_set) then outputs_set = 1b
  endfor
  if ~keyword_set(outputs_set) then begin
    spd_ui_message, 'Please select one or more output types.', sb=sb
    return
  endif

  
  ;check/get time range
  state.tr->getproperty, starttime=start_obj
  state.tr->getproperty, endtime=stop_obj
  start_obj->getProperty,tstring=startText
  stop_obj->getProperty,tstring=stopText
  trange = time_double([startText, stopText])
  
  ;check that start and end times are not out of order/equal
  if trange[0] ge trange[1] then begin
    spd_ui_message, 'Error: End time less than/equal to Start time.', sb=sb
    return
  endif
  
  ;check that start and end times are not in the future
  if (trange[0] gt systime(/sec)) AND (trange[1] gt systime(/sec)) then begin
    spd_ui_message, "Error: Start and end times are later than today's date. ", sb=sb
    return
  endif


  ;Check editable widget values and copy into appropriate variables
  ;in the state structure.  Widgets with invalid entries will be reset
  ;with the last applied value.
  spd_ui_part_getspec_set_values, state


  ;get current tplot names so that extra varaibles can be cleaned later
  tnames_before = tnames('*',create_time=ct)

  
  ;check in new SST calibrations are requested
  sst_cal_id=widget_info(state.tab_id, find_by_uname='SST_CALIBRATE')
  sst_cal=widget_info(sst_cal_id,/button_set)
  
  ;list of acceptable data types is different if user is using new SST calibrations
  if sst_cal then begin
    if in_set(data_idx,0) then begin
      datatype = state.validBetatypes[1:n_elements(state.validBetatypes)-1]
    endif else begin
      datatype = state.validBetatypes[data_idx]
    endelse
  endif else begin
    if in_set(data_idx,0) then begin
      datatype = state.validDatatypes[1:n_elements(state.validDatatypes)-1]
    endif else begin
      datatype = state.validDatatypes[data_idx]
    endelse
  endelse


  ;get status of energy limit selection
  ; -energy limits will only be applied if the button is set
  id = widget_info(state.tab_id, find_by_uname='energy_button')
  limit_energy = widget_info(id, /button_set)


  ;copy options out of state structure
  ; -numerical values have already been checked
  trange = time_double([startText, stopText])
  outputs = state.outputs
  suffix = state.suffix
  phi = [state.phi_min, state.phi_max]
  theta = [state.theta_min, state.theta_max]
  pitch = [state.pa_min, state.pa_max]
  gyro = [state.gyro_min, state.gyro_max]
  energy = limit_energy ? [state.energy_min, state.energy_max]:0
  start_angle = state.start_angle
  regrid = [state.regrid_phi,state.regrid_theta]
  fac_type = strlowcase(state.fac_type)
  sst_method_clean = state.sst_method_clean
    
  
  var_success = 1b  ;flag denoting whether all requested variables were imported
  clobber = ''      ;used later to determine if existing variables should be overwritten
  
  
  ;Loop over probe
  for k=0, n_elements(probe)-1 do begin
  
  
    ;Load support data for this probe
    ;  -support data only needed for FAC transformations
    if in_set('pa',outputs) or in_set('gyro',outputs) then begin
      thm_load_state, probe=probe[k], trange=trange, /get_support
      thm_load_fit, probe=probe[k], trange=trange, datatype='fgs', level='l1', coord='dsl'
    endif
  
  
    ;Loop over data type
    for j=0, n_elements(datatype)-1 do begin
    
      spd_ui_message, 'Processing Probe: '+probe[k]+',  Datatype: '+datatype[j], sb=sb, hw=hw
    
    
      ; Check for duplicate variable names before processing 
      ; and modify the requested outputs accordingly.
      ;----------------------------------------------------
    
      ;names of existing variables in gui
      existing_names = state.loadedData->getGroupNames()
      if ~is_string(existing_names) then existing_names = '' ;can return 0
      
      ;names of new variables to be created here
      new_names = 'th'+probe[k]+'_'+datatype[j]+'_eflux'+'_'+outputs+suffix
    
      output_flags = replicate(1b,n_elements(outputs))
    
      ;loop over requested variable names to check if any
      ;GUI variables will be overwritten
      for i=0, n_elements(new_names)-1 do begin
      
        ;query the user if the variable already exists
        if in_set(new_names[i], existing_names) then begin
        
          ;only query if neither "yes to all" nor "no to all" have been selected
          if clobber ne 'yestoall' AND clobber ne 'notoall' then begin
    
            prompttext = 'The variable ' + strupcase(new_names[i]) + $
                ' already exists. Do you want to ' + 'overwrite it?'+ $
                ' Click "No" continue with the existing variable or "Cancel" to stop.'
            clobber = spd_ui_prompt_widget(state.tab_id, sb, hw, promptText=promptText,$
                title='Variable already exists.', defaultvalue='cancel', $
                /no, /yes, /allno, /allyes, /cancel, frame_attr=8)
            
            ;re-initialize hourglass after prompt widget has been called
            widget_control, /hourglass
            
          endif
            
          if clobber eq 'yestoall' then break  ;loads all by default
          if clobber eq 'no' then output_flags[i] = 0b
          if clobber eq 'notoall' then begin ;
            output_flags[*] = 0b
            break
          endif
          
          if clobber eq 'cancel' then begin
            spd_ui_message, 'Load canceled by user.', sb=sb, hw=hw
            return
          endif
          
        endif
        
      endfor
  
      ;remove data types that are not desired
      output_idx = where(output_flags,nout)
      if nout eq 0 then begin
        continue
      endif else begin
        outputs = outputs[output_idx]
      endelse
      
      
      ; Load data & generate spectrograms
      ;----------------------------------
      
      thm_part_load, probe=probe[k], datatype=datatype[j], trange=trange, sst_cal=sst_cal
      
  
      thm_part_products, probe = probe[k], $
                      datatype = datatype[j], $
                      trange = trange, $
                      outputs = outputs, $
                      phi = phi, $
                      theta = theta, $
                      pitch = pitch, $
                      gyro = gyro, $
                      energy = energy, $
                      regrid = regrid, $
                      start_angle = start_angle, $
                      suffix = suffix, $
                      fac_type = fac_type, $
                      sst_method_clean = sst_method_clean, $
                      sst_cal=sst_cal, $
                      tplotnames=tplotnames
        
      
      ; Add new variables to the GUI
      ;---------------------------------
      
      add_replay_call = 0b ;flag to add this run to the call sequence
      
      ;if all data from this run loaded fine then add this call to the call sequence
      ;if any data failed notify user and do not add this call to the call sequence
      for i=0, n_elements(tplotnames)-1 do begin
        success = state.loadeddata->add(tplotnames[i])
        if success then begin
          spd_ui_message, 'Added Variable: '+tplotnames[i], sb=sb, hw=hw
          add_replay_call = 1b
        endif else begin
          spd_ui_message, 'Failed to Add Variable: '+tplotnames[i], sb=sb, hw=hw
          var_success = 0b
        endelse
      endfor
  
  
      ; Add replay call for GUI docs
      ;---------------------------------
      if add_replay_call then begin
        state.callSequence->addGetSpecOp,probe[k], datatype[j], trange,$
            start_angle, suffix, outputs, phi, theta, pitch, gyro, energy, $
            regrid, fac_type, sst_cal, sst_method_clean
      endif


    endfor
  endfor


  ;Remove tplot variables created in this routine
  ;  -this will only remove new variables, not modified variables 
  ;----------------------------------------------
  spd_ui_cleanup_tplot, tnames_before, create_time_before=ct, new_vars=new_vars, del_vars=del_vars

  ;use 'new_vars' to also remove modified tplot variables
  if del_vars[0] ne '' then begin
    store_data, del_vars, /delete
  endif
  
  
  ; Output update messages and return
  ;----------------------------------
  if var_success Then Begin
    spd_ui_message, 'Getspec load finished.', sb=sb, hw=hw
  endif else begin
    spd_ui_message, 'Getspec load finished. Some quantities were not processed. '+ $
                    'Check History window for details.', sb=sb, hw=hw
  endelse

  error = 0
  
  return
  
end




;event handler
Pro spd_ui_part_getspec_options_event, event


  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg

    print, err_msg

    dummy = dialog_message('An unknown error occured and the window must be restarted. See console for details.', /center, _extra=_extra)
    
    if is_struct(state) then begin
      for i=0, n_elements(err_msg)-1 do begin
        spd_ui_message, err_msg[i], sb=state.statusBar, hw=state.historyWin
      endfor
    endif
    
    if widget_valid(base) then begin
      Widget_Control, base, Set_UValue=state, /No_Copy
    endif
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF


  ;ignore events from widgets without a uval
  widget_control, event.id, get_uvalue = uval
  if undefined(uval) then return
  
  ;get state structure
  base = event.handler
  widget_control, base, Get_UValue=state, /no_copy
  
  
  ;identify widget by uval and handle event
  ;-----------------------------------------------------------------------
  case uval of
  
    'energy_button': begin
      ;sensitize energy limit spinners
      spd_ui_part_getspec_sens_erange, state.tab_id
    end
    
    'fac_set': begin
      ;sensitize FAC options as needed
      spd_ui_part_getspec_sens_fac, state.tab_id
    end
    
    'CLEARDATA': begin
      widget_control, state.dataTypeList, set_list_select=-1
    end
    
    'CLEARPROBE': begin
      widget_control, state.probeList , set_list_select=-1
    end
    
    'SST_CALIBRATE':begin
      ;if beta calibrations are requested, don't let user select invalid data types.(ESA or SST reduced)
      use_new_sst_calibrations = widget_info(event.id,/button_set)
      data_type_list_id = widget_info(state.tab_id,find_by_uname='data_type_list')
      if use_new_sst_calibrations then begin
        widget_control,data_type_list_id,set_value=state.validBetaTypes
      endif else begin
        widget_control,data_type_list_id,set_value=state.validDataTypes
      endelse
    end
    
    'HELP':begin
      gethelppath,path
      xdisplayfile, path+'spd_ui_part_getspec_options.txt', group=state.tab_id, /modal, done_button='Done', $
                    title='HELP: Getspec Options'
    end
    
    'RESET':begin
      spd_ui_part_getspec_set_defaults, state
    end
    
    'APPLY':begin
      spd_ui_part_getspec_apply, state, error=error
    end
  
    else:
  
  endcase
  ;-----------------------------------------------------------------------
  
  widget_control, base, set_uvalue=state, /NO_COPY
  
  return

end




;+ 
;NAME:
;  spd_ui_part_getspec_options
; 
;PURPOSE:
;  A interface to thm_part_products.pro for creating and loading SPEDAS energy/
;  angular particle spectra into the GUI.  Intended to be called from
;  SPD_UI_INIT_LOAD_WINDOW.PRO using the SPEDAS load API.
; 
;CALLING SEQUENCE:
;  spd_ui_part_getspec_options, tab_id, loadedData, historyWin, statusBar, $
;                               treecopy, trObj, callSequence, $
;                               loadTree=loadTree, $
;                               timeWidget=timeid
;
;INPUT:
;  tab_id:  The widget id of the tab.
;  loadedData:  The loadedData object.
;  historyWin:  The history window object.
;  statusText:  The status bar object for the main Load window.
;  treeCopyPtr:  Pointer variable to a copy of the load widget tree.
;  trObj:  The GUI timerange object.
;  callSequence:  Reference to GUI call sequence object
;
;OUTPUT:
;  loadTree = The Load widget tree.
;  timeWidget = The time widget object.
;
;NOTES:
;
; 
;HISTORY:
; 5-jan-2009, jmm, jimm@ssl.berkeley.edu
; 14-jan-2009, jmm, added statusbar object
; 15-jan-2009, jmm, added external_state, so that the active data
;                   widget on the dproc panel can be updated.
; 23-jan-2009, jmm, deletes tplot variables created during processing,
;                   correctly updates active data
; 13-may-2009, bck, moved code from Data Processing window to Load window
; 16-jul-2012, aaf, rewrote error checking on input values to match the 
;                   behavior of other GUI windows
; ??-sept-2013, aaf, modified to use new spectrogram code
; 01-jul-2014, aaf, now conforms to standard SPEDAS load API
; 
; 
;$LastChangedBy: jwl $
;$LastChangedDate: 2014-07-03 15:14:01 -0700 (Thu, 03 Jul 2014) $
;$LastChangedRevision: 15508 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/spd_ui_part_getspec_options.pro $
;-
Pro spd_ui_part_getspec_options, tab_id, loadedData, historyWin, statusBar, $
                                 treecopy, trObj, callSequence, $
                                 loadTree=loadTree, $
                                 timeWidget=timeid

compile_opt idl2, hidden                       

widget_control, /hourglass

;------------------------------------------------------------------------------
;Set up initial widget bases for easier formatting
;------------------------------------------------------------------------------
mainBase = widget_base(tab_id, /col, tab_mode=1, event_pro='spd_ui_part_getspec_options_event')
  topBase = widget_base(mainBase, /row, ypad=8)
    topCol1Base =  widget_base(topBase, /col, space=4)
      instrLabelBase = widget_base(topcol1base, /row)
      instrumentBase = widget_base(topCol1Base, /col, /frame, xpad=5)
        timeBase = widget_base(instrumentBase)
        sstCalButtonBase = widget_base(instrumentBase, /col, /nonexclusive, xpad=5)
        dataBase = widget_base(instrumentBase, /row)
    topCol2Base = widget_base(topBase, /col, space=4)
      col2row1 = widget_base(topcol2base, ypad=2, /col) ;zero padding to keep tops aligned
        spec_type_label_base = widget_base(col2row1, /row, /align_left)
        spec_type_base = widget_base(col2row1, /row, /frame, ypad=6, xpad=5)
      col2row2 = widget_base(topcol2base, ypad=2, /col)
        angle_range_label_base = widget_base(col2row2, /row, /align_left)
        angle_range_base = widget_base(col2row2, /col, /frame, ypad=8, xpad=5)
      col2row3 = widget_base(topcol2base, ypad=2, /col)
        energy_range_label_base = widget_base(col2row3, /row, /align_left)
        energy_range_base = widget_base(col2row3, /col, /frame, ypad=6, xpad=5)
    topCol3Base =  widget_base(topBase, /col, space=4)
      col4row1 = widget_base(topcol3base, ypad=2, /col)
        suffixLabelBase = widget_base(col4row1,/col)
        suffixBase = widget_base(col4row1, /row, /frame, ypad=8, xpad=10)
      col3row2 = widget_base(topcol3base, ypad=2, /col)
        fac_label_base = widget_base(col3row2, /row, /align_left)
        fac_base = widget_base(col3row2, /col, /frame, ypad=8, xpad=5, uname='fac_base')
      col3row3 = widget_base(topcol3base, ypad=2, /col)
        sst_label_base = widget_base(col3row3, /row, /align_left)
        sst_base = widget_base(col3row3, /col, /frame, ypad=8, xpad=5)
      col3row4 = widget_base(topcol3base, ypad=2, /col)
        start_angle_label_base = widget_base(col3row4, /row, /align_left)
        start_angle_base = widget_base(col3row4, /col, /frame, ypad=5, xpad=5)


  buttonBase = widget_base(mainBase, /row, /align_center)
  
  ;data input options
  dataLabel = widget_label(instrLabelBase, value='Data Selection: ', /align_left)


;------------------------------------------------------------------------------
; NOTE: Default widget values and states will be handled in the helper funtion
;       spd_ui_part_getspec_set_defaults.
;       Changes to any defaults shoudl be made there.
;------------------------------------------------------------------------------

  loadtree = obj_new() ;calling function needs object passed back

;------------------------------------------------------------------------------
; Time selection
;------------------------------------------------------------------------------
  tr = trObj
  timeid = spd_ui_time_widget(timeBase,$
                              statusBar,$
                              historyWin,$
                              timeRangeObj=tr,$
                              uvalue='TIME_WIDGET',$
                              uname='time_widget')
                              
  sstButton = widget_button(sstCalButtonBase, value = 'Use Beta SST Calibrations?', $
                             uname = 'SST_CALIBRATE',UVAL='SST_CALIBRATE')


;------------------------------------------------------------------------------
; Probe selection
;------------------------------------------------------------------------------
  validProbesVisible = [' * (All)', ' A (P5)', ' B (P1)', ' C (P2)', ' D (P3)', ' E (P4)']
  validProbes = ['*', 'a', 'b', 'c', 'd', 'e']
  probeBase = Widget_Base(dataBase, /col)
  plBase = Widget_base(probeBase, /row)
  probeListBase = Widget_Base(plBase, /col)
  probeLabel = Widget_Label(probeListBase, Value='Probe: ', /align_left)
  probeList = Widget_List(probeListBase, Value=validProbesVisible, /multiple, uval='PROBE', XSize=16, YSize=11)
  probeButtonBase = Widget_Base(probeListBase, /row, /align_center)
  probeClearButton = Widget_Button(probeButtonBase, value=' Clear Probe ', uvalue='CLEARPROBE', /align_center)


;------------------------------------------------------------------------------
; Data type selection
;------------------------------------------------------------------------------

  suffix = ''
  validDataTypes = ['*', $
                    'peif', 'peir', 'peib', 'peef', 'peer', 'peeb', $
                    'psif', 'psir', 'psef', 'pser', 'pseb'] 
  validBetaTypes = ['*','psif','psef','pseb']
  
  
  dataTypeBase = Widget_Base(DataBase, /col)
  dataL1Base = Widget_Base(dataTypeBase, /col)
  dataButtonBase = Widget_Base(dataTypeBase, /col, /align_center)
  dataTypeLabel = Widget_Label(dataL1Base, Value='Data Type:', /align_left)
  dataTypeList = Widget_List(dataL1Base, Value=validDataTypes, uval='DATATYPE', $
                             uname='data_type_list',$
                         /Multiple, XSize=16, YSize=11)
  dataClearButton = Widget_Button(dataButtonBase, value=' Clear Data Type ', uvalue='CLEARDATA', /align_center)

  ;suffix
  suffixlabel = widget_label(suffixLabelBase, value = 'Variable Name: ', /align_left)
  suffixlabel = widget_label(suffixBase, value = 'Suffix: ', /align_left)
  suffixid = widget_text(suffixBase, value=suffix, xsize=22, ysize=1, uname='suffix', /editable)


;------------------------------------------------------------------------------
;Spectrogram Selection
;------------------------------------------------------------------------------
  outputs = ['phi', 'theta', 'energy']
  validOutputs = ['energy', 'phi', 'theta', 'pa', 'gyro'] 

  spec_label = widget_label(spec_type_label_base, value='Output Selection')
  
  spec_selection_base1 = widget_base(spec_type_base, /nonexclusive)
    ener_energy = widget_button(spec_selection_base1, value='Energy', uname='energy', $ 
                     tooltip='Energy spectrogram.  Averages over all look directions.')
  
  spec_selection_base2 = widget_base(spec_type_base, /nonexclusive)
    spec_phi = widget_button(spec_selection_base2, value='Phi', uname='phi', $ 
                     tooltip='Phi (longitudinal) spectrogram.  Averages over energy and theta (latitude).')
    spec_theta = widget_button(spec_selection_base2, value='Theta', uname='theta', $ 
                     tooltip='Theta (latitudinal) spectrogram. Averages over energy and phi (longitude).')
  
  spec_selection_base3 = widget_base(spec_type_base, /nonexclusive)
    spec_gyro = widget_button(spec_selection_base3, value='Gyrovelocity', uname='gyro', uval='fac_set', $ 
                     tooltip='Field aligned longitudinal spectrogram.  Averages over energy and latitude in field alligned coordinates.')
    spec_pa = widget_button(spec_selection_base3, value='Pitch Angle', uname='pa', uval='fac_set', $ 
                     tooltip='Field aligned colatitude spectrogram.  Averages over energy and longitude in field alligned coordinates.') 
  

;------------------------------------------------------------------------------
; Angle Range Limits
;------------------------------------------------------------------------------
  phi = [0,360.]
  theta = [-90,90.]
  gyro = [0,360]
  pa = [0,180]

  angle_range_label = widget_label(angle_range_label_base, value='Angular Ranges (min/max):')
  
  phi_range_base = widget_base(angle_range_base, /row)
    phi_range_label = widget_label(phi_range_base, value='Phi:  ')
    phi_min = spd_ui_spinner(phi_range_base, label='', value=phi[0], uname='phi_min', $
                     tooltip = 'Minimum phi used to calculate all outputs.')
    phi_max = spd_ui_spinner(phi_range_base, label='', value=phi[1], uname='phi_max', $
                     tooltip = 'Maximum phi used to calculate all outputs.')

  theta_range_base = widget_base(angle_range_base, /row)
    theta_range_label = widget_label(theta_range_base, value='Theta:  ')
    theta_min = spd_ui_spinner(theta_range_base, label='', value=theta[0], uname='theta_min', $
                     tooltip = 'Minimum theta used to calculate all outputs.')
    theta_max = spd_ui_spinner(theta_range_base, label='', value=theta[1], uname='theta_max', $
                     tooltip = 'Maximum theta used to calculate all outputs.')

  gyro_range_base = widget_base(angle_range_base, /row, uname='gyro_base')
    gyro_range_label = widget_label(gyro_range_base, value='Gyro:  ')
    gyro_min = spd_ui_spinner(gyro_range_base, label='', value=gyro[0], uname='gyro_min', $
                     tooltip = 'Minimum gyrovelocity used to calculate field aligned spectrograms.')
    gyro_max = spd_ui_spinner(gyro_range_base, label='', value=gyro[1], uname='gyro_max', $
                     tooltip = 'Maximum gyrovelocity used to calculate field aligned spectrograms.')

  pa_range_base = widget_base(angle_range_base, /row, uname='pa_base')
    pa_range_label = widget_label(pa_range_base, value='PA:  ')
    pa_min = spd_ui_spinner(pa_range_base, label='', value=pa[0], uname='pa_min', $
                     tooltip = 'Minimum pitch angle used to calculate field aligned spectrograms.')
    pa_max = spd_ui_spinner(pa_range_base, label='', value=pa[1], uname='pa_max',$
                     tooltip = 'Maximum gyrovelocity used to calculate field aligned spectrograms.')

  ;dynamically resize angle range labels
  geo = widget_info(theta_range_label,/geo)
    widget_control, phi_range_label, xsize = geo.scr_xsize
    widget_control, gyro_range_label, xsize = geo.scr_xsize
    widget_control, pa_range_label, xsize = geo.scr_xsize


;------------------------------------------------------------------------------
; Energy Range Limits
;------------------------------------------------------------------------------
  energy = [0,1e7]
  
  energy_range_label = widget_label(energy_range_label_base, value='Energy Range (min/max):')

  energy_range_base2 = widget_base(energy_range_base, /row, xpad=0)
    energy_range_bbase = widget_base(energy_range_base2, /nonexclusive, xpad=0, ypad=0)
      energy_range_button = widget_button(energy_range_bbase, value='Energy (eV):', $
                    uname='energy_button', uval='energy_button', $
                    tooltip='Limit the energy range used to calculate all spectrograms.')
    energy_min = spd_ui_spinner(energy_range_base2, label='', value=energy[0], uname='energy_min', $
                    tooltip = 'Minimum energy used to calculate all outputs.', inc=100)
    energy_max = spd_ui_spinner(energy_range_base2, label='', value=energy[1], uname='energy_max', $
                    tooltip = 'Maximum energy used to calculate all outputs.', inc=100)
    
    
;------------------------------------------------------------------------------
; Start Angle
;------------------------------------------------------------------------------
  phi_start = 0.
  
  start_angle_label = widget_label(start_angle_label_base, value='Phi/Gyro Start Angle: ')
  
  start_angle_base2 = widget_base(start_angle_base, /row, xpad=0)
    start_angle = spd_ui_spinner(start_angle_base2, label='Start plot at (degrees): ', $
                      value=phi_start, incr=5,  uname='start_angle', $
                      tooltip='Start phi and gyrovelocity y axes at this value.')
  
  
;------------------------------------------------------------------------------
; FAC Options
;------------------------------------------------------------------------------
  regrid = [16,8.]
  facs =  ['MPHIGEO', 'PHIGEO', 'MPHISM', 'PHISM', 'MRGEO', 'RGEO', 'XGSE', 'YGSM']

  fac_label = widget_label(fac_label_base, value='Field Aligned Coordinates:')
  
  regrid_base = widget_base(fac_base, /row)
    regrid_label = widget_label(regrid_base, value='Bin Num (long,lat):  ')
    regrid_phi = spd_ui_spinner(regrid_base, value=regrid[0], incr=2, label='', text_box_size=4, $
                 uname='regrid_phi', tooltip='Number of bins across rphi (field aligned longitude).')
    regrid_theta = spd_ui_spinner(regrid_base, value=regrid[1], incr=2, label='', text_box_size=4, $
                 uname='regrid_theta', tooltip='Number of bins across rtheta (field aligned longitude).')
  
  coord_base = widget_base(fac_base, /row)
    coord_label = widget_label(coord_base, value='FAC Variant:  ')
    coord_list = widget_combobox(coord_base, value=facs, uname='fac_type')
  

;------------------------------------------------------------------------------
; SST Contamination
;------------------------------------------------------------------------------

  sst_method_clean = 0b

  sst_label = widget_label(sst_label_base, value='SST Contamination:')
  
  sst_cont_button_base = widget_base(sst_base, /nonexclusive,/col)
    sst_cont_button = widget_button(sst_cont_button_base, $
                      value='Mask Default Bins', uname='sst_method_clean', $ 
                      tooltip='Mast the default set of contaminated SST bins.')  


;------------------------------------------------------------------------------
; Main Buttons
;------------------------------------------------------------------------------

  apply_button = Widget_Button(buttonBase, Value = '    Apply    ', XSize = 70, $
                               UValue = 'APPLY', tooltip='Create particle spectra from active data')
  resetButton = Widget_Button(buttonBase, value='Reset All', uvalue='RESET', $
                              tooltip='Reset all settings to their default values.')
  helpButton = Widget_Button(buttonBase, Value='Help', XSize=70, UValue='HELP', $
                              tooltip='Open Help Window.')


;------------------------------------------------------------------------------
; Widget formatting
;------------------------------------------------------------------------------

  ;dynamically resize the second column's framed bases
  geo = widget_info(energy_range_base,/geo)
    widget_control, spec_type_base, xsize=geo.scr_xsize
    widget_control, angle_range_base, xsize=geo.scr_xsize

  ;dynamically resize the third column's framed bases
  geo = widget_info(fac_base,/geo)
    widget_control, sst_base, xsize=geo.scr_xsize
    widget_control, start_angle_base, xsize=geo.scr_xsize
    widget_control, suffixbase, xsize=geo.scr_xsize


;------------------------------------------------------------------------------
; Set state, initialize widgets, and realize
;------------------------------------------------------------------------------


state = {tab_id:tab_id, $
        
        ; GUI objects & variables
         loadedData:loadedData, historyWin:historyWin, callSequence:callSequence, $ 
         statusBar:statusBar, probeList:probeList, tr:tr, $
        
        ; Widgets
         dataTypeList:dataTypeList, $
         probeClearButton:probeClearButton, $
         dataClearButton:dataClearButton, $
        
        ; Widget support variables (lists etc)
         validProbes:validProbes, $
         validDataTypes:validDataTypes, $
         validBetaTypes:validBetaTypes, $
         validOutputs:validOutputs, $
        
        ; Stored Options (to be passed to thm_part_getspec)
         phi_min:phi[0], phi_max:phi[0], $
         theta_min:theta[0], theta_max:theta[1], $
         pa_min:pa[0], pa_max:pa[1], $
         gyro_min:gyro[0], gyro_max:gyro[1], $
         energy_min:energy[0], energy_max:energy[1], $
         outputs:outputs, $
         start_angle:start_angle, $
         regrid_phi:regrid[0], regrid_theta:regrid[1], $
         fac_type:facs[0],  $         
         sst_method_clean:sst_method_clean, $
         suffix:suffix $
         }


;Set widget values and states
spd_ui_part_getspec_set_defaults, state


widget_control, widget_info(tab_id, /child), set_uvalue=state, /no_copy

Return
End
