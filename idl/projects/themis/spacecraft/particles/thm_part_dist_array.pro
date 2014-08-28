

;+
; Purpose:
;   Find the sun direcion vector if requested
;
;-
function thm_part_dist_array_getsun, probe=probe, times=times, fail=fail

    compile_opt idl2, hidden

  
  ctn = '2dslice_temp_sundir'
  nt = n_elements(times)
   
  ; Caculation needed for dsl
  dprint, dlevel=4, 'Finding sun direction in DSL...'


  thm_load_state, probe=probe, trange=minmax(times) + 120*[-1,1], suffix='_'+ctn, $
                  /get_support_data

  ;Transform GSE x-axis (defined by sun)
  store_data, ctn, data = {x: times, $
                           y: [1.,0,0] ## replicate(1,nt) }
  thm_cotrans, ctn, probe=probe, in_coord='gse', out_coord='dsl', $
               support_suffix='_'+ctn, out_suff='_dsl'


  ;Return array of transformed vectors
  get_data, ctn+'_dsl', data=ctd
  if size(ctd,/type) ne 8 then begin
    fail = 'Could not obtain coordinate transform from GSE -> DSL'+ $
           ', check for error from THM_COTRANS.'
    dprint, dlevel=0, fail
    return, -1
  endif
  sundir = ctd.y
  
  
  ;Delete temporary tplot data
  store_data, '*'+ctn+'*', /delete


  return, sundir

end



;+
;
;Procedure: thm_part_dist_array
;
;Purpose: Returns an array of pointers to ESA or SST particle distributions.(One pointer for new mode in the time series)  This routine
;         is a wrapper for thm_part_dist, which returns single distributions.
;
;
;Required Keywords:
; PROBE: The THEMIS probe, 'a','b','c','d','e'.
; DATATYPE: Four character string denoting the type of data that you need.
;          ESA Ions (full/reduced/burst)
;            'peif' - Full mode
;            'peir' - Reduced mode
;            'peib' - Burst mode
;          ESA Electrons
;            'peef' - Full
;            'peer' - Reduced
;            'peeb' - Burst 
;          SST Ions 
;            'psif' - Full
;            'psir' - Reduced
;          SST Electrons 
;            'psef' - Full 
;            'pser' - Reduced
;            'pseb' - Burst
; TRANGE: Time range of interest (2 element array, string or numerical).
;         *This keyword may be ommitted if 'timespan is set. If neither 
;          TRANGE nor 'timespan' is set the user will be prompted.
;
;
;Optional Keywords:
; MAG_DATA: Tplot variable containing magnetic field data. The data will be 
;           interpolated to the cadence of the requested particle distribution
;           and added to the returned structures under the tag 'MAGF'.
; VEL_DATA: Tplot variable containing velocity data. The data will be 
;           interpolated to the cadence of the requested particle distribution
;           and added to the returned structures under the tag 'VELOCITY'.
;           If not set V_3D_NEW.PRO will be used instead.
; SST_CAL: Flag to use new SST calibrations (BETA)
; GET_SUN_DIRECTION: Adds sun direction vector to the returned structures
;           under the tag 'SUN_VECTOR'
; FRACTIONAL_COUNTS: Flag to keep the ESA unit conversion routine from rounding 
;                    to an even number of counts when removing the dead time 
;                    correction (no effect if input data already in counts, 
;                    no effect on SST data). This will only be used by this
;                    code when calculating the bulk velocity with V_3D_NEW.PRO
; 
; 
; 
;Other Keywords:
; FORMAT: (old) Single string that can be used instead of PROBE and DATATYPE
;                (e.g. 'thb_psif' or 'tha_peeb')
; 
; 
;Examples:  
;           dist_array = thm_part_dist_array(probe='b',datatype='pseb', $
;                                            trange='2008-2-26/04:'+['50:00','55:00'])
;           
;           timespan, '2008-2-26/04:50:00', 5, /min
;           dist_array = thm_part_dist_array(probe='b',datatype='psif', $
;                                            vel_data='tplot_vel', $
;                                            mag_data='tplot_mag')
;
;
;Contamination Removal:
;
; BACKGROUND REMOVAL(BGND) Description, Warnings and Caveats(from Vassilis Angelopoulos):
; This code allows for keywords that permit omni-directional or anode-dependent
; background removal from penetrating electrons in the ESA ion and electron 
; detectors. Anode-dependent subtraction is used when possible by default,
; i.e., when angle information is available; but user has full control by
; keyword specification. Default bgnd estimates use 3 lowest counts/s values.
; Scaling of the background (artificial scaling) can also allow playing with
; background estimates to account for noise statistics in the background itself.
; The parameters that have worked well for me during high bgnd levels are:
; ,/bgnd_remove, bgnd_type='anode', bgnd_npoints=3, bgnd_scale=1.5
;
; This background subtraction to be used at the inner magnetosphere,
; or when SST electron fluxes indicate presence of significant electron
; fluxes at the satellite (injections). At quiet times the code tends to remove
; real fluxes, so beware.
; 
; Crib sheets for contamination removal with are listed below in 'See Also'.
; The same keywords are valid for this code; a few are documented below.
; 
;Contamination/Background Keywords:
;
; The following keywords are passed to the appropriate data retrieval routines. 
; The resulting distributions will have the specified contamination removal applied.
; 
; ESA Keywords:
;   BGND_REMOVE: Flag to turn on ESA background removal.
;   BGND_TYPE: String naming removal type, e.g. 'angle','omni', or 'anode'.
;   BGND_NPOINTS: Number of lowest values points to average over when determining background.
;   BGND_SCALE: Scaling factor that the background will be multiplied by before it is subtracted.
; 
; SST Keywords:
;
;   Check the list of keywords in THM_SST_REMOVE_SUNPULSE for more.
;
;   MASK_REMOVE: Set this keyword to the proportion of values that must be 0 at 
;                all energies to determine that a mask is present. Generally .99 
;                or 1.0 is a good value. The mask is a set of points that are set 
;                to 0 on-board the spacecraft.  By default they will be filled by 
;                linear interpolation across phi.
;
;   METHOD_SUNPULSE_CLEAN:  set this to a string:  Either 'median' or 'spin_fit' or 'z_score_mod'
;              'median':  This will remove all points that are greater 
;                than 2.0 standard deviations from the median.By default they will be filled by a 
;                linear interpolation across the phi angle by default. 
;              'spin_fit':  This will remove all points that are greater
;                than 2.0 standard deviations from a spin fit across phi angle.  The equation used to
;                fit is A+B*sin(phi)+C*cos(phi). By default these points will be filled by a linear
;                interpolation across the phi angle. The fitting is done using the svdfit routine
;                from the idl distribution.
;              'z_score_mod': This will remove all points that have a modified z-score(calculated across phi) greater than 3.5 
;                The modified z-score is a normalized outlier detection test defined as follows:  
;                #1 X_Bar = median(X+1)
;                #2 Sigma = MAD = Median Absolute Deviation = median(abs(X-X_Bar))
;                #3 Z_Score_Mod = .6745*(X - X_Bar)/Sigma
;                This test can often get excellent results because it is insensitive to variation in standard deviation
;                and skew in the distributions.  
;   FILLIN_METHOD: Set this keyword to a string that specifies the method used to fill the points that are
;             removed via the method_sunpulse_clean or the mask_remove keywords.
;             If 'interpolation' is set, this routine will interpolate across the phi angle.  This is the 
;               default behavior. Interpolation is done using the interp_gap routine.
;             If 'spin_fit' is set this routine will perform a spin fit to the data after the points
;               have been removed using the equation A+B*sin(phi)+C*cos(phi).  It will then generate
;               expected values for each removed phi using the equation of fit.   The fitting is done using
;               the svdfit routine from the idl distribution.  Note that if 'spin_fit' is selected for
;               the clean method and the fill method, this routine will perform two spin fits.
;   LIMIT_SUNPULSE_CLEAN: set this equal to a floating point number that will override the default of 2.0 standard
;             deviation tolerance or 3.5 z_score_tolerance, used by the sunpulse cleaning methods by default.
;             This keyword will only have an effect if the method_sunpulse_clean keyword is set.

;   
;   ENOISE_BINS: A 0-1 array that indicates which bins should be used to calculate 
;               electronic noise.  A 0 indicates that the bin should be used for 
;               electronic noise calculations.  This is basically the output from 
;               the bins argument of edit3dbins. It should have dimensions 16x4.
;   ENOISE_REMOVE_METHOD: (default: 'fit_median') set the keyword to a string specifying the method you want to use to calculate the electronic noise that will be subtracted 
;               This function combines values across time.  The allowable options are:
;                 'min':  Use the minimum value in the time interval for each bin/energy combination.
;                 'average': Use the average value in the time interval for each bin/energy combination.
;                 'median': Use the median value in the time interval for each bin/energy combination.
;                 'fit_average': Fill in selected bins with a value that is interpolated across phi then subtracts the average of the difference
;                                between the interpolated value and the actual value from each selected bin/energy combination.
;                 'fit_median': Fill in selected bins with a value that is interpolated across phi then subtracts the median of the difference
;                               between the interpolated value and the actual value from each selected bin/energy combination.
;                 'fill': Fill the selected bins using the technique specified by enoise_remove_method_fit, or interpolation by default.
;                         (note that if this method is used, enoise_bgnd_time is not required)
;   ENOISE_REMOVE_FIT_METHOD: (default:'interpolation'):  Set this keyword to control the method used in 'fit_average' & 'fit_median' to
;                    fit across phi. Options are 'interpolation' & 'spin_fit' By default, missing bins are interpolated across phi.  Setting
;                    enoise_remove_fit_method='spin_fit' will instead try to fill by fitting to a curve of the form A+B*sin(phi)+C*cos(phi).
;   ENOISE_BGND_TIMES: This should be either a 2 element array or a 2xN element array(where n is the number of elements in enoise_bins).  
;                    The arguments represents the start and end times over which the electronic background will be calculated for each
;                    bin.  If you pass a 2 element array the same start and end times can be used for each bin.  If you pass a 2xN element
;                    array, then the Ith bin in enoise_bins will use the time enoise_bgnd_time[0,I] as the start time and enoise_bgnd_time[1,I] as
;                    the end time for the calculation of the background for that bin.  If this keyword is not set then electronic noise will not 
;                    be subtracted.
;
;
;See Also: thm_part_slice2d, thm_clib_part_slice2d, 
;          thm_crib_esa_bgnd_remove, thm_esa_bgnd_remove, 
;          thm_crib_sst_contamination, thm_sst_remove_sunpulse
;
;
;Created by Bryan Kerr
;Modified by A. Flores
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-01-15 11:30:30 -0800 (Wed, 15 Jan 2014) $
; $LastChangedRevision: 13905 $
; $URL $
;-

function thm_part_dist_array, format=format, trange=trange, type=type, datatype=datatype, $
                              probe=probe, mag_data=mag_data, vel_data=vel_data, $
                              get_sun_direction=get_sun_direction, $
                              suffix=suffix, err_msg=err_msg, $
                              gettimes=gettimes, sst_cal=sst_cal, $
                              _extra = _extra 

  compile_opt idl2


if keyword_set(type) && ~keyword_set(datatype) then datatype=type

if keyword_set(probe) && keyword_set(datatype) then begin
  probe = strlowcase(probe)
  dtype = strlowcase(datatype)
  format = 'th'+probe+'_'+dtype
endif else if keyword_set(format) then begin
  format = strlowcase(format)
  probe = strmid(format,2,1)
  dtype  = strmid(format,4,4)
endif else begin
  err_msg = 'Must provide PROBE and DATATYPE keywords.'
  dprint, dlevel=1, err_msg
  return, -1
endelse


inst = strmid(dtype,1,1)
species = strmid(dtype,2,1)


; check requested probe
dummy = where(probe eq ['a','b','c','d','e'], yes_probe)
if yes_probe lt 1 then begin
  dprint, dlevel=1, 'Invalid probe: ' + probe
  return, -1
endif

; check requested instrument type
if inst ne 'e' && inst ne 's' then begin
  dprint, dlevel=1, 'Invalid instrument type: ' + inst
  return, -1
endif

; check requested species
if species ne 'e' && species ne 'i' then begin
  dprint, dlevel=1, 'Invalid species: ' + species
  return, -1
endif


; copy time range to new variable(s) and make sure timespan gets set
if keyword_set(trange) then begin
   trd = minmax(time_double(trange))
   tr = time_string(trd)
   ndays = (trd[1] - trd[0]) / 86400
   timespan,trd[0],ndays
endif else begin
   trd = timerange()
   tr = time_string(trd)
endelse


; load L1 data
; ESA
if inst eq 'e' then begin
  thm_load_esa_pkt, probe=probe, trange=tr, datatype=dtype, suffix=suffix, _extra=_extra
; SST
endif else begin
  ;beta SST calibrations only working for full/burst data
  if keyword_set(sst_cal) then begin
    if strmid(format,7,1) eq 'f' || strmid(format,7,1) eq 'b' then begin
      thm_load_sst2, probe=probe, trange=tr, datatype=dtype, suffix=suffix, _extra=_extra
    endif else begin
      err_msg = 'Beta SST calibrations only available for full and burst data'
      dprint, dlevel=1, err_msg
      return, -1
    endelse
  endif else begin
    thm_load_sst, probe=probe, trange=tr, suffix=suffix, _extra=_extra
  endelse
endelse


; get time indexes of data in requested time range
times = thm_part_dist(format, /times, sst_cal=sst_cal)
if size(times,/type) eq 8 then begin
  err_msg = 'Unable to retrieve times for th'+probe+'_'+dtype+ $
            ' between ' +tr[0]+ ' and ' +tr[1]+ '.' 
  dprint, err_msg
  return, -1
endif


;time correction to point at bin center is applied for ESA, but not for SST
if inst eq 's' then begin
  times += 1.5
endif


;return times if requested
if keyword_set(gettimes) then return, times


; check that data exists in requested range
time_ind = where(times ge trd[0] and times le trd[1], n_times) 
if (size(times,/type) ne 5) or (n_times lt 1) then begin
  err_msg = 'No '+format+' data for time range '+tr[0]+ $
             ' to '+tr[1]+'.' 
  dprint, err_msg
  return, -1
endif 


enoise_tot = thm_sst_erange_bin_val('th'+probe, dtype[0], times, _extra=_extra,sst_cal=sst_cal)
mask_tot = thm_sst_find_masking('th'+probe, dtype[0], time_ind, _extra=_extra,sst_cal=sst_cal)


;interpolate mag data  
if keyword_set(mag_data) then begin

  tinterpol_mxn, mag_data, times[time_ind], /nan_extrapolate, error=success
  
  if success then begin
    get_data, mag_data+'_interp', data=d
    mag = d.y
    add_mag_data = 1b
  endif else begin
    err_msg = 'Unable to interpolate B field data from "'+ mag_data + $
      '". Variable may not exist or may not cover the requested time range.'
    dprint, dlevel=1, err_msg
    return, -1
  endelse

endif


;add default velocity data if not specified from tplot variable
;if ~keyword_set(vel_data) then vel_auto = 1b

;interpolate velocity data
if keyword_set(vel_data) then begin

  tinterpol_mxn, vel_data, times[time_ind], /nan_extrapolate, error=success

  if success then begin
    get_data, vel_data+'_interp', data=d
    vel = d.y
    add_vel_data = 1b
  endif else begin
    err_msg = 'Unable to interpolate velocity data from "'+ vel_data + $
      '". Variable may not exist or may not cover the requested time range.'
    dprint, dlevel=1, err_msg
    return, -1
  endelse
endif



;get sun vector (in DSL) if requested
if keyword_set(get_sun_direction) then begin
  sundir = thm_part_dist_array_getsun(probe=probe, times=times[time_ind], fail=fail)
endif



; Find all mode changes.  This will allow pre-allocation of memory 
; for the data structure arrays and bypass costly concatenations
; in the following for loop.
midx = thm_part_getmodechange(probe, dtype, time_ind, sst_cal=sst_cal, n=nsamples)
if nsamples[0] eq 0 then begin
  return, -1
end


;Initialize array of pointers to be returned
dist_ptrs = replicate( ptr_new(), n_elements(midx) )



; Loop to create array
for i=0L,n_times-1 do begin


  dat = thm_part_dist(format, index=time_ind[i], sst_cal=sst_cal,mask_tot=mask_tot,enoise_tot=enoise_tot, _extra=_extra)


  ; add mag data to dat structure
  if keyword_set(add_mag_data) then begin
    str_element, /add, dat, 'magf', reform(mag[i,*])
  endif
  
  
  ; add velocity data to dat structure
  if keyword_set(add_vel_data) then begin
    ; add user specified velocity data to data structure
    str_element, /add, dat, 'velocity', reform(vel[i,*])    
  endif else begin
    ; calculate velocity if not specified
    vel=v_3d_new(dat,_extra=_extra) ;*1000. use km/s 
    str_element, /add, dat, 'velocity', vel
  endelse


  ;add sun direction vector
  if keyword_set(sundir) && n_elements(sundir) gt 1 then begin
    str_element, /add, dat, 'sun_vector', reform(sundir[i,*])
  endif
  
  
  ;Assign pointer to pre-allocated structure array for new mode;
  ;otherwise, place structure into existing array.
  mode = where(i eq midx,n)
  if n gt 0 then begin
  
    dprint, dlevel=2,'New mode encountered at '+time_string(dat.time)
    
    current_mode = mode[0]
    
    ;create new pointer with pre-allocated array
    dist_ptrs[current_mode] = ptr_new( replicate(dat, nsamples[current_mode]), /no_copy )
    dist_count = 1
  
  endif else begin
  
    ;place this structure into the current mode's array
    ( *(dist_ptrs[current_mode]) )[dist_count] = temporary(dat)
    dist_count++
  
  endelse
  
  
;  ; append current dat structure to array of dat structures
;  if keyword_set(dist_arr) then begin
;  
;    ;mode change encountered
;    if ~array_equal( size(dist_arr[0].bins,/dim), size(dat.bins,/dim) ) then begin
;      dprint, dlevel=2,'Mode change encountered at '+time_string(dat.time)
;
;      ;add previous dist_arr to ptr array
;      dist_ptrs = array_concat(ptr_new(dist_arr[0:dist_count-1]),dist_ptrs);add mode pointer to list, if array was overallocated, throw array the excess
;      dist_count=1
;      ;create new dist_arr
;      dist_arr= dat      
;    endif else begin
;      ;higher efficiency concatenation by pre-allocating arrays using exponentially growing array size. (For a small exponent: new_size=old_size^1.05)
;      if n_elements(dist_arr) eq dist_count then begin
;        dist_arr = [dist_arr,replicate(dat,ceil(n_elements(dist_arr)*0.05))] ;new array is 5% larger.  
;      endif
;      
;      ;no mode change, just insert new structure
;      dist_arr[dist_count] = dat
;      dist_count++
;    endelse
;  endif else begin
;    dist_count = 1
;    dist_arr = dat
;  endelse


endfor


;if keyword_set(dist_arr) then begin
;  dist_ptrs=array_concat(ptr_new(dist_arr[0:dist_count-1]),dist_ptrs)
;endif


return, dist_ptrs

end
