;+ 
;NAME:
; spd_ui_cotrans_new
;
;PURPOSE:
; A performs the coordinate transformations
;
;CALLING SEQUENCE:
; spd_ui_cotrans_new, value,info
;
;INPUT:
; value:  a string storing the destination coordinate system
; active: the set of variables to be transformed
; loadedData: the loadedData object
; sobj: the status bar object to which messages should be sent
; callSequence:  the object that tracks data processing operations so that they can be replayed in SPEDAS documents.
; replay(optional): This keyword determines whether operations are pushed onto the call sequence and whether popups are displayed
; tvar_overwrite_selections(optional): Set this keyword when the replay keyword is set.  It will contain an array of what overwrite selection was made for each processed variable
; load_support_selections(optional): Set this keyword when the replay keyword is set.  It will contain an array of what support load selection was made for each processed variable
; load_slp_selections(optional): Set this keyword when the replay keyword is set.  It will contain an array of what slp load selection was made for each processed variable
;OUTPUT:
; none
; 
; SIDE EFFECT: New active variable for each prior active stored in loaded data
;   and transformed into the new coordinate system with suffix added/changed
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/panels/spd_ui_cotrans_new.pro $
;
;---------------------------------------------------------------------------------

pro spd_ui_cotrans_new,tlb,value,active,loadedData,sobj,historywin,callSequence,replay=replay,tvar_overwrite_selections=tvar_overwrite_selections,load_support_selections=load_support_selections,load_slp_selections=load_slp_selections

  compile_opt idl2,hidden
  
  all = loadedData->getAll(/parent) ; no children traces will hold support data so we don't bother either
  
  
  ;READ THIS: If you are adding any new coordinate systems, you need to update spd_ui_req_spin.pro
  validcoords = ['dsl','ssl','spg','gsm','gse','gei','sm','geo', 'sse', 'sel']
    
  ;remember "Yes to all" and "No to all" decisions for state load queries
  yesall = 0
  noall = 0
   
  tvar_overwrite_selection =''
  load_support_selection = ''
  load_slp_selection = ''
  tvar_overwrite_count = 0
  load_support_count = 0
  load_slp_count = 0
  
  if ~keyword_set(replay) then begin
    tvar_overwrite_selections=''
    load_support_selections=''
    load_slp_selections=''
  endif
   
  if ~keyword_set(active) then begin
    ;info.statusBar->update,'No active data is transformable'
    sobj->update,'No active data is transformable'
    return
  endif else begin
   
    for i = 0,n_elements(active)-1 do begin
      out_var = '' ; reset variable 
    
      ;used to keep track of what tplot variables are already defined.  This way we can try to preserve the state of the command line tplot variables, before and after the gui dproc operation.
      ;This means that no new tplot variables are created, and no tplot variables that existed before the operation are deleted.  Unfortunately, some tplot variables may need to be altered.
      tn_before = tnames('*')
    
      var = loadedData->getTvarObject(active[i])
    
      var->GetProperty,name=name,coordSys=coordSys,observatory=probe,mission=mission,timerange=timerange,dataPtr=dataPtr

      startTime = timerange->getStartTime()
      endTime = timerange->getEndTime()
      
      trange = [starttime,endtime]
      
      origname=name
      
      if strlowcase(mission) ne 'spedas' then begin
;          result=error_message('No coordinate transformation support for non-SPEDAS missions',$
;                               title ='Error in Cotrans: ', /noname ) 
;          sobj->update, 'No coordinate transformation support for non-SPEDAS missions'
          
          probe='xxx' ; set a dummy probe so non-SPEDAS data can be converted
          
