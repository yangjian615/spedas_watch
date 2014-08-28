;+
;
;spd_ui_draw_object method: pt2norm
;
;
;Convert pts into draw area normal coordinates.
;Inputs:
;  Value(numeric type, or array of numeric types): the point value(s) to be converted
;  xy(boolean):  0: convert for x-axis, 1 convert for y-axis.(because screen dims differ, axis must be specified)
;  
;Returns, the value in normalized coordinates
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/display/draw_object/spd_ui_draw_object__pt2norm.pro $
;-

function spd_ui_draw_object::pt2norm,value,xy

  compile_opt idl2,hidden
  
  pt2mm = 127D/360D
  mm2cm = .1D
  
  v = value*pt2mm*mm2cm
  
  dim = self->getDim()
  
  self.destination->getProperty,resolution=r
  
  dim /= self->getZoom()
  
  return,v/(r[xy]*dim[xy])
  
end
