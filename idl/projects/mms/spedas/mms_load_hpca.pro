;+
; PROCEDURE:
;         mms_load_hpca
;         
; PURPOSE:
;         Load data from the MMS Hot Plasma Composition Analyzer (HPCA)
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         local_data_dir: local directory to store the CDF files
;         varformat: format of the variable names in the CDF to load
;         no_color_setup: don't setup graphics configuration; use this
;             keyword when you're using this load routine from a
;             terminal without an X server running
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-09-29 12:07:31 -0700 (Tue, 29 Sep 2015) $
;$LastChangedRevision: 18956 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_hpca.pro $
;-

function mms_hpca_elevations
    anode_theta = [123.75000, 101.25000, 78.750000, 56.250000, 33.750000, $
        11.250000, 11.250000, 33.750000, 56.250000, 78.750000, $
        101.25000, 123.75000, 146.25000, 168.75000, 168.75000, $
        146.25000]
    anode_theta[6:13] += 180.
    return, anode_theta
end

function mms_hpca_anodes, fov = fov
    if undefined(fov) then begin
        dprint, dlevel = 0, 'Error, must give a field of view'
        return, -1
    endif
    
    anodes = mms_hpca_elevations()
    
    fov_tmp = float(fov)
    anodes_in_fov = where(anodes ge fov_tmp[0] and anodes le fov_tmp[1], anode_count)
    return, anodes_in_fov
end


function mms_hpca_energies
    return, [1.35500, 1.57180, 1.84280, 2.22220, 2.60160, 3.08940, 3.63140, 4.28180, $
        5.04060, 5.96200, 6.99180, 8.23840, 9.75600, 11.4904, 13.5500, 15.9890, $
        18.8616, 22.2762, 26.2328, 30.9482, 36.5308, 43.0890, 50.7854, 59.9452, $
        70.6768, 83.4138, 98.3730, 116.042, 136.855, 161.462, 190.459, 224.659, $
        264.984, 312.571, 368.723, 434.955, 513.057, 605.197, 713.868, 842.051, $
        993.323, 1171.70, 1382.10, 1630.28, 1923.07, 2268.43, 2675.80, 3156.28, $
        3723.11, 4391.72, 5180.44, 6110.72, 7208.11, 8502.57, 10029.5, 11830.6, $
        13955.2, 16461.4, 19417.5, 22904.6, 27017.9, 31869.8, 37593.1]
end
   
; Input:
;       data_struct: structure containing: {x: times, y: flux}
;
; Keywords:
;       fov: field of view
;
;
; averages over elevation angles inside the field of view
;
; output:
;   structure containing {x: times, y: flux, v: energies} 
function mms_hpca_avg_fov, data_struct, fov = fov, anodes = anodes
    if ~is_struct(data_struct) then begin
        dprint, dlevel = 0, 'Error - invalid structure.'
        return, -1
    endif
    if ~undefined(fov) and ~undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, should only specify a field of view (fov) or list of anodes, but not both.'
        return, -1
    endif
    if undefined(fov) and undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, must specify either field of view or a list of anodes'
        return, -1
    endif
    if undefined(fov) then anodes_in_fov = anodes else anodes_in_fov = mms_hpca_anodes(fov=fov)
    
    times = data_struct.X
    
    ;anode_elevation = mms_hpca_elevations()
    energies = mms_hpca_energies()
    
    if n_elements(anodes_in_fov) eq 1 then data_total = reform(data_within_fov) else data_total = total(data_within_fov, 3, /nan)

    data_mean = dblarr(n_elements(times), n_elements(energies))
    data_mean = average(data_within_fov, 3, /nan)

    data_mean(where(data_mean eq 0.)) = !VALUES.F_NAN
    return, {x: times, y: data_mean, v: energies}
end

; Input:
;       data_struct: structure containing: {x: times, y: flux}
;  
; Keywords:
;       fov: field of view
;       
;  
; sums over elevation angles inside the field of view
; 
; output:
;   structure containing {x: times, y: flux, v: energies}

function mms_hpca_sum_fov, data_struct, fov = fov, anodes = anodes
    if ~is_struct(data_struct) then begin
        dprint, dlevel = 0, 'Error - invalid structure.'
        return, -1
    endif
    if ~undefined(fov) and ~undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, should only specify a field of view (fov) or list of anodes, but not both.'
        return, -1
    endif
    if undefined(fov) and undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, must specify either field of view or a list of anodes'
        return, -1
    endif
    if undefined(fov) then anodes_in_fov = anodes else anodes_in_fov = mms_hpca_anodes(fov=fov)
    times = data_struct.X

    ;anode_elevation = mms_hpca_elevations()
    energies = mms_hpca_energies()

    data_within_fov = data_struct.Y[*,*,anodes_in_fov]
    
    data_total = dblarr(n_elements(times), n_elements(energies)) 
    if n_elements(anodes_in_fov) eq 1 then data_total = reform(data_within_fov) else data_total = total(data_within_fov, 3, /nan)

    data_total(where(data_total eq 0.)) = !VALUES.F_NAN
    return, {x: times, y: data_total, v: energies}
