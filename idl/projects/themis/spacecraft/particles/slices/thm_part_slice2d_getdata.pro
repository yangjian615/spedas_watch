;+
;Procedure:
;  thm_part_slice2d_getdata
;
;
;Purpose:
;  Helper function for thm_part_slice2d.pro
;  Returns an array of averaged data along with the corresponding
;  bin centers and widths in spherical coordinates. This routine
;  will apply energy range constraints and count thresholds.
;  
;         
;Input:
;  dist_array: Array of 3d data structures
;  units: String descriping the units desired
;  count_threshold: Mask out bins with counts below the specified value.
;                 If not already working in counts the value will
;                 be converted to the specified units.
;                (after averaging -> before averaging - 2012-12-21)
;                (allow specified value - 2013-02-25)
;  regrid: 3 Element array specifying the new number of points desired in 
;          phi, theta, and energy respectively.
;  erange: Two element array specifying min/max energies to be used
;   
;   
;Output:
;  data: N element array containing interpolated particle data
;  rad: N element array of bin centers along r (eV or km/s)
;  phi: N element array of bin centers along phi
;  theta: N element array of bin centers along theta
;  dr: N element array of bin widths along r (eV or km/s)
;  dp: N element array of bin widths along phi
;  dt: N element array of bin widths along theta
; 
; 
;Notes:
;
; 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-05-16 15:53:53 -0700 (Fri, 16 May 2014) $
;$LastChangedRevision: 15157 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice2d_getdata.pro $
;-

