;+
;Procedure:
;  thm_cmb_clean_sst
;
;
;Purpose:
;  Runs standard SST sanitation routine on data array.
;    -removes excess fields in data structures
;    -performs unit conversion (if UNITS specified)
;    -applies contamination removal (none or default bins)
;
;
;Calling Sequence:
;  thm_cmb_clean_sst, dist_array [,units] [,sst_sun_bins=sst_sun_bins]
;
;Input:
;  dist_array:  SST particle data array from thm_part_dist_array
;  units: String specifying output units
;  sst_sun_bins: Numerical list of contaminated bins to be removed
;
;
;Output:
;  none, modifies input
;  
;
;Notes:
;  Further unit conversions will not be possible after sanitation
;  due to the loss of some support quantities.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-01-10 18:02:25 -0800 (Fri, 10 Jan 2014) $
;$LastChangedRevision: 13850 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_cmb_clean_sst.pro $
;
;-

pro thm_cmb_clean_sst, data, units=units, sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,_extra=ex 

  compile_opt idl2,hidden

  
  ;loop over pointers
  for i=0, n_elements(data)-1 do begin

    ;loop over structures
    for j=0, n_elements(*data[i])-1 do begin
      
      ;sanitization
      thm_pgs_clean_sst, (*data[i])[j], units, output=temp, sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,_extra=ex
      
      ;new struct array must be built
      if j eq 0 then begin
        temp_arr = replicate(temp, n_elements(*data[i]))
      endif else begin
        temp_arr[j] = temp
      endelse
      
    endfor
    
    ;replace data
    ptr_free, data[i]
    data[i] = ptr_new(temp_arr, /no_copy)
    
  endfor
  

end