end

pro mms_hpca_calc_anodes, tplotnames=tplotnames, fov=fov, probe=probe, anodes = anodes
    sum_anodes = ['*_count_rate', '*_RF_corrected', '*_bkgd_corrected', '*_norm_counts']
    if ~undefined(fov) and ~undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, should only specify a field of view (fov) or list of anodes, but not both.'
        return
    endif
    if undefined(fov) and undefined(anodes) then begin
        dprint, dlevel = 0, 'Error, must specify either field of view or a list of anodes'
        return
    endif
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    if undefined(tplotnames) then tplotnames = tnames()
    
    if ~undefined(fov) then begin
        fov_str = strcompress('_elev_'+string(fov[0])+'-'+string(fov[1]), /rem)
    endif else fov_str = '_anodes_' + strjoin(strcompress(string(anodes), /rem), '_')
    
    ;avg_anodes = ['*_flux', '*_vel_dist_fn']
    ; removed velocity distribution from above because
    ; we need the full (non-avg'd) data for 2d slices
    avg_anodes = ['*_flux']
    
    for sum_idx = 0, n_elements(sum_anodes)-1 do begin
        vars_to_sum = strmatch(tplotnames, sum_anodes[sum_idx])
        for vars_idx = 0, n_elements(vars_to_sum)-1 do begin
            if vars_to_sum[vars_idx] eq 1 then begin
                get_data, tplotnames[vars_idx], data=var_data, dlimits=var_dl
                if is_struct(var_data) then begin
                    updated_spectra = mms_hpca_sum_fov(var_data, fov=fov, anodes=anodes)
                    store_data, tplotnames[vars_idx]+fov_str, data=updated_spectra, dlimits=var_dl
                    append_array, tplotnames, tplotnames[vars_idx]+fov_str
                endif
            endif
        endfor
    endfor

    for avg_idx = 0, n_elements(avg_anodes)-1 do begin
        vars_to_avg = strmatch(tplotnames, avg_anodes[avg_idx])
        for vars_idx = 0, n_elements(vars_to_avg)-1 do begin
            if vars_to_avg[vars_idx] eq 1 then begin
                get_data, tplotnames[vars_idx], data=var_data, dlimits=var_dl
                if is_struct(var_data) then begin
                    updated_spectra = mms_hpca_avg_fov(var_data, fov=fov, anodes=anodes)
                    store_data, tplotnames[vars_idx]+fov_str, data=updated_spectra, dlimits=var_dl
                    append_array, tplotnames, tplotnames[vars_idx]+fov_str
                endif
            endif
        endfor
    endfor
    mms_hpca_set_metadata, tplotnames, prefix = 'mms'+probe, fov = fov, anodes = anodes
end
pro mms_load_hpca, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, varformat = varformat, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update
                

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'ion'
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(varformat) then begin
       ; allow for the following datatypes:
       ; count_rate, flux, vel_dist, rf_corr, bkgd_corr
       case datatype of 
            'ion': varformat = '*_RF_corrected'
            'rf_corr': varformat = '*_RF_corrected'
            'count_rate': varformat = '*_count_rate'
            'flux': varformat = '*_flux'
            'vel_dist': varformat = '*_vel_dist_fn'
            'bkgd_corr': varformat = '*_bkgd_corrected'
            'moments': varformat = '*'
            else: varformat = '*_RF_corrected'
       endcase
       if ~undefined(varformat) && varformat ne '*' then datatype = 'ion'
       
    endif
    ;if level eq 'sitl' then varformat = '*'
    
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'hpca', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, varformat = varformat, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update
    
    if undefined(tplotnames) then return
    
    ; if the user requested HPCA ion data, need to:
    ; 1) sum over anodes for normalized counts, count rate, 
    ;    RF and background corrected count rates
    ; 2) average over anodes for flux, velocity distributions
    ;if datatype eq 'ion' then mms_hpca_calc_anodes, tplotnames=tplotnames, fov=fov, probes=probes

    for probe_idx = 0, n_elements(probes)-1 do mms_hpca_set_metadata, tplotnames, prefix = 'mms'+probes[probe_idx]
end