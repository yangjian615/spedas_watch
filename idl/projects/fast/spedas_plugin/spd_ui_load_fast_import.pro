;+
;NAME:
;  spd_ui_load_fast_import
;
;PURPOSE:
;  Modularized gui FAST mission data loader/importer
;  Lightly modified version of the ACE loader/importer
;
;
;HISTORY:
;$LastChangedBy: jwl $
;$LastChangedDate: 2014-07-03 12:31:53 -0700 (Thu, 03 Jul 2014) $
;$LastChangedRevision: 15502 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/fast/spedas_plugin/spd_ui_load_fast_import.pro $
;
;--------------------------------------------------------------------------------


pro spd_ui_load_fast_import,$
                         loadStruc, $
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  ;needed for appropriate layering and modality of popups
                         replay=replay,$
                         overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 
                         
  compile_opt hidden,idl2

  instrument=loadStruc.instrument[0]
  datatype=loadStruc.datatype[0]
  parameters=loadStruc.parameters
  timeRange=loadStruc.timeRange
  loaded = 0

  new_vars = ''

  overwrite_selection=''
  overwrite_count =0

  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  tn_before = [tnames('*',create_time=cn_before)]
;  tn_before_time_hash = [tn_before + time_string(double(cn_before),/msec)]

  par_names = 'fa_hr_dcb_' + parameters

  fa_load_mag_hr_dcb,trange=timeRange,tplotnames=tplotnames
  
  spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  
  if new_vars[0] ne '' then begin
    ;only add the requested new parameters
    new_vars = ssl_set_intersection([par_names],[tplotnames])
    loaded = 1
    ;loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin
    
      ;Check if data is already loaded, so that it can query user on whether they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue
      
      result = loadedData->add(new_vars[i],mission='FAST',observatory='FAST',instrument=instrument,coordSys=coordSys)
      
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'FAST: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
    
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
     
  if loaded eq 1 then begin
    statusBar->update,'FAST Data Loaded Successfully'
    historyWin->update,'FAST Data Loaded Successfully'
  endif else begin
    statusBar->update,'No FAST Data Loaded.  Data may not be available during this time interval.'
    historyWin->update,'No FAST Data Loaded.  Data may not be available during this time interval.'    
  endelse

end