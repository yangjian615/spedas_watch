;+ 
;NAME: 
; spd_ui_data_range__define
;
;PURPOSE:  
; data range object 
;
;CALLING SEQUENCE:
; dataRange = Obj_New("SPD_UI_DATA_RANGE")
;
;INPUT:
; none
;
;KEYWORDS:
; startData  start data 
; endData    end data        
;
;OUTPUT:
; data range object reference
;
;METHODS:
; SetProperty  procedure to set keywords 
; GetProperty  procedure to get keywords
; GetStartData returns the start data (default format is double)
; GetStopData  returns the stop data (default format is double)
; GetDuration  returns duration in seconds 
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_data_range, and
;  call them in the same way as before
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/objects/spd_ui_data_range__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_DATA_RANGE::Copy
   out = Obj_New("SPD_UI_DATA_RANGE")
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_DATA_RANGE::Init, $
      StartData=startdata,        $ ; value at start of data 
      EndData=enddata,            $ ; value at end of data           
      Debug=debug                   ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
   
      ; Check for parameters
      
   IF N_Elements(startdata) EQ 0 THEN startdata = 0.0D
   IF N_Elements(enddata) EQ 0 THEN enddata = 0.0D
   
      ; Set all data range object attributes

   self.startData = startdata
   self.endData = enddata
                 
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_DATA_RANGE__DEFINE

   struct = { SPD_UI_DATA_RANGE,   $

      startData : 0.0D,    $ ; value where data starts  
      endData : 0.0D,      $ ; value where data ends 
      inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods   
      
 
}

END
