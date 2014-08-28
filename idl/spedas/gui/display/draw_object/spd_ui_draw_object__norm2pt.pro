;+
;
;spd_ui_draw_object method: norm2pt
;
;converts back from the normalized value into points,
;While the normalized value is dependent on screen dimensions
;zoom, & resolution.  The value in points should be an
;absolute quantity
;
;Inputs:
;  Value(numeric or array of numerics):  A value in screen normal coords
;  xy(boolean) 0 : convert from x-axis, 1:convert from y-axis(because screen dims differ, axis must be specified)
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/display/draw_object/spd_ui_draw_object__norm2pt.pro $
;-
function spd_ui_draw_object::norm2pt,value,xy

  compile_opt idl2,hidden
  
  pt2mm = 127D/360D
  mm2cm = .1D
  
  dim = self->getDim()
  
  self.destination->getProperty,resolution=r
  
  dim /= self->getZoom()
  
  v = value*r[xy]*dim[xy]
  
  return,v/(pt2mm*mm2cm)
  
end
