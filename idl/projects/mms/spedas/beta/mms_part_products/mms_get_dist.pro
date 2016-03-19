;+
;Procedure:
;  mms_get_dist
;
;
;Purpose:
;  Retrieve particle distribution structures/pointers from data loaded
;  into tplot. 
;
;
;Calling Sequence:
;  data = mms_get_dist( input_name [,trange=trange] [/times] [/structure]
;
;
;Input:
;  input_name:  Name of tplot variable containing particle data (must be original name)
;  trange:  Optional two element time range
;  times:  Flag to return array of full distribution sample times
;  structure:  Flag to return structures instead of pointer to structures
;
;
;Output:
;  return value:  Pointer to structure array or structure array if /structure used.
;                 Array of times if /times is used
;                 0 for any error case
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-18 17:31:20 -0700 (Fri, 18 Mar 2016) $
;$LastChangedRevision: 20511 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_get_dist.pro $
;-

function mms_get_dist, tname, index, trange=trange, times=times, structure=structure, $
                       probe=probe, species=species, instrument=instrument

    compile_opt idl2, hidden


if undefined(instrument) then begin
  instrument = 'null'
  if stregex(tname, '^mms[1-4]_hpca_', /bool) then instrument = 'hpca'
  if stregex(tname, '^mms[1-4]_d[ei]s_', /bool) then instrument = 'fpi'
endif


case strlowcase(instrument) of
  'hpca': return, mms_get_hpca_dist(tname, index, trange=trange, times=times, structure=structure, probe=probe, species=species)
  'fpi': return, mms_get_fpi_dist(tname, index, trange=trange, times=times, structure=structure, probe=probe, species=species)
  'null': dprint, dlevel=1, 'Cannot determine instrument from variable name; please specify with INSTRUMENT keyword'
  else: dprint, dlevel=1, 'Unknown instrument: "'+instrument+'"'
endcase

return, 0

end