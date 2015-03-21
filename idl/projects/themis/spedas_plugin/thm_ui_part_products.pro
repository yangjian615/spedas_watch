
; Helper function to load combined distribution data
;
pro thm_ui_part_products_getcombined, probe=probe, $
                                      datatype=datatype, $
                                      trange=trange, $

                                      data_out = data_out, $
                                      error = error, $

                                      use_eclipse_corrections=use_eclipse_corrections, $

                                      esa_bgnd_remove=esa_bgnd_remove, $
                                      bgnd_type=bgnd_type, $
                                      bgnd_npoints=bgnd_npoints, $
                                      bgnd_scale=bgnd_scale, $
                                      
                                      sst_cal=sst_cal


    compile_opt idl2, hidden

error = 0b

;nothing to do if datatype is invalid
if ~strmatch(datatype,'pt[ei][rfb][fb]') then begin
  return
endif

esa_datatype = 'pe'+strmid(datatype,2,2)

sst_datatype = 'ps'+strmid(datatype,2,1)+strmid(datatype,4,1)

;get combined data
data_out = thm_part_combine(probe=probe, $
                            esa_datatype=esa_datatype, $
                            sst_datatype=sst_datatype, $
                            trange=trange, $
                            
                            use_eclipse_corrections=use_eclipse_corrections, $

                            ;bgnd_remove must go through _extra
                            bgnd_remove=esa_bgnd_remove, $
                            bgnd_type=bgnd_type, $
                            bgnd_npoints=bgnd_npoints, $
                            bgnd_scale=bgnd_scale, $
                             
                            sst_cal=sst_cal)

if in_set(ptr_valid(data_out),0) then begin
  error = 1b
endif

end



;+
;Procedure:
;  thm_ui_part_products
;
;Purpose:
;  Wrapper interface between SPEDAS GUI plugin and 
;  thm_part_products and thm_part_combine.
;
;
;Input:
;  API Required:
;    loaded_data:  SPEDAS loaded data object
;    history_window:  SPEDAS history window object
;    status_bar:  SPEDAS status bar object
;
;  Unique (options not passed to particle routines):  
;    load_flags:  flag array denoting which requested probe/datatype/output
;                 combinations are to be processed (controls overwrite & replay)
;
;Output:
;  none
;
;Notes:
;  -This routine should comply with the SPEDAS plugin replay API
;  -Some particle routines pass keywords to lower level routines through _extra
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-03-19 19:25:12 -0700 (Thu, 19 Mar 2015) $
;$LastChangedRevision: 17152 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_part_products.pro $
;
;-

pro thm_ui_part_products, loaded_data=loaded_data, $
                          history_window=hw, $
                          status_bar=sb, $
                          load_flags=load_flags, $
                          
                          probe=probe, $
                          datatype=datatype, $
                          trange=trange, $
                          outputs=outputs, $
                          suffix=suffix, $

                          energy=energy, $
                          phi=phi, $
                          theta=theta, $
                          gyro=gyro, $
                          pitch=pitch, $
                          start_angle=start_angle, $

                          regrid=regrid, $
                          fac_type=fac_type, $
                          
                          use_eclipse_corrections=use_eclipse_corrections, $

                          esa_bgnd_remove=esa_bgnd_remove, $
                          bgnd_type=bgnd_type, $
                          bgnd_npoints=bgnd_npoints, $
                          bgnd_scale=bgnd_scale, $

                          sst_cal=sst_cal, $
                          sst_method_clean=sst_method_clean, $
                          
                          _extra=_extra

 
    compile_opt idl2, hidden


final_msg_suffix = ''

;get current tplot names so that extra varaibles can be cleaned later
tnames_before = tnames('*',create_time=ct)

;flags denoting if any of the requeste probe/datatype/output combinations 
;  -set load flags to 1 if not specified (i.e. load all requested data)
;  -array must be created and reformed to maintain dimensionality (IDL bug?)
;  -reform should always occur as dimensionality is lost on replay
flag_dimensions = [n_elements(probe),n_elements(datatype),n_elements(outputs)]
if undefined(load_flags) then begin
  load_flags = replicate(1b,flag_dimensions)
