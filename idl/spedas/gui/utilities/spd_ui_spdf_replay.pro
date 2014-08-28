;+
;
;  spdfcdawebchooser GUI load code is structured in such a way that it would be very difficult to abstract.
;  Instead just rewriting the load process in a way that isn't so dependent on pseudo-globals(via state)
;  and gui elements, this way we can replay the data without needing the UI to be instantiated.
;
;  In the future, we may want to consider replacing the cdawebchooser GUI code with this.
;  as I'm forking a little bit here.
;  
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-06-10 19:13:51 -0700 (Tue, 10 Jun 2014) $
;$LastChangedRevision: 15345 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_spdf_replay.pro $
;-----------------------------------------------------------------------------------



pro spd_ui_spdf_replay,tlb,statusbar,historywindow,$
  timeInterval,datasetId,varnames,$
  selectedDataview,loadedData,$
  windowStorage
  
  ;do nothing until IDL crash is traced
  return

  RESOLVE_ROUTINE, 'spdf_virtual_funcs', /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spdfCdawebChooser', /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spdf_virtual_funcs', /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_ui_spdfcdawebchooser', /COMPILE_FULL_FILE

  localdir = !spedas.TEMP_CDF_DIR

  cdas = $
    obj_new('SpdfCdas', $
    endpoint='http://cdaweb.gsfc.nasa.gov/WS/cdasr/1', $
    userAgent='CdawebChooser/1.0')

  authenticator = obj_new('SpdfCdawebChooserAuthenticator', tlb)
  errorDialog = obj_new('SpdfHttpErrorDialog')

  timeIntervalObj =  obj_new('SpdfTimeInterval', timeInterval[0], timeInterval[1])

  dataResults = $
    cdas->getCdfData($
    timeIntervalObj, datasetId, varNames, $
    dataview=selectedDataview, $
    authenticator=authenticator, $
    httpErrorReporter=errorDialog)

  fileDescriptions = dataResults->getFileDescriptions()

  for i = 0, n_elements(fileDescriptions) - 1 do begin
    urlname = fileDescriptions[i]->getName()
    urlComponents = parse_url(urlname)
    urlfilename = file_basename(urlComponents.path)
    filename = localdir + urlfilename
    localCdfNames[i] = fileDescriptions[i]->getFile(filename=filename[0])
  endfor

  CDFfileExists = FILE_TEST(localCDFfile)
  if CDFfileExists then begin

    fix_spedas_depend_time, localCDFfile[0]

    cdf2tplot,files=localCDFfile,all=1,prefix=theprefix,tplotnames=tplotnames,/load_labels

    spd_ui_tplot_gui_load_tvars,tplotnames,all_names=all_varnames,gui_id=tlb
    spd_ui_verify_data,tl, all_varnames,loadedData, windowStorage, historyWin, success=success,newnames=new_names

    if ~keyword_set(success) then success=0
    if success then begin
      statusMessage = 'CDAWeb: All variables imported successfully. Check history window for details.'
      statusBar->Update, statusMessage
      historyWin->Update, statusMessage
    endif else begin
      statusMessage = 'CDAWeb: Problem importing some variables.  Check history window for details.'
      statusBar->Update, statusMessage
      historyWin->Update, statusMessage
    endelse
  endif

  obj_destroy, fileDescriptions
  obj_destroy, dataResults
end