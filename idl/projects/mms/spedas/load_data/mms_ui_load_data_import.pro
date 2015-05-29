;+
;NAME:
;  mms_ui_load_data_import
;
;PURPOSE:
;  This routine acts as a wrapper around the load data 
;      routine for MMS, mms_load_data. It is called by the 
;      SPEDAS plugin mms_ui_load_data, and imports the data
;      loaded by mms_load_data into the SPEDAS GUI
;
;  
;HISTORY:
;
;;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-05-27 14:37:31 -0700 (Wed, 27 May 2015) $
;$LastChangedRevision: 17748 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/load_data/mms_ui_load_data_import.pro $
;
;-

pro mms_ui_load_data_import,$
                         loadStruc,$
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  
                         replay=replay,$
                         overwrite_selections=overwrite_selections
                         

  compile_opt hidden,idl2
  
  ; initialize variables
  loaded = 0
  new_vars = ''
  overwrite_selection=''
  overwrite_count =0
  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; extract the variables from the load structure
  probes=loadStruc.probes
  instrument=loadStruc.instrument
  datatype=loadStruc.datatype
  timeRange=loadStruc.trange
  
  ; need to update for MMS
  mmsmintime = '2015-03-01'
  mmsmaxtime = '2050-12-31'
  

  tn_before = [tnames('*',create_time=cn_before)]

  mms_load_data, probes=probes, datatype=datatype, trange=timeRange, instrument=instrument

  ; determine which tplot vars to delete and which ones are the new temporary 
  ; vars
  spd_ui_cleanup_tplot, tn_before, create_time_before=cn_before, del_vars=to_delete,$
                        new_vars=new_vars
 
  if new_vars[0] ne '' then begin
    loaded = 1
    
    ; loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin
      
      ; check if data is already loaded, if so query the user on whether they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin, $
        overwrite_selection,overwrite_count,replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue
      
      ; this statement adds the variable to the loadedData object
      result = loadedData->add(new_vars[i],mission='MMS',observatory=probes, $
                               instrument=strupcase(instrument))
        
      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'MMS: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
    
  ; here's where the temporary tplot variables are removed
  if to_delete[0] ne '' then begin
     store_data,to_delete,/delete
  endif
  
  ; inform the user that the load was successful and add it to the history   
  if loaded eq 1 then begin  
     statusBar->update,'MMS Data Loaded Successfully'
     historyWin->update,'MMS Data Loaded Successfully'
  endif else begin
  
     ; if the time range specified by the user is not within the time range 
     ; of available data for this mission and instrument then inform the user 
     if time_double(mmsmaxtime) lt time_double(timerange[0]) || $
        time_double(mmsmintime) gt time_double(timerange[1]) then begin
        statusBar->update,'No MMS Data Loaded, MMS data is only available between ' + mmsmintime + ' and ' + mmsmaxtime
        historyWin->update,'No MMS Data Loaded, MMS data is only available between ' + mmsmintime + ' and ' + mmsmaxtime
     endif else begin   
        statusBar->update,'No MMS Data Loaded'
        historyWin->update,'No MMS Data Loaded'
     endelse
    
  endelse
end
