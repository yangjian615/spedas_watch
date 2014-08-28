;+ 
;NAME: 
; spd_ui_marker_wizard__define
;
;PURPOSE:  
; Marker Settings object - used for the marker options panel, this object holds the
; wizard used for markers
;
;CALLING SEQUENCE:
; marker = Obj_New("SPD_UI_MARKER_WIZARD")
;
;INPUT:
; none
;
;KEYWORDS:
;useVarName     variable name to use to marking data
;whenVarName    mark data when this variable equals 
;whenRelOp      relative operator to use for marking
;whenValue      mark data when variable value is this
;highlightColor color to use when shading marked area 
;lineStyle      line style object for marker lines
;title          title or marker name
;minTimeSpan    don’t mark if less than minimum time 
;
;OUTPUT:
; marker setting object reference
;
;METHODS:
; SetProperty  procedure to set keywords 
; GetProperty  procedure to get keywords 
; GetAll       returns the entire structure
;
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/objects/spd_ui_marker_wizard__define.pro $
;-----------------------------------------------------------------------------------


PRO SPD_UI_MARKER_WIZARD::SetProperty,  $ ; standard property set method 
      useVarName=usevarname,          $ ; variable name to use to marking data
      whenVarName=whenvarname,        $ ; mark data when this variable equals 
      whenRelOp=whenrelop,            $ ; relative operator to use for marking
      whenValue=whenvalue,            $ ; mark data when variable value is this
      highlightColor=highlightcolor,  $ ; color to use when shading marked area 
      lineStyle=linestyle,            $ ; line style object for marker lines
      title=title,                    $ ; title or marker name
      minTimeSpan=mintimespan           ; don’t mark if less than minimum time 

 
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN
   ENDIF

   IF N_Elements(usevarname) NE 0 THEN self.useVarName = usevarname
   IF N_Elements(whenvarname) NE 0 THEN self.whenVarName = whenvarname 
   IF N_Elements(whenrelop) NE 0 THEN self.whenRelOp = whenrelop
   IF N_Elements(whenvalue) NE 0 THEN self.whenValue = whenvalue 
   IF N_Elements(highlightcolor) NE 0 THEN self.highlightColor = highlightcolor 
   IF Obj_Valid(linestyle) THEN self.lineStye = linestyle
   IF N_Elements(title) NE 0 THEN self.title = title
   IF N_Elements(mintimespan) NE 0 THEN self.minTimeSpan = mintimespan

RETURN
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_MARKER_WIZARD::GetAll
RETURN, self
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MARKER_WIZARD::GetProperty,  $
      UseVarName=usevarname,          $ ; variable name to use to marking data
      WhenVarName=whenvarname,        $ ; mark data when this variable equals 
      WhenRelOp=whenrelop,            $ ; relative operator to use for marking
      WhenValue=whenvalue,            $ ; mark data when variable value is this
      HighlightColor=highlightcolor,  $ ; color to use when shading marked area 
      LineStyle=linestyle,            $ ; line style object for marker lines
      Title=title,                    $ ; title or marker name
      MinTimeSpan=mintimespan           ; don’t mark if less than minimum time 
   
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN
   ENDIF

      ; Return only what the user asked for

   IF Arg_Present(usevarname) THEN usevarname = self.useVarName
   IF Arg_Present(whenvarname) THEN whenvarname = self.whenVarName  
   IF Arg_Present(whenrelop) THEN whenrelop = self.whenRelOp   
   IF Arg_Present(whenvalue) THEN whenvalue = self.whenValue  
   IF Arg_Present(highlightcolor) THEN highlightcolor = self.highlightColor   
   IF Arg_Present(linestyle) THEN linestyle = self.lineStyle 
   IF Arg_Present(title) THEN title = self.title 
   IF Arg_Present(mintimespan) THEN mintimespan=self.minTimeSpan   

RETURN
END ;--------------------------------------------------------------------------------



;PRO SPD_UI_MARKER_WIZARD::Cleanup
;   Obj_Destroy, self.lineStyle
;RETURN
;END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_MARKER_WIZARD::Init,  $
      UseVarName=usevarname,          $ ; variable name to use to marking data
      WhenVarName=whenvarname,        $ ; mark data when this variable equals 
      WhenRelOp=whenrelop,            $ ; relative operator to use for marking
      WhenValue=whenvalue,            $ ; mark data when variable value is this
      HighlightColor=highlightcolor,  $ ; color to use when shading marked area 
      LineStyle=linestyle,            $ ; line style object for marker lines
      Title=title,                    $ ; title or marker name
      MinTimeSpan=mintimespan,        $ ; don’t mark if less than minimum time 
      Debug=debug                       ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

      ; Check that all parameters have values
   
   IF N_Elements(usevarname) EQ 0 THEN usevarname = ' '
   IF N_Elements(whenvarname) EQ 0 THEN whenvarname = ' '
   IF N_Elements(whenrelop) EQ 0 THEN whenrelop = 0
   IF N_Elements(whenvalue) EQ 0 THEN whenvalue = 0
   IF N_Elements(highlightcolor) EQ 0 THEN highlightcolor = [0,0,0] 
   IF N_Elements(title) EQ 0 THEN title = ' '
   IF N_Elements(minTimeSpan) EQ 0 THEN mintimespan = 0 

   IF NOT Obj_Valid(linestyle) THEN linestyle =  Obj_New(SPD_UI_LINE_STYLE, Color=[255,0,0])

      ; Set all parameters

   self.useVarName = usevarname
   self.whenVarName = whenvarname
   self.whenRelOp = whenrelop
   self.whenValue = whenvalue
   self.highlightColor = highlightcolor
   self.lineStyle = linestyle
   self.title = title
   self.minTimeSpan = mintimespan
  
                 
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MARKER_WIZARD_DEFINE

   struct = { SPD_UI_MARKER_WIZARD,  $
          
      useVarName : ' ',       $ ; variable name to use to marking data
      whenVarName : ' ',      $ ; mark data when this variable equals 
      whenRelOp : 0,          $ ; relative operator to use for marking
      whenValue : 0,          $ ; mark data when variable value is this
      highlightColor:[0,0,0] ,$ ; color to use when shading marked area 
      lineStyle : Obj_New(),  $ ; line style object for marker lines
      title : ' ',            $ ; title or marker name
      minTimeSpan : 0D        $ ; don’t mark if less than minimum time span 

}

END
