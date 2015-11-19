;+
;Procedure:
;  spd_slice2d_nearest
;
;
;Purpose:
;  Helper function for spd_slice2d.
;  Get a time range that encompasses a specified number of 
;  samples closest to a specified time range.
;
;
;Input:
;  ds: (pointer) Particle distribution pointer array.
;  time: (double) Time near which to search
;  samples: (int/long) Number of samples to use
;
;
;Output:
;  return value: (double) two element time range 
;
;
;Notes:
;  Uses the center of each sample's time window to determine distance.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-11-18 17:57:46 -0800 (Wed, 18 Nov 2015) $
;$LastChangedRevision: 19418 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_nearest.pro $
;
;-
function spd_slice2d_nearest, ds, time, samples

    compile_opt idl2, hidden

  ;number of samples to consider from each pointer (as an index)
  n = undefined(samples) ? 0:samples[0]-1

  for i=0, n_elements(ds)-1 do begin

    ;get distance to each sample
    times = ( (*ds[i]).end_time + (*ds[i]).time )/2  ;use center
    distance = abs(times - time)

    ;get n closest samples
    idx = sort(distance)
    idx = idx[0:n < n_elements(idx)]
    
    ;aggregate full time range
    tr = [ min((*ds[i])[idx].time), max((*ds[i])[idx].end_time) ]
    trange = undefined(trange) ? tr : [ trange[0] < tr[0], trange[1] > tr[1] ]
    
  endfor

  return, trange
  
end