;          continue              ;skip the rest of the loop
      endif
      
      if strlowcase(coordSys) eq 'n/a' then begin
        if ~keyword_set(replay) then begin
          result=error_message('Sorry. '+name+ ' does not have its coordinate system defined. Cannot perform transformation.', $
                              title ='Error in Cotrans: ', /noname, /center,traceback=0)
        endif
        sobj->update, 'Sorry. '+name+ ' does not have its coordinate system defined. Cannot perform transformation.'
        spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
        if to_delete[0] ne '' then begin
          store_data,to_delete,/delete
        endif
        continue              ;skip the rest of the loop
      endif
      
      get_data,name,data=dTest
      dDim = dimen(dTest.y)
      if n_elements(dDim) ne 2 || dDim[1] ne 3 then begin
        if ~keyword_set(replay) then begin
          result=error_message('Sorry. '+name+ ' is not a 3-vector. Cannot perform transformation.', $
                              title ='Error in Cotrans: ', /noname, /center,traceback=0)
        endif
        sobj->update, 'Sorry. '+name+ ' is not a 3-vector. Cannot perform transformation.'
        spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
        if to_delete[0] ne '' then begin
          store_data,to_delete,/delete
        endif
        continue              ;skip the rest of the loop
      
      endif

      if strlowcase(probe) eq 'tha' then probe = 'a'
      if strlowcase(probe) eq 'thb' then probe = 'b'
      if strlowcase(probe) eq 'thc' then probe = 'c'
      if strlowcase(probe) eq 'thd' then probe = 'd'
      if strlowcase(probe) eq 'the' then probe = 'e'
      if strlowcase(probe) eq 'xxx' then probe = 'x' ; dummy probe for non-SPEDAS data

      ok_probe = where(['a', 'b', 'c', 'd', 'e', 'x'] Eq probe)
      if ok_probe[0] eq -1 then begin
          if ~keyword_set(replay) then begin
            result=error_message('Sorry. No coordinate transformation support for ground-based data: '+probe,$
                               title ='Error in Cotrans: ', /noname, /center,traceback=0)
          endif
          sobj->update, 'Sorry. No coordinate transformation support for ground-based data: '+probe
          spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
          if to_delete[0] ne '' then begin
            store_data,to_delete,/delete
          endif
          continue              ;skip the rest of the loop
      endif
      
      if strlowcase(coordSys) eq 'spg' || strlowcase(coordSys) eq 'dsl' || strlowcase(coordSys) eq 'ssl' || $
         strlowcase(value) eq 'spg' || strlowcase(value) eq 'dsl' || strlowcase(value) eq 'ssl' then begin

        if probe eq 'x' then begin
        ; make sure non-SPEDAS data isn't converted to spg, dsl, or ssl coords
          if ~keyword_set(replay) then begin
            result=error_message('Sorry. '+name+ ' is not SPEDAS data. Can not convert to SPG, DSL, or SSL coordinates.',$
                               title ='Error in Cotrans: ', /noname, /center,traceback=0)
          endif 
          sobj->update, 'Sorry. '+name+ ' is not SPEDAS data. Can not convert to SPG, DSL, or SSL coordinates.'
          spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
          if to_delete[0] ne '' then begin
            store_data,to_delete,/delete
          endif
          continue              ;skip the rest of the loop
        endif
      endif
      
      ;check for EFI variables and disallow coordinate transforms from SPG to anything else
      efi_vars = ['eff', 'efp', 'efw']
      instr = strmid(name, 4, 3)
      efi_test = where(instr Eq efi_vars)
      if(efi_test[0] ne -1 &&  strlowcase(coordSys) eq 'spg') then begin
        if(~keyword_set(replay)) then begin
          result = error_message('Sorry. '+name+ ' is in SPG coordinates. EFI data in SPG can not be converted to other coordinates. Please load EFI L1 data in DSL to convert.', $
                                 title = 'Error in Cotrans: ', /noname, /center, traceback = 0)
        endif 
        sobj -> update, 'Sorry. '+name+ ' is in SPG coordinates. EFI data in SPG can not be converted to other coordinates. Please load EFI L1 data in DSL to convert.'
        spd_ui_cleanup_tplot, tn_before, del_vars = to_delete
        if to_delete[0] ne '' then begin
          store_data, to_delete, /delete
        endif
        continue                ;skip the rest of the loop
      Endif

      spinras_cor = 'th'+probe+'_state_spinras_corrected'
      spindec_cor = 'th'+probe+'_state_spindec_corrected'
      spinras = 'th'+probe+'_state_spinras'
      spindec = 'th'+probe+'_state_spindec'
      
      ;determine state dependencies for variable, know that the behavior of these
      ;routines is undefined if non-spedas observatories request, spedas spacecraft transforms
      ;this is intentional, as it should never happen
      if spd_ui_req_spin(coordSys,value,probe,trange,loadedData) then begin
         
         message_stem = 'Required state data not loaded for SPEDAS ' + strupcase(probe) + '.'
         skip_message = message_stem + ' skipping transform of ' + active[i] 
         prompt_message = message_stem + ' Would you like to load this data automatically?'
         loading_message = message_stem + ' Attempting to load state data.'
         
         if load_support_selection ne 'yestoall' && load_support_selection ne 'notoall' then begin

           if ~keyword_set(replay) then begin
             load_support_selection = spd_ui_prompt_widget(tlb,sobj,historyWin,promptText=prompt_message,title="Load state data?",defaultValue="no",/yes,/no,/allyes,/allno, frame_attr=8)
             load_support_selections = array_concat_wrapper(load_support_selection,load_support_selections)
           endif else begin
             if load_support_count ge n_elements(load_support_selections) then begin
              historywin->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
              sobj->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
              load_support_selection = "yestoall"
             endif else begin
              load_support_selection = load_support_selections[load_support_count]
             endelse
           endelse
           
           load_support_count++
         endif
         
         if load_support_selection eq 'notoall' || load_support_selection eq 'no' then begin
           sobj->update,skip_message 
           historywin->update,skip_message
           spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
           if to_delete[0] ne '' then begin
             store_data,to_delete,/delete
           endif
           continue
         endif
         
         thm_load_state,probe=probe,/get_support_data,trange=trange
         
         if is_string(tnames(spinras_cor)) && is_string(tnames(spindec_cor)) then begin
           sobj->update,'Loading : ' + spinras_cor + ' & ' + spindec_cor
           historywin->update,'Loading : ' + spinras_cor + ' & ' + spindec_cor
           if (~loadedData->add(spinras_cor) || ~loadedData->add(spindec_cor)) && ~keyword_set(replay) then begin
             ok = error_message('unexpected error adding data',traceback=0,/center,title='Error in Cotrans New')
           endif
         endif else if is_string(tnames(spinras)) && is_string(tnames(spindec)) then begin
           sobj->update,'Corrected variable not found, loading : ' + spinras + ' & ' + spindec
           historywin->update,'Corrected variable not found, loading : ' + spinras + ' & ' + spindec
           if (~loadedData->add(spinras) || ~loadedData->add(spindec)) && ~keyword_set(replay) then begin
             ok = error_message('unexpected error adding data',traceback=0,/center,title='Error in Cotrans New')
           endif
         endif
               
         if spd_ui_req_spin(coordSys,value,probe,trange,loadedData) then begin
            
            spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
            if to_delete[0] ne '' then begin
              store_data,to_delete,/delete
            endif
            fail_message = "Failed to auto-load state data for SPEDAS " + strlowcase(probe) + " to transform " + active[i] + ". Skipping."
            sobj->update,fail_message
            historywin->update,fail_message
            ok = error_message(fail_message,traceback=0,/center,title='Error in Cotrans New')
            continue
          endif
        
      endif
      
      name_sun_pos = 'slp_sun_pos'
      name_lun_pos = 'slp_lun_pos'
      name_lun_att_x = 'slp_lun_att_x'
      name_lun_att_z = 'slp_lun_att_z'
      names = [name_sun_pos, name_lun_pos, name_lun_att_x, name_lun_att_z]
      
      if spd_ui_req_slp(coordSys,value,trange,loadedData) then begin
        
        message_stem = 'Required Solar/Lunar ephemeris not present for variable ' + active[i]
        skip_message = message_stem + ' skipping transform of ' + active[i] 
        prompt_message = message_stem + ' Would you like to load this data now?'
        loading_message = 'Loading Solar/Lunar ephemeris data...'
        
        if load_slp_selection ne 'yestoall' && load_slp_selection ne 'notoall' then begin
         
           if ~keyword_set(replay) then begin
             load_slp_selection = spd_ui_prompt_widget(tlb,sobj,historyWin,promptText=prompt_message,title="Load SLP data?",defaultValue="no",/yes,/no,/allyes,/allno, frame_attr=8)  
             load_slp_selections = array_concat_wrapper(load_slp_selection,load_slp_selections)
           endif else begin
             if load_slp_count ge n_elements(load_slp_selections) then begin
              historywin->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
              sobj->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
              load_slp_selection = "yestoall"
             endif else begin
              load_slp_selection = load_slp_selections[load_slp_count]
             endelse
           endelse
           
           load_slp_count++
         endif
         
        if load_slp_selection eq 'notoall' || load_slp_selection eq 'no' then begin
          sobj->update,skip_message 
          historywin->update,skip_message
          spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
          if to_delete[0] ne '' then begin
            store_data,to_delete,/delete
          endif
          continue
        endif
        
        sobj -> update, loading_message
        historywin -> update, loading_message
        
        thm_load_slp,datatype='all',trange=trange
        
        ;add data to gui
        for j=0, n_elements(names)-1 do begin
          if is_string(tnames(names[j])) && ~loadeddata->add(names[j]) && ~keyword_set(replay) then begin
            addmsg = keyword_set(addmsg) ? strjoin([addmsg,names[j]],', '):names[j]
          endif
        endfor
        
        ;notify user if data cannot be loaded into gui
        if keyword_set(addmsg) then begin
          ok = error_message('Unexpected error adding '+addmsg+' to GUI.', $
                           traceback=0, /center, title='Error in Cotrans New')
        endif
        
        ;double check everything worked OK
        if spd_ui_req_slp(coordSys,value,trange,loadedData) then begin
           
           spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
           if to_delete[0] ne '' then begin
             store_data,to_delete,/delete
           endif
           fail_message = "Failed to auto-load Solar/Lunar ephemeris to transform " + active[i] + ". Skipping."
           sobj->update,fail_message
           historywin->update,fail_message
           ok = error_message(fail_message,traceback=0,/center,title='Error in Cotrans New')
           continue
        endif
       
      endif
        
      out_suffix = '_'+strlowcase(value)
      in_suffix = ''
      
      ;info.statusBar->update,'Coordinate Transforming: ' + name
      sobj->update,String('Coordinate Transforming: ' + name)
      
      for j = 0,n_elements(validCoords)-1 do begin
      
        if (pos = stregex(name,'_'+validCoords[j]+'$',/fold_case)) ne -1 then begin
          in_suffix = '_'+ validCoords[j]
          name = strmid(name,0,pos)
          break
        endif
      endfor
      
      catch,err
      
      if err ne 0 then begin
      
        catch,/cancel
        if ~keyword_set(replay) then begin
          ok = error_message('Unexpected cotrans error, see console output.',/traceback,/center,title='Error in Cotrans New')
        endif
        spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
        if to_delete[0] ne '' then begin
          store_data,to_delete,/delete
        endif
        return
        
      endif else begin
      
        thm_cotrans,name,in_suffix=in_suffix,out_suffix=out_suffix,out_vars=out_var,probe=probe,in_coord=coordSys,out_coord=value
      
      endelse
      
      catch,/cancel
      
      if ~keyword_set(out_var) then begin
        ;info.statusbar->update,'Data not transformed: '+name
        sobj->update,String('Data not transformed: '+name)
        spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
        if to_delete[0] ne '' then begin
          store_data,to_delete,/delete
        endif
        continue
      endif else begin
        ;info.statusbar->update,'Successfully transformed variable to: ' + out_var[0]
        sobj->update,String('Successfully transformed variable to: ' + out_var[0])
      endelse
      
      out = var->copy()
      out->setProperty,coordSys = value,name=out_var
      spd_ui_check_overwrite_data,out_var[0],loadedData,tlb,sobj,historyWin,tvar_overwrite_selection,tvar_overwrite_count,$
                             replay=replay,overwrite_selections=tvar_overwrite_selections
                             
      ; The spinras_cor and spindec_cor variables were being left in memory, 
      ; presumably because they were still in loadedData, removing them from 
      ; loadedData removes them from memory
      ras_del = loadedData->remove(spinras_cor)
      dec_del = loadedData->remove(spindec_cor)
      if strmid(tvar_overwrite_selection, 0, 2) eq 'no' then begin
          spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
          if to_delete[0] ne '' then begin
              store_data,to_delete,/delete
          endif
          continue
      endif
      
      if ~loadedData->addTvarObject(out) && ~keyword_set(replay) then begin
        ok = error_message('error adding data',traceback=0,/center,title='Error in Cotrans New')
      endif
            
      loadedData->clearActive,origname
      loadedData->setActive,out_var
      
      spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
      if to_delete[0] ne '' then begin
        store_data,to_delete,/delete
      endif
    endfor
    if ~keyword_set(replay) then begin
      callSequence->addCotransOp,value,active,tvar_overwrite_selections,load_support_selections,load_slp_selections
    endif
       
  endelse
 
end
