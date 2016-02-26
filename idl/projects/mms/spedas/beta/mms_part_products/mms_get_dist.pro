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
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-25 09:48:42 -0800 (Thu, 25 Feb 2016) $
;$LastChangedRevision: 20175 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_get_dist.pro $
;-

function mms_get_dist, tname, index, trange=trange, times=times, structure=structure

    compile_opt idl2, hidden



if stregex(tname, 'mms[1-4]_.*_.{4}SkyMap_dist', /bool, /fold) then begin
  
  ;fpi-l1b
  return, mms_get_fpi_dist(tname, index, trange=trange, times=times, structure=structure)

endif else if stregex(tname, 'mms[1-4]_.*_dist_.{4}', /bool, /fold) then begin

    ;fpi-l2
    return, mms_get_fpi_dist(tname, index, trange=trange, times=times, structure=structure , level='l2', data_rate=strmid(tname,14,4), species=strmid(tname,6,1), probe=strmid(tname,3,1))

endif else if stregex(tname, 'mms[1-4]_.*_vel_dist_fn', /bool, /fold) then begin

  ;hpca
  return, mms_get_hpca_dist(tname, index, trange=trange, times=times, structure=structure)

endif else begin

  dprint, dlevel=1, 'Instrument not recognized from intput name: '+tname
  return, 0

endelse

end