;+
; Procedure:
;         mms_part_getspec
;
;
; Purpose:
;         This is a wrapper around mms_part_products that loads required 
;         support data (if not already loaded), and optionally creates
;         angular spectrograms with B-field and S/C ram directions specified 
;         using symbols
;
; Keywords:
;         probes: array of probes
;         instrument: fpi or hpca
;         species: depends on instrument:
;             FPI: 'e' for electrons, 'i' for ions
;             HPCA: 'hplus' for H+, 'oplus' for O+, 'heplus' for He+, 'heplusplus', for He++
;         outputs: list of requested output types, 
;             'energy' - energy spectrogram
;             'phi' - azimuthal spectrogram
;             'theta' - latitudinal spectrogram
;             'gyro' - gyrophase spectrogram
;             'pa' - pitch angle spectrogram
;             'moments' - distribution moments (density, velocity, etc.) - see warning at the top of mms_part_products before using this!
;         add_bfield_dir: add B-field direction (+, -) to the angular spectrograms (phi, theta)
;         add_ram_dir: add S/C ram direction (X) to the angular spectrograms (phi, theta)
;         dir_interval: number of seconds between B-field and S/C ram direction symbols on angular spectrogram plots
;         
;         subtract_error: subtract the distribution error prior to doing the calculations (FPI only, currently)
;         
; Notes:
;         Updated to automatically center HPCA measurements if not specified already, 18Oct2017
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-01-24 10:52:02 -0800 (Wed, 24 Jan 2018) $
;$LastChangedRevision: 24577 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_getspec.pro $
;-

