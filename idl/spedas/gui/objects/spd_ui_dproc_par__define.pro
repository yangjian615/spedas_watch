;+ 
;NAME: 
; spd_ui_dproc_par__define
;PURPOSE:  
; generic object to hold a pointer to a structure holding parameters
; for a data processing task.
;CALLING SEQUENCE:
; axis = Obj_New('spd_ui_dproc_par', dp_struct=dp_struct, dp_string=dp_string)
;INPUT:
; none
;KEYWORDS:
; dp_struct = an anonymous structure containing the input parameters for
;             the task, this will be unpacked in this routine and the
;             parameters are passed through. Note that, since this is
;             only called from the thm_GUI_new routine, there is no
;             error checking for content, it is expected that the
;             calling routine passes through the proper parameters in
;             each case.
; dp_string = a string variable that describes the process, e.g.,
;             'smooth' for smoothing
;OUTPUT:
; dp_struct object reference
;METHODS:
; init: initializes object
; cleanup: cleans up object
; SetProperty   procedure to set keywords 
; GetProperty   procedure to get keywords 
;HISTORY:
; 21-oct-2008, jmm, jimm@ssl.berkeley.edu
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/objects/spd_ui_dproc_par__define.pro $
;-----------------------------------------------------------------------------------
;init method allows setting of keywords in obj_new call
Function spd_ui_dproc_par::init, _extra = _extra
  self -> setproperty, _extra = _extra
  Return, 1
End
;Cleans up pointers
Pro spd_ui_dproc_par::cleanup
  ptr_free, self.dp_struct
  ptr_free, self.dp_string
  Return
End
;Set method
Pro spd_ui_dproc_par::setproperty, $
                    dp_struct = dp_struct, $
                    dp_string = dp_string, $
                    _extra = _extra
  If(is_struct(dp_struct)) Then Begin
    If(ptr_valid(self.dp_struct)) Then ptr_free, self.dp_struct
    self.dp_struct = ptr_new(dp_struct)
  Endif
  If(is_string(dp_string)) Then Begin
    If(ptr_valid(self.dp_string)) Then ptr_free, self.dp_string
    self.dp_string = ptr_new(dp_string)
  Endif
Return
End
;return everything
Function spd_ui_dproc_par::getall, object = object, _extra = _extra
  If(keyword_set(object)) Then Return, self Else Begin
;dereference pointers and return a structure
    If(ptr_valid(self.dp_struct)) Then a = *self.dp_struct $
    Else a = -1
    If(ptr_valid(self.dp_string)) Then b = *self.dp_string $
    Else b = ''
    Return, {dp_struct:a, dp_string:b}
  Endelse
End
Function spd_ui_dproc_par::getproperty, $
                         dp_struct = dp_struct, $
                         dp_string = dp_string, $
                         pointer = pointer, $
                         _extra = _extra
  If(keyword_set(dp_struct)) Then Begin
    If(keyword_set(pointer)) Then Return, self.dp_struct Else Begin
      If(ptr_valid(self.dp_struct)) Then Return, *self.dp_struct $
      Else Return, -1
    Endelse
  Endif
  If(keyword_set(dp_string)) Then Begin
    If(keyword_set(pointer)) Then Return, self.dp_string Else Begin
      If(ptr_valid(self.dp_string)) Then Return, *self.dp_string $
      Else Return, ''
    Endelse
  Endif
End
Pro spd_ui_dproc_par__define
  self = {spd_ui_dproc_par, $
          dp_struct:ptr_new(), $
          dp_string:ptr_new()}
  Return
End
