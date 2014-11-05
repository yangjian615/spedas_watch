;+
;PROCEDURE: 
;	mvn_swe_n3d
;PURPOSE:
;	Determines density from a 3D distribution.  Adapted from McFadden's n_3d.pro.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_n3d
;INPUTS: 
;KEYWORDS:
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_n3d.pro $
;
;-

pro mvn_swe_n3d, ebins=ebins, abins=abins, dbins=dbins, pans=pans, archive=archive

  compile_opt idl2

  @mvn_swe_com
  
; Make sure data are loaded

  if (size(swe_3d,/type) ne 8) then begin
    print,"Load SWEA data first.  Use mvn_swe_load_l0."
    return
  endif
  
  if (size(swe_sc_pot,/type) ne 8) then begin
    print,"No spacecraft potential.  Use mvn_swe_sc_pot."
    return
  endif
  
  if keyword_set(archive) then aflg = 1 else aflg = 0
    
  if (aflg) then t = swe_3d_arc.time else t = swe_3d.time
  npts = n_elements(t)
  density = fltarr(npts)
  
  for i=0L,(npts-1L) do begin
    ddd = mvn_swe_get3d(t[i],archive=aflg,units='eflux')
    density[i] = swe_n_3d(ddd,ebins=ebins,abins=abins,dbins=dbins)
  endfor
  
; Create TPLOT variables

  store_data,'swe_3d_n',data={x:t, y:density}
  options,'swe_3d_n','ytitle','Ne (1/cc)'
  pans = ['swe_3d_n']
  
  return

end