pro mms_part_getspec, probes=probes, $
                      level=level, $
                      data_rate=data_rate, $
                      trange=trange, $
                      energy=energy,$ ;energy range
                      species=species, $ ; FPI: 'i' for ions, 'e' for electrons; HPCA: 'hplus' for H+, 'oplus' for O+, etc.
                      instrument=instrument, $ ; HPCA or FPI
                      
                      outputs=outputs,$ ;list of requested output types

                      units=units,$ ;scalar unit conversion for data
                        
                      phi=phi_in,$ ;angle limit 2-element array [min,max], in degrees, spacecraft spin plane
                      theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
                      pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
                      gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase
                      
                      regrid=regrid, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)
                      ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
                      
                      suffix=suffix, $ ;tplot suffix to apply when generating outputs

                      datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)

                      forceload=forceload, $ --force data load (otherwise will try to use previously loaded data)

                      mag_suffix=mag_suffix,$
                        
                      subtract_bulk=subtract_bulk, $
                      subtract_error=subtract_error, $
                      
                      center_measurement=center_measurement, $
                      tplotnames=tplotnames, $
                      
                      cdf_version=cdf_version, $
                      latest_version=latest_version, $
                      major_version=major_version, $
                      min_version=min_version, $
                      
                      add_bfield_dir=add_bfield_dir, $
                      add_ram_dir=add_ram_dir, $
                      dir_interval=dir_interval, $
                      
                      _extra=ex 

    compile_opt idl2

    start_time = systime(/seconds)
    
    if ~keyword_set(trange) then begin
        trange = timerange()
    endif else trange = timerange(trange)
    
    if ~keyword_set(units) then begin
      units_lc = 'eflux'
    endif else units_lc = strlowcase(units)

    if ~keyword_set(outputs) then begin
        outputs = ['phi','theta','energy','pa','gyro']
    endif else outputs = strlowcase(outputs)
    
    if ~keyword_set(instrument) then begin
        instrument = 'fpi'
    endif else instrument = strlowcase(instrument)
    
    if ~keyword_set(data_rate) then begin
        if instrument eq 'fpi' then data_rate = 'fast' else data_rate = 'srvy'
    endif else data_rate = strlowcase(data_rate)
    
    if ~keyword_set(species) then begin
        if instrument eq 'fpi' then species = 'e' else species = 'hplus'
    endif else species = strlowcase(species)
    
    if ~keyword_set(probes) then begin
        probes = ['1', '2', '3', '4']
    endif else probes = strcompress(string(probes), /rem)
    
    if ~keyword_set(mag_suffix) then mag_suffix = ''
    if ~keyword_set(dir_interval) then dir_interval = 60d 
    
    ; HPCA is required to be at the center of the accumulation interval
    if instrument eq 'hpca' and ~keyword_set(center_measurement) then center_measurement = 1
    
    support_trange = trange + [-60,60]
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        if ~spd_data_exists('mms'+strcompress(string(probes[probe_idx]), /rem)+'_fgm_b_dmpa_srvy_l2_bvec'+mag_suffix, trange[0], trange[1]) or keyword_set(forceload) then append_array, fgm_to_load, probes[probe_idx]
        if ~spd_data_exists('mms'+strcompress(string(probes[probe_idx]), /rem)+'_defeph_pos', trange[0], trange[1]) or keyword_set(forceload) then append_array, state_to_load, probes[probe_idx]
    endfor

    ; load state data (needed for coordinate transforms and field aligned coordinates)
    if defined(state_to_load) then mms_load_state, probes=state_to_load, trange=support_trange

    ; load magnetic field data
    if defined(fgm_to_load) then mms_load_fgm, probes=fgm_to_load, trange=support_trange, level='l2', suffix=mag_suffix, /time_clip

    if instrument eq 'fpi' then begin
        mms_load_fpi, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='d'+species+'s-dist', /time_clip, center_measurement=center_measurement, $
            cdf_version=cdf_version, latest_version=latest_version, major_version=major_version, $
            min_version=min_version
            
        ; load the bulk velocity if the user requested to subtract it
        if keyword_set(subtract_bulk) then mms_load_fpi, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='d'+species+'s-moms'
    endif else if instrument eq 'hpca' then begin
        mms_load_hpca, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='ion', center_measurement=center_measurement,  $
            cdf_version=cdf_version, latest_version=latest_version, major_version=major_version, $
            min_version=min_version
        
        ; load the bulk velocity if the user requested to subtract it
        if keyword_set(subtract_bulk) then mms_load_hpca, probes=probes, trange=trange, $
            data_rate=data_rate, level=level, datatype='moments'
    endif

    for probe_idx = 0, n_elements(probes)-1 do begin
        bname = 'mms'+probes[probe_idx]+'_fgm_b_dmpa_srvy_l2_bvec'+mag_suffix
        pos_name = 'mms'+probes[probe_idx]+ '_defeph_pos'
        if instrument eq 'fpi' then begin
            name = 'mms'+probes[probe_idx]+'_d'+species+'s_dist_'+data_rate
            vel_name = 'mms'+probes[probe_idx]+'_d'+species+'s_bulkv_dbcs_'+data_rate
            if keyword_set(subtract_error) then error_variable = 'mms'+probes[probe_idx]+'_d'+species+'s_disterr_'+data_rate
        endif else if instrument eq 'hpca' then begin
            name =  'mms'+probes[probe_idx]+'_hpca_'+species+'_phase_space_density'
            vel_name = 'mms'+probes[probe_idx]+'_hpca_'+species+'_ion_bulk_velocity'
        endif

        mms_part_products_new, name, trange=trange, units=units_lc, $
            mag_name=bname, pos_name=pos_name, vel_name=vel_name, energy=energy, $
            pitch=pitch, gyro=gyro_in, phi=phi_in, theta=theta, regrid=regrid, $
            outputs=outputs, suffix=suffix, datagap=datagap, subtract_bulk=subtract_bulk, $
            tplotnames=tplotnames_thisprobe, subtract_error=subtract_error, $
            error_variable=error_variable, _extra=ex
            
        if undefined(tplotnames_thisprobe) then continue ; nothing created by mms_part_products
        append_array, tplotnames, tplotnames_thisprobe
        
        if keyword_set(add_ram_dir) then begin
            ; average the velocity data before adding to the plot
            avg_data, 'mms'+probes[probe_idx]+'_mec_v_gse', dir_interval
            get_data, 'mms'+probes[probe_idx]+'_mec_v_gse_avg', data=velocity_gse
            cart_to_sphere, velocity_gse.Y[*, 0], velocity_gse.Y[*, 1], velocity_gse.Y[*, 2], vel_r, vel_theta, vel_phi, /PH_0_360
            store_data, name+'_phi_vdata', data={x: velocity_gse.X, y: vel_phi}
            store_data, name+'_theta_vdata', data={x: velocity_gse.X, y: vel_theta}
            options, name+'_phi_vdata', psym=7, linestyle=6 ; X
            options, name+'_theta_vdata', psym=7, linestyle=6 ; X
            store_data, name+'_phi_with_v', data=name+'_phi '+name+'_phi_vdata'
            store_data, name+'_theta_with_v', data=name+'_theta '+name+'_theta_vdata'
            ylim, name+'_phi_with_v', 0., 360., 0
            ylim, name+'_theta_with_v', -90., 90., 0
        endif
        if keyword_set(add_bfield_dir) then begin
            ; average the B-field before adding to the plot
            avg_data, 'mms'+probes[probe_idx]+'_fgm_b_dmpa_srvy_l2_bvec', dir_interval
            get_data, 'mms'+probes[probe_idx]+'_fgm_b_dmpa_srvy_l2_bvec_avg', data=b_field_data
            neg_b_field = -b_field_data.Y
            
            cart_to_sphere, b_field_data.Y[*, 0], b_field_data.Y[*, 1], b_field_data.Y[*, 2], r, theta, phi, /PH_0_360
            cart_to_sphere, neg_b_field[*, 0], neg_b_field[*, 1], neg_b_field[*, 2], negr, negtheta, negphi, /PH_0_360
            
            store_data, name+'_phi_bdata', data={x: b_field_data.X, y: phi}
            store_data, name+'_minusphi_bdata', data={x: b_field_data.X, y: negphi}
            store_data, name+'_theta_bdata', data={x: b_field_data.X, y: theta}
            store_data, name+'_minustheta_bdata', data={x: b_field_data.X, y: negtheta}
            
            usersym, [-1, 1], [0, 0] ; minus sign
            
            options, name+'_phi_bdata',psym=1, linestyle=6 ; +
            options, name+'_minusphi_bdata',psym=8, linestyle=6 ; -
            options, name+'_theta_bdata',psym=1, linestyle=6 ; +
            options, name+'_minustheta_bdata',psym=8, linestyle=6 ; -
            
            store_data, name+'_phi_with_b', data=name+'_phi '+name+'_phi_bdata '+name+'_minusphi_bdata'
            store_data, name+'_theta_with_b', data=name+'_theta '+name+'_theta_bdata '+name+'_minustheta_bdata'
            ylim, name+'_phi_with_b', 0., 360., 0
            ylim, name+'_theta_with_b', -90., 90., 0
        endif
        if keyword_set(add_bfield_dir) and keyword_set(add_ram_dir) then begin
            store_data, name+'_phi_with_bv', data=name+'_phi '+name+'_phi_bdata '+name+'_minusphi_bdata '+name+'_phi_vdata'
            store_data, name+'_theta_with_bv', data=name+'_theta '+name+'_theta_bdata '+name+'_minustheta_bdata '+name+'_theta_vdata'
            ylim, name+'_phi_with_bv', 0., 360., 0
            ylim, name+'_theta_with_bv', -90., 90., 0
        endif 
    endfor
    
end
