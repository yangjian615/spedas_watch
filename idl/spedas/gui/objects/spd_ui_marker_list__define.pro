;+
;NAME:
; spd_ui_marker_list__define
;
;PURPOSE:
; Container of markers, inheriting generalized read/write routines from 
; SPD_UI_READWRITE
;
;CALLING SEQUENCE:
; marker_list = Obj_New("SPD_UI_MARKER_LIST")
;
;INPUT:
; none
;
;KEYWORDS:
; none
;
;OUTPUT:
; none
;
;METHODS:
; Add
; GetAll
;
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/objects/spd_ui_marker_list__define.pro $ ;

function spd_ui_marker_list::init
  self.markers = obj_new('IDL_CONTAINER')
  return, 1
end

pro spd_ui_marker_list::add,objs
   self.markers->add,objs
end

function spd_ui_marker_list::GetAll
   return,self.markers->Get(/all)
end

pro spd_ui_marker_list__define
  struct = { SPD_UI_MARKER_LIST, $
             markers:obj_new('IDL_CONTAINER'), $ ; Container of markers
             INHERITS SPD_UI_READWRITE $ ; Generalized read/write methods
           }
end