endif
load_flags = reform(load_flags,flag_dimensions)


;loop over probe
for k=0, n_elements(probe)-1 do begin

  ;skip probe if there are no quantities to load 
  if total(load_flags[k,*,*]) eq 0 then continue

  ;load support data for this probe (state is only need for pa & gyro)
  if in_set('pa',outputs) or in_set('gyro',outputs) or in_set('moments',outputs) then begin
    thm_load_state, probe=probe[k], trange=trange, /get_support
    thm_load_fit, probe=probe[k], trange=trange, datatype='fgs', level='l1', coord='dsl', $
                  use_eclipse_corrections=use_eclipse_corrections
  endif

  ;loop over data type
  for j=0, n_elements(datatype)-1 do begin

    output_idx = where(load_flags[k,j,*], n)

    ;skip datatype if there are no quantities to load
    if n eq 0 then continue

    spd_ui_message, 'Processing Probe: '+probe[k]+',  Datatype: '+datatype[j], sb=sb, hw=hw

    ;load particle data into memory
    thm_part_load, probe=probe[k], datatype=datatype[j], trange=trange, sst_cal=sst_cal, $
                   use_eclipse_corrections=use_eclipse_corrections
    
    ;generate combined data if requested
    thm_ui_part_products_getcombined, probe=probe, $
                                      datatype=datatype, $
                                      trange=trange, $
                                      use_eclipse_corrections=use_eclipse_corrections, $
                                      esa_bgnd_remove=esa_bgnd_remove, $
                                      bgnd_type=bgnd_type, $
                                      bgnd_npoints=bgnd_npoints, $
                                      bgnd_scale=bgnd_scale, $
                                      sst_cal=sst_cal, $
                                      data_out = combined_data, $
                                      error=error, $
                                      _extra=_extra

    if keyword_set(error) then begin
      final_msg_suffix = ' Some quantities were not processed.'+ $
                         ' Check history window for details.'
      continue
    endif
  
    ;generate products
    thm_part_products, probe = probe[k], $
                       datatype = datatype[j], $
                       trange = trange, $
                       dist_array = combined_data, $
                       outputs = outputs[output_idx], $
                       phi = phi, $
                       theta = theta, $
                       pitch = pitch, $
                       gyro = gyro, $
                       energy = energy, $
                       regrid = regrid, $
                       start_angle = start_angle, $
                       suffix = suffix, $
                       fac_type = fac_type, $
                       esa_bgnd_remove=esa_bgnd_remove, $
                       bgnd_type=bgnd_type, $
                       bgnd_npoints=bgnd_npoints, $
                       bgnd_scale=bgnd_scale, $
                       sst_method_clean = sst_method_clean, $
                       sst_cal=sst_cal, $
                       tplotnames=tplotnames, $
                       _extra=_extra

    
    ;set intrument name for data tree
    case strmid(datatype[j],1,1) of 
      'e': instrument = 'esa'
      's': instrument = 'sst'
      't': instrument = 'esa + sst'
      else: 
    endcase

    ;load finaly products into gui
    for i=0, n_elements(tplotnames)-1 do begin

      success = loaded_data->add(tplotnames[i], $
                                 mission='THEMIS', $
                                 observatory=probe[k], $
                                 instrument=instrument)
     
      if success then begin
        msg = 'Added variable: '+tplotnames[i]
      endif else begin
        msg = 'Failed to ddd variable: '+tplotnames[i]
        final_msg_suffix = ' Some quantities were not processed.'+ $
                           ' Check history window for details.'
      endelse 

      spd_ui_message, msg, sb=sb, hw=hw
      
    endfor

  endfor ;end loop over datatype
endfor ;end loop over probe


;remove tplot variables created in this routine
;this will only remove new variables, not modified variables 
spd_ui_cleanup_tplot, tnames_before, create_time_before=ct, new_vars=new_vars, del_vars=del_vars

;use 'new_vars' to also remove modified tplot variables
if del_vars[0] ne '' then begin
  store_data, del_vars, /delete
endif

spd_ui_message, 'Load finished.'+final_msg_suffix, sb=sb, hw=hw

              
end
