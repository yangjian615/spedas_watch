;+ 
;Name:
;  spd_ui_cotrans
;
;Purpose:
;  Performs coordinate transformations on GUI data
;
;Input:
;  tlb:  top level widget ID
;  out_coord:  string storing the destination coordinate system
;  active:  string array of variables to be transformed
;  loadedData:  the loadedData object
;  callSequence:  the call sequence object for replaying SPEDAS documents.
;  sobj:  status bar object
;  historywin:  history window object  
;  replay:  This keyword determines whether operations are pushed 
;           onto the call sequence and whether popups are displayed
;  tvar_overwrite_selections:  Set this keyword when the replay keyword is set.
;                              It should contain an array of what overwrite selection 
;                              was made for each processed variable.
;
;Output:
;  none
;
;Notes:
;  -If successful all previous active data variables will be replaced with
;   their transformed copies.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/cotrans/spd_ui_cotrans.pro $
;
;---------------------------------------------------------------------------------

pro spd_ui_cotrans, tlb, $
                    out_coord, $
                    active, $
                    loadedData, $
                    sobj, $
                    historywin, $
                    callSequence, $
                    replay=replay, $
                    tvar_overwrite_selections=tvar_overwrite_selections

compile_opt idl2, hidden


; no children traces will hold support data so we don't bother either
all = loadedData->getAll(/parent)

;get valid coordinates
coordSysObj = obj_new('spd_ui_coordinate_systems')
validcoords = coordSysObj->makeCoordSysList()
obj_destroy, coordSysObj
 
;remember "Yes to all" and "No to all" decisions for state load queries
yesall = 0
noall = 0

;existing variable overwrite for replay 
tvar_overwrite_selection =''
tvar_overwrite_count = 0

if ~keyword_set(replay) then begin
  tvar_overwrite_selections=''
endif
 
if ~keyword_set(active) then begin
  sobj->update,'No active data is transformable'
  return
endif
 
;keep track of all preexisting tplot vars
tn_before = tnames('*')

for i = 0,n_elements(active)-1 do begin
  
  sobj->update, 'Coordinate Transforming: ' + active[i]

  ;reset output list
  out_name = ''

  ;export object and tplot variable from GUI data
  var = loadedData->getTvarObject(active[i])      

  ;get metadata
  var->GetProperty, name=name, $
                    coordSys=in_coord, $
                    observatory=probe, $
                    mission=mission, $
                    timerange=timerange

  startTime = timerange->getStartTime()
  endTime = timerange->getEndTime()
  
  trange = [starttime,endtime]
  
  origname=name
  
  ;check input coord validity
  if strlowcase(in_coord) eq 'n/a' then begin
    errors = array_concat(name + ':  Data has no defined coordinate system.', errors)
    continue
  endif
 
  ;skip if variable is not a 3-vector
  ;TODO: this is inefficient and is already checked in spd_cotrans
  get_data,name,data=dTest
  dDim = dimen(dTest.y)
  if n_elements(dDim) ne 2 || dDim[1] ne 3 then begin
    errors = array_concat(name + ':  Data is not a 3-vector.', errors)
    continue
  endif

  out_suffix = '_'+strlowcase(out_coord)
  in_suffix = ''
     
  ;break name into base and suffix
  for j = 0,n_elements(validCoords)-1 do begin
    if (pos = stregex(name,'_'+validCoords[j]+'$',/fold_case)) ne -1 then begin
      in_suffix = '_'+ validCoords[j]
      name = strmid(name,0,pos)
      break
    endif
  endfor

  ;perform transformation    
  catch,err
  if err ne 0 then begin
    catch,/cancel
    if ~keyword_set(replay) then begin
      ok = error_message('Unexpected cotrans error, see console output.',/traceback,/center,title='Coordinate Transform Error')
    endif
    spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
    store_data,to_delete,/delete
    return
  endif else begin
  
    spd_cotrans, name, $
                 in_coord=in_coord, $
                 out_coord=out_coord, $
                 in_suffix=in_suffix, $
                 out_suffix=out_suffix, $
                 out_vars=out_var
  
  endelse
  catch,/cancel
  
  ;check for output vars
  if keyword_set(out_var) then begin
    sobj->update,String('Successfully transformed variable to: ' + out_var[0])
  endif else begin
    sobj->update,String('Data not transformed: '+name)
    continue
  endelse
  
  ;add output to the GUI
  out = var->copy()
  out->setProperty,coordSys = out_coord,name=out_var
  spd_ui_check_overwrite_data,out_var[0],loadedData,tlb,sobj,historyWin,tvar_overwrite_selection,tvar_overwrite_count,$
                         replay=replay,overwrite_selections=tvar_overwrite_selections
                         
  if ~loadedData->addTvarObject(out) && ~keyword_set(replay) then begin
    ok = error_message('error adding data',traceback=0,/center,title='Error in Cotrans New')
  endif
        
  loadedData->clearActive,origname
  loadedData->setActive,out_var
  
endfor


;clean up new tplot vars
spd_ui_cleanup_tplot, tn_before, del_vars=to_delete
store_data, to_delete, /delete

;add this operation to the call sequence
if ~keyword_set(replay) then begin
  callSequence->addCotransOp, out_coord, active, tvar_overwrite_selections
endif

;inform user of any errors
if ~undefined(errors) then begin
  text = ['Some errors were encountered; the following data was not transformed:  ',errors]
  spd_ui_message, strjoin(text,ssl_newline()), title='Skipped variables', dialog=~keyword_set(replay), hw=historywin
endif
       
 
end
