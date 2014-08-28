;+
;spd_ui_draw_object method: getVariablesRowSizes
;
;Purpose:
;  generates an array that indicates the space variables will occupy for
;    each row in the layout, sizes are in pts
;  
;  INPUTS:
;    an array of spd_ui_panels
;    
;  OUTPUTS:
;    an array of sizes in pts
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/display/draw_object/spd_ui_draw_object__getvariablerowsizes.pro $
;-
function spd_ui_draw_object::getVariableRowSizes,panels

  compile_opt idl2,hidden

  panel_layouts = self->getPanelLayouts(panels)
  
  max_row = max(panel_layouts[*].row+panel_layouts[*].rSpan-1)
  
  row_sizes = dblarr(max_row)
  
  for i = 0,max_row-1 do begin
  
    idx = where(panel_layouts[*].row+panel_layouts[*].rSpan-2 eq i,c)
    
    if c gt 0 then begin
      row_sizes[i] = self->getVariableSize(panels[idx])
    endif
  
  endfor
  
  return,row_sizes
  
end