pro thm_part_slice2d_getdata, ptr_array, units=units, trange=trange, $ 
                             regrid=regrid, erange=erange, energy=energy, $
                             count_threshold=count_threshold, subtract_counts=subtract_counts, $
                             sst_sun_bins=sst_sun_bins, $
                             rad=rad_out, phi=phi_out, theta=theta_out, $
                             dp=dp_out, dt=dt_out, dr=dr_out, $
                             data=data_out, $
                             fail=fail, $
                             _extra=_extra

    compile_opt idl2, hidden


  thm_part_slice2d_const, c=c

  units_lc = strlowcase(units)

  ;------------------------------------------------------------------
  ;Loop over pointers (modes/datatypes)
  ;------------------------------------------------------------------
  for j=0, n_elements(ptr_array)-1 do begin
      
      
    ;This prevents the previous iterations' data and coordinates from being reused.
    ;TBD: Coordinate collation could be performed outside the loop below.
    if ~undefined(data_t) then undefine, data_t
    if ~undefined(weight_t) then undefine, weight_t
    if ~undefined(rad) then undefine, rad
    if ~undefined(phi) then undefine, phi
    if ~undefined(theta) then undefine, theta
    if ~undefined(dr) then undefine, dr
    if ~undefined(dp) then undefine, dp
    if ~undefined(dt) then undefine, dt
    
    
    ;Get indexes of dat structures in reqested time window
    times_ind = thm_part_slice2d_intrange(ptr_array[j], trange, n=ndat)
    if ndat eq 0 then begin
      missing = keyword_set(missing) ? missing++:1
      dprint, dlevel=2, 'No '+(*ptr_array[j])[0].data_name+' data in time range: ' + $
                        time_string(trange[0])+ ' - ' + time_string(trange[1])
      continue
    endif
    
    
    ;Determine data type for sanitization
    thm_pgs_get_datatype, ptr_array[j], instrument=instrument
    
    
    ;------------------------------------------------------------------
    ;Loop over sample times
    ;------------------------------------------------------------------
    for i=0, n_elements(times_ind)-1 do begin

      ;Verify that bins do not differ from the last sample
      ;In general, this code assumes it is being called on a similar set of 3d data structs
      if ~thm_part_checkbins(( (*ptr_array[j])[times_ind] )[i], $
                             ( (*ptr_array[j])[times_ind] )[i-1 > 0], msg=msg) then begin 
        fail = msg
        dprint,dlevel=0, fail
        return
      endif
      
      ;Use standard particle sanitization routines to perform unit
      ;conversion and contamination removal.
      if instrument eq 'esa' then begin
        thm_pgs_clean_esa, ( (*ptr_array[j])[times_ind] )[i], units_lc, output=dist, _extra=ex
      endif else if instrument eq 'sst' then begin
        thm_pgs_clean_sst, ( (*ptr_array[j])[times_ind] )[i], units_lc, output=dist, sst_sun_bins=sst_sun_bins,_extra=ex
      endif else if instrument eq 'combined' then begin
        thm_pgs_clean_cmb, ( (*ptr_array[j])[times_ind] )[i], units_lc, output=dist
      endif else begin
        dprint,dlevel=0,'WARNING: Instrument type unrecognized'
        return
      endelse 
      
      ;Find active, valid bins.
      bins = (dist.bins ne 0) and finite(dist.data)
  
      ;Find bins within energy limits
      if keyword_set(erange) then begin
        n = dimen1(dist.energy)
        energies = thm_part_slice2d_ebounds(dist)
        ecenters = (energies[0:n-1,*]+energies[1:n,*])/ 2
        bins = bins and (ecenters ge erange[0] and ecenters le erange[1])
      endif
  
      ;Get extract data & coordinates
      if keyword_set(regrid) then begin
      
        ;Regrid in spherical coordinates
        dist.bins = bins ;ensure energy limited bins are used for regridding
        thm_part_slice2d_regridsphere, dist, regrid=regrid, energy=energy, fail=fail,$ 
                   data=data, bins=bins, rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt
      
      endif else begin
      
        ;Get center of each bin plus dphi, dtheta, dr
        thm_part_slice2d_getsphere, dist, energy=energy, fail=fail, $
                   data=data, rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt
        
      endelse
                                 
      if keyword_set(fail) then return
    
    
      ;Sum of counts over all time samples
      data_t = keyword_set(data_t) ? data_t+data:data
  
  
      ;Keep track of valid bins within energy range.  This array will later be used
      ;to average bins and discard any that are out of range or invalid.
      weight_t = keyword_set(weight_t) ? (weight_t + bins):bins
      
    endfor
    ;------------------------------------------------------------------
    ;End loop over sample times
    ;------------------------------------------------------------------
    
    
    ;Average data over number of time samples containging valid measurements
    data_ave = temporary(data_t) / (weight_t > 1)
    
    
    ;Remove/subtract count limit from data.
    ;**One-count removal performed before averaging from 2012-12-21 to 2013-07-02.**
    ;  -a unit conversion is often required here so use un-sanitized structure
    ;  -invalid bins are removed independently from this 
    thm_part_slice2d_climit, ( (*ptr_array[j])[times_ind] )[0], data_ave, $
      units=units, regrid=regrid, subtract_counts=subtract_counts, count_threshold=count_threshold
  
  
    ;Remove bins with no valid data
    ;Each distribution may have a different set of bins active
    ;so this should be done after the data is averaged.
    valid = where(weight_t gt 0, nvalid)
    if nvalid gt 0 then begin
      data_ave = data_ave[valid]
      rad = rad[valid]
      phi = phi[valid]
      theta = theta[valid]
      if keyword_set(dr) then begin
        dr = dr[valid]
        dp = dp[valid]
        dt = dt[valid]
      endif
    endif else begin
      fail = 'No valid data in distribution(s).  '+ $
             'This is may be due to stringent energy limits, '+ $
             'count threshold, or other constraints.'
      dprint, dlevel=1, fail
      return
    endelse


    ;Concatenate data and coordinates
    data_out = array_concat(temporary(data_ave),data_out)
    
    rad_out = array_concat(temporary(rad),rad_out)
    phi_out = array_concat(temporary(phi),phi_out)
    theta_out = array_concat(temporary(theta),theta_out)
    
    dr_out = array_concat(temporary(dr),dr_out)
    dp_out = array_concat(temporary(dp),dp_out)
    dt_out = array_concat(temporary(dt),dt_out)

  
  
  endfor
  ;------------------------------------------------------------------
  ;End loop over pointers
  ;------------------------------------------------------------------
  
  
  ;Check that data was found in the time range
  if keyword_set(missing) && missing eq n_elements(ptr_array) then begin
    fail = 'No distributions exist within the given time window: '+ $
           time_string(trange[0])+ ' + '+strtrim(trange[1],2)+' sec).'
    dprint, dlevel=0, fail
    return  
  endif
  

  return
  
end
