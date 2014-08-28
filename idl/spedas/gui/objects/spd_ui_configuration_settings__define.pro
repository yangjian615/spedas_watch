;+ 
;NAME: 
; spd_ui_configuration_settings__define
;
;PURPOSE:  
; generic object for configuration settings
;
;CALLING SEQUENCE:
; configSettings = Obj_New("SPD_UI_CONFIGURATION_SETTINGS")
;
;INPUT:
; none
;
;ATTRIBUTES:
;localdatadir    name of directory to get local data
;remotedatadir   name of directory to get remote data 
;downloaddata    download data 0=Automatically, 1=Use local data only
;updatefiles     update files 0=if newer, 1=use local only
;loaddata        loading data 0=download and load, 1=download only
;loadstatedata   load state data 0=automatically, 1=on request only 
;verbose         debug settings 0-6, 6 being the most debug messages

;OUTPUT:
; configuration settings object reference
;
;METHODS:
; GetProperty
; GetAll
; SetProperty
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_configuration_Settings, and
;  call them in the same way as before
;  
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_configuration_settings__define.pro $
;-----------------------------------------------------------------------------------
  
FUNCTION SPD_UI_CONFIGURATION_SETTINGS::Init,         $ ; The INIT method of the line style object
              LocalDataDir=localdatadir,     $ ; name of directory to get local data
              RemoteDataDir=remotedatadir,  $ ; name of directory to get remote data 
              DownloadData=downloaddata,     $ ; download data 0=Automatically, 1=Use local data only
              UpdateFiles=updatefiles,       $ ; update files 0=if newer, 1=use local only
              LoadData=loaddata,             $ ; loading data 0=download and load, 1=download only
              LoadStateData=loadstatedata,   $ ; load state data 0=automatically, 1=on request only 
              Verbose=verbose,               $ ; debugging settings 0-6, 6 being the most debug messages
              Debug=debug                      ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values

   IF N_Elements(localdatadir) EQ 0 THEN localdatadir = !spedas.local_data_dir
   IF N_Elements(remotedatadir) EQ 0 THEN remotedatadir = !spedas.remote_data_dir
   IF N_Elements(downloaddata) EQ 0 THEN downloaddata = !spedas.no_download
   IF N_Elements(updatefiles)EQ 0 THEN updatefiles = !spedas.no_update
   IF N_Elements(loaddata)EQ 0 THEN loaddata = !spedas.downloadonly 
   IF N_Elements(loadstatedata) EQ 0 THEN loadstatedata = 1 
   IF N_Elements(verbose)EQ 0 THEN verbose = !spedas.verbose

  ; Set all parameters

   self.localDataDir = localdatadir
   self.remoteDataDir = remotedatadir
   self.downloadData = downloaddata
   self.updateFiles = updatefiles
   self.loadData = loaddata
   self.loadStateData = loadstatedata
   self.verbose = verbose   
  
   RETURN, 1
END ;--------------------------------------------------------------------------------                 



PRO SPD_UI_CONFIGURATION_SETTINGS__DEFINE

   struct = { SPD_UI_CONFIGURATION_SETTINGS,            $

              localDataDir : '',     $ ; name of directory to get local data
              remoteDataDir : '',    $ ; name of directory to get remote data 
              downloadData : 0,      $ ; download data 0=Automatically, 1=Use local data only
              updateFiles : 0,       $ ; update files 0=if newer, 1=use local only
              loadData : 0,          $ ; loading data 0=download and load, 1=download only
              loadStateData : 0,     $ ; load state data 0=automatically, 1=on request only 
              verbose : 0,           $ ; debugging settings 0-6, 6 being the most debug messages
              inherits spd_ui_getset    $ ; generalized setProperty/getProperty/getAll/setAll methods   
                                     
}

END
