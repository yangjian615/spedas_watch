;+
;Procedure:
;  thm_pgs_get_datatype
;
;Purpose:
;  Returns probe and datatype designations from an particle distribution pointer array.
;
;
;Arguments:
;  dist_array: pointer(s) to particle structure arrays
;  
;
;Output Keywords:
;  probe: String denoting probe
;  datatype: String denoting particle data type (e.g. peif, pseb)
;
;  
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-10-09 18:03:13 -0700 (Wed, 09 Oct 2013) $
;$LastChangedRevision: 13298 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_get_datatype.pro $
;-


pro thm_pgs_get_datatype, dist_array, probe=probe, datatype=datatype, units=units

  compile_opt idl2, hidden
      
  ;check existence before indexing pointer
  if keyword_set(dist_array) && ptr_valid(dist_array[0]) then begin
  
    ;probe
    if ~keyword_set(probe) then begin
      probe = strlowcase( (*dist_array[0])[0].spacecraft )
    endif
  
    ;data type  
    if ~keyword_set(datatype) then begin
      case (*dist_array[0])[0].apid of
        '454'x: datatype = 'peif'
        '455'x: datatype = 'peir'
        '456'x: datatype = 'peib'
        '457'x: datatype = 'peef'
        '458'x: datatype = 'peer'
        '459'x: datatype = 'peeb'
        '45a'x: datatype = 'psif'
        '45b'x: datatype = 'psir'
        '45c'x: datatype = 'psib'
        '45d'x: datatype = 'psef'
        '45e'x: datatype = 'pser'
        '45f'x: datatype = 'pseb'
             0: datatype = (*dist_array[0])[0].data_name ;combined dist
        else: begin
          ;this should never happen
          message, 'Error: Cannot determine data type from input distribution.'
        end
      endcase
    endif
    
    
    if ~keyword_set(units) then begin
      units = (*dist_array[0])[0].units_name
    endif
    
  endif
  
  return
  
end