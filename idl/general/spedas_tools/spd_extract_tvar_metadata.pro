;+
; FUNCTION:
;         spd_extract_tvar_metadata
;
; PURPOSE:
;         Returns metadata extracted from a tplot variable; mostly for tplot2ap and tplot2cdf
;
; NOTES:
;         prefers the following order:
;         - limits structure (set by the user during the session)
;         - dlimnits structure (set by the load routine)
;         - dlimits.cdf structure (stored in the CDF file)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-02-23 11:52:33 -0800 (Fri, 23 Feb 2018) $
; $LastChangedRevision: 24765 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_extract_tvar_metadata.pro $
;-

function spd_extract_tvar_metadata, tvar
    tvar = tnames(tvar)
    if tvar eq '' then begin
      dprint, dlevel = 0, 'tplot variable not found!'
      return, -1
    endif
    
    out = create_struct('units', '', 'labels', '', 'catdesc', '', 'ztitle', '', 'ytitle', tvar, 'spec', 0b)
    
    get_data, tvar, dlimits=dl, limits=l
    if is_struct(dl) then begin
      ; first try the CDF info
      if is_struct(dl.cdf.vatt) then begin
        str_element, dl.cdf.vatt[0], 'catdesc', success=s
        if s then out.catdesc = dl.cdf.vatt[0].catdesc
        
        str_element, dl.cdf.vatt[0], 'units', success=s
        if s then out.units = dl.cdf.vatt[0].units
      endif
      
      ; now override of the load routine set the metadata
      str_element, dl, 'units', success=exists
      if exists then out.units = dl.units
      
      str_element, dl, 'data_att', success=data_att_exists
      if data_att_exists then begin
        str_element, dl.data_att, 'units', success=exists
        if exists then out.units = dl.data_att.units
      endif
      
      str_element, dl, 'ztitle', success=ztitle_exists
      if ztitle_exists then out.ztitle = dl.ztitle
      
      str_element, dl, 'ytitle', success=ytitle_exists
      if ytitle_exists then out.ytitle = dl.ytitle
      
      str_element, dl, 'labels', success=labels_exists
      if labels_exists then str_element, out, 'labels', dl.labels, /add
      
      str_element, dl, 'spec', success=exists
      if exists && byte(dl.spec) ne 0 then out.spec = 1b
    endif
    if is_struct(l) then begin
      ; try to extract data from the limits last, as 'limits' are set by the user
      str_element, l, 'units', success=exists
      if exists then out.units = l.units

      str_element, l, 'data_att', success=data_att_exists
      if data_att_exists then begin
        str_element, l.data_att, 'units', success=exists
        if exists then out.units = l.data_att.units
      endif

      str_element, l, 'ztitle', success=ztitle_exists
      if ztitle_exists then out.ztitle = l.ztitle

      str_element, l, 'ytitle', success=ytitle_exists
      if ytitle_exists then out.ytitle = l.ytitle

      str_element, l, 'labels', success=labels_exists
      if labels_exists then str_element, out, 'labels', l.labels, /add
      
      str_element, l, 'spec', success=exists
      if exists && byte(l.spec) ne 0 then out.spec = 1b
    endif
    
    return, out
end