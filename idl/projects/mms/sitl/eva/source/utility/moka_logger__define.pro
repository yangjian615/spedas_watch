;
; This is a modified version of the code provided by 
; Jim Pendleton in his article at
; http://www.exelisvis.com/Company/PressRoom/Blogs/IDLDataPointDetail/
; TabId/902/ArtMID/2926/ArticleID/14005/DebuggerHelper---A-Handy-Debugging
; -Class-for-IDL-Developers.aspx
;
; 2014/08/18 Copied
; 2014/08/19 Modified for EVA
;          1. Removed TicToc (Because EVA has to work on IDL6.4)
;          2. Renamed the object name to avoid conflict with the original one
;          3. Changed log output format
;          4. Changed the log-file name
;          5. Disabled widget
Pro moka_logger::_ConstructDebugWidget, Group_Leader
  Compile_Opt IDL2
  self._DebugTLB = Widget_Base(/Column, $
    Title = Obj_Class(self) + ' Debug', $
    Group_Leader = Group_Leader)
  DebugText = Widget_Text(self._DebugTLB, Value = '', $
    UName = 'DebugText', $
    XSize = 140, YSize = 24, /Scroll)
  Widget_Control, self._DebugTLB, /Realize
End
Pro moka_logger::_CreateDebugFile
  Compile_Opt IDL2
;  LogDir = FilePath('', $
;    Root = File_DirName(Routine_Filepath()), $
;    SubDir = ['logs'])
;  If (~File_Test(LogDir)) then Begin
;    File_MkDir, LogDir
;    File_ChMod, LogDir, /A_Read, /A_Write
;  EndIf
;  self._DebugFile = FilePath('EVA' + $
;    StrTrim(ULong(SysTime(1)), 2) + '.log', $
;    Root = LogDir)
;  self._DebugFile = FilePath('EVA.log', $
;    Root = LogDir)
  self._DebugFile = getenv('HOME') + '/.eva_log.txt'
  If (File_Test(self._DebugFile)) then Begin
    File_Delete, self._DebugFile
  EndIf
  OpenW, DebugLUN, self._DebugFile, /Get_LUN
  self._DebugLUN = DebugLUN
  File_ChMod, self._DebugFile, /A_Read, /A_Write
End
Pro moka_logger::Cleanup
  Compile_Opt IDL2
  If (self._DebugLUN ne 0) then $
    Free_LUN, self._DebugLUN
  If (Widget_Info(self._DebugTLB, /Valid_ID)) then $
    Widget_Control, self._DebugTLB, /Destroy
End
Pro moka_logger::DebugOutput, Output, $
  No_Print = NoPrint, $
  Up = Up, plain=plain
  Compile_Opt IDL2
  If (~self._DebugOn) then Begin
    Return
  EndIf
  ThisClass = Obj_Class(self)
  stb = Scope_Traceback(/Structure)
  Routines = stb.Routine
  if keyword_set(plain) then begin 
    Result = '' 
  endif else begin 
    nnn = n_elements(Routines)-(2+keyword_set(Up))
    Result = Routines[nnn] + '(' + strtrim(string(stb[nnn].LINE),2) + '): '
  endelse
  Result += Output
  If (~Keyword_Set(NoPrint)) then Begin
    Print, Result, Format = '(a)'
  EndIf
;  If (~Widget_Info(self._DebugTLB, /Valid_ID)) then Begin
;    Return
;  EndIf
  Now = systime(/seconds)
  DT = time_string(Now,/local,format=4,precision=3)
;  Now = SysTime(1)
;  DT = '[' + $
;    String(Now - self._DebugCreationTime, $
;    Format = '(f14.3)') + ', ' + $
;    String(Now, Format = '(f14.3)') + $
;    '] '
;  DebugText = Widget_Info(self._DebugTLB, $
;    Find_by_UName = 'DebugText')
;  DebugYSize = (Widget_Info(DebugText, /Geometry)).YSize
;  Widget_Control, DebugText, Get_UValue = NLines
;  If (N_elements(NLines) eq 0) then Begin
;    NLines = 0L
;  EndIf
  if keyword_set(plain) then Line = Result else Line =  DT + ' '+Result
  If (self._DebugLUN ne 0) then Begin
    PrintF, self._DebugLUN, Line
    Flush, self._DebugLUN
  EndIf Else Begin
    Print, Line, Format = '(a)'
  EndElse
;  If (NLines gt self._DebugWindowMaxLines) then Begin
;    Widget_Control, DebugText, Get_Value = Old
;    Lines = Old[self._DebugWindowMaxLines/2:*]
;    Old = 0
;    NLines = N_elements(Lines)
;    Widget_Control, DebugText, $
;      Set_Value = [Temporary(Lines), Line]
;    Widget_Control, DebugText, $
;      Set_UValue = NLines + 1L
;  EndIf Else Begin
;    Widget_Control, DebugText, $
;      Set_Value = Line, /Append
;    Widget_Control, DebugText, $
;      Set_UValue = ++NLines
;  EndElse
;  Widget_Control, DebugText, Set_Text_Top_Line = $
;    NLines - DebugYSize + 3 > 0
End
Pro moka_logger::O, Output, _Extra = Extra
  Compile_Opt IDL2
  self->DebugOutput, Output, /Up, /No_Print, _Extra = Extra
End
Pro moka_logger::Off
  Compile_Opt IDL2
  self._DebugOn = 0
End
Pro moka_logger::On
  Compile_Opt IDL2
  self._DebugOn = 1
End
Pro moka_logger::GetProperty, $
  On = On, $
  File = File
  Compile_Opt IDL2
  If (Arg_Present(On)) then On = self._DebugOn
  If (Arg_Present(File)) then $
    File = self._DebugFile
End
Function moka_logger::Init, $
  On = On, $
  Group_Leader = Group_Leader, $
  No_File = No_File
  Compile_Opt IDL2
  self._DebugCreationTime = SysTime(1)
  self._DebugWindowMaxLines = 500
  self._DebugOn = Keyword_Set(On)
  self._DebugClocks = 0.d0
  ;self->_ConstructDebugWidget, Group_Leader
  If (~Keyword_Set(No_File)) then $
    self->_CreateDebugFile
  Return, 1
End
Pro moka_logger__Define
  !null = {moka_logger, Inherits IDL_Object, $
    _DebugOn : 0B, $
    _DebugLUN : 0L, $
    _DebugFile : '', $
    _DebugTLB : 0L, $
    _DebugCreationTime : 0D, $
    _DebugClocks : [0.d0], $
    _DebugWindowMaxLines : 0L}
End