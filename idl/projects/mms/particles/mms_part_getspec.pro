;+
; Procedure:
;         mms_part_getspec
;
;
; Purpose:
;         This is a wrapper around mms_part_products that loads required 
;         support data (if not already loaded)
;
; Keywords:
;         probes: array of probes
;         instrument: fpi or hpca
;         
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-04-20 13:04:32 -0700 (Thu, 20 Apr 2017) $
;$LastChangedRevision: 23202 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_getspec.pro $
;-

pro mms_part_getspec, probes=probes, $
                      level=level, $
                      data_rate=data_rate, $
                      trange=trange, $
                      energy=energy,$ ;energy range
                      species=species, $ ; 'i' for ions, 'e' for electrons
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
                      
                      _extra=ex ;TBD: consider implementing as _strict_extra

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
        probes = [1, 2, 3, 4]
    endif
    
    if ~keyword_set(mag_suffix) then mag_suffix = ''
    
    support_trange = trange + [-60,60]
    
    for probe_idx = 0, n_elements(probes)-1 do begin
      if (tnames('mms'+strcompress(string(probes[probe_idx]), /rem)+'_fgm_b_dmpa_srvy_l2_bvec'+mag_suffix) eq '') then append_array, fgm_to_load, probes[probe_idx]
      if (tnames('mms'+strcompress(string(probes[probe_idx]), /rem)+'_defeph_pos') eq '') then append_array, state_to_load, probes[probe_idx]
    endfor

    ; load state data (needed for coordinate transforms and field aligned coordinates)
    if defined(state_to_load) then mms_load_state, probes=state_to_load, trange=support_trange

    ; load magnetic field data
    if defined(fgm_to_load) then mms_load_fgm, probes=fgm_to_load, trange=support_trange, level='l2', suffix=mag_suffix

    if instrument eq 'fpi' then begin
        mms_load_fpi, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='d'+species+'s-dist'
        ; load the bulk velocity if the user requested to subtract it
        if keyword_set(subtract_bulk) then mms_load_fpi, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='d'+species+'s-moms'
    endif else if instrument eq 'hpca' then begin
        mms_load_hpca, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='ion'
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
        endif else if instrument eq 'hpca' then begin
          name =  'mms'+probes[probe_idx]+'_hpca_'+species+'_phase_space_density'
          vel_name = 'mms'+probes[probe_idx]+'_hpca_'+species+'_ion_bulk_velocity'
        endif
        mms_part_products, name, trange=trange, units=units_lc, $
            mag_name=bname, pos_name=pos_name, vel_name=vel_name, energy=energy, $
            pitch=pitch, gyro=gyro_in, phi=phi_in, theta=theta, regrid=regrid, $
            outputs=outputs, suffix=suffix, datagap=datagap, subtract_bulk=subtract_bulk, $
            _extra=ex
    endfor
end
