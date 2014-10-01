;+
; Procedure: poes_load_data
; 
; Keywords: 
;             trange:       time range of interest
;             datatype:     type of POES data to be loaded. Valid data types are:
;                    ---- Total Energy Detector (TED) ----
;                      ted_ele_eflux: TED electron integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_pro_eflux: TED proton integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_ele_eflux_atmo: TED electron atmospheric integral energy flux, low and high energies (50-1000 eV, 1-20 keV), at 120 km
;                      ted_pro_eflux_atmo: TED proton atmospheric integral energy flux, low and high energies (50-1000 eV, 1-20 keV), at 120 km
;                      ted_total_eflux_atmo: TED electron and proton total atmospheric integral energy flux at 120 km
;                      ted_ele_energy: TED electron characteristic energy channel, both telescopes
;                      ted_pro_energy: TED proton characteristic energy channel, both telescopes
;                      ted_ele_max_flux: TED electron maximum differential flux, both telescopes
;                      ted_pro_max_flux: TED proton maximum differential flux, both telescopes
;                      ted_ele_eflux_bg: TED electron background integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_pro_eflux_bg: TED proton background integral energy flux, both telescopes, low (50-1000 eV) and high energy (1-20 keV)
;                      ted_pitch_angles: TED pitch angles (at satellite and foot of field line)
;                      ted_ifc_flag: TED IFC flag (0=off, 1=on)
;                           
;                    ---- Medium Energy Proton and Electron Detector ----
;                      mep_ele_flux: MEPED electron integral flux, in energy for each telescope
;                      mep_pro_flux: MEPED proton differential flux, in energy for each telescope
;                      mep_pro_flux_p6: MEPED proton integral flux,  >6174 keV, for each telescope
;                      mep_omni_flux: MEPED omni-directional proton differential flux
;                      mep_pitch_angles: MEPED pitch angles (satellite and foot print)
;                      mep_ifc_flag: IFC flag for MEPED, (0=off, 1=on)
;            
;             suffix:        String to append to the end of the loaded tplot variables
;             probes:        Name of the POES spacecraft, i.e., probes=['noaa18','noaa19','metop2']
;             varnames:      Name(s) of variables to load, defaults to all (*)
;             /downloadonly: Download the file but don't read it  
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-09-26 15:05:05 -0700 (Fri, 26 Sep 2014) $
; $LastChangedRevision: 15873 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_load_data.pro $
;-

; split tplot variable containing data for two telescopes into 
; two tplot variables - one for each telescope
pro poes_split_telescope_data, name, telescope_angles, tplotnames = tplotnames
    get_data, name, data=the_data, dlimits=the_dlimits
    if is_struct(the_data) && is_struct(the_dlimits) then begin
        store_data, name+'_tel'+telescope_angles[0], data={x: the_data.X, y: reform(the_data.Y[*,0,*])}, dlimits=the_dlimits
        store_data, name+'_tel'+telescope_angles[1], data={x: the_data.X, y: reform(the_data.Y[*,1,*])}, dlimits=the_dlimits
    
        del_data, name
        ; add the new tplot variables to tplotnames, so we can time clip them.
        append_array, tplotnames, name+'_tel'+telescope_angles[0]
        append_array, tplotnames, name+'_tel'+telescope_angles[1]
    endif else begin
        dprint, dlevel=0, 'Error splitting the telescope data for ', name, '. Invalid data or dlimits structure.'
    endelse
end

pro poes_load_data, trange = trange, datatype = datatype, probes = probes, suffix = suffix, $
                    downloadonly = downloadonly, verbose = verbose, noephem = noephem
    compile_opt idl2

    poes_init
    if undefined(suffix) then suffix = ''
    if undefined(prefix) then prefix = ''
    
    ; handle possible server errors
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return
    endif

    if not keyword_set(datatype) then datatype = '*'
    if not keyword_set(probes) then probes = ['noaa19'] 
    if not keyword_set(source) then source = !poes
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    tn_list_before = tnames('*')
    
    pathformat = strarr(n_elements(probes))
    ; let's have the prefix include the probe name, so we can load
    ; data from multiple spacecraft without naming conflicts
    prefix_array = strarr(n_elements(probes))
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        dprint, dlevel = 2, verbose=source.verbose, 'Loading ', strupcase(probes[probe_idx]), ' data'

        pathformat[probe_idx] = '/noaa/'+probes[probe_idx]+'/sem2_fluxes-2sec/YYYY/'+probes[probe_idx]+'_poes-sem2_fluxes-2sec_YYYYMMDD_v01.cdf'
        prefix_array[probe_idx] = prefix + probes[probe_idx]
    endfor
    
    for j = 0, n_elements(datatype)-1 do begin
        if datatype[j] eq '*' then varformat = '*' else begin
            case datatype[j] of 
                ; TED electron integral energy flux
                'ted_ele_eflux': append_array, varformat, 'ted_ele_*_eflux'
                ; TED proton integral energy flux
                'ted_pro_eflux': append_array, varformat, 'ted_pro_*_eflux'
                ; TED electron atmospheric integral energy flux at 120 km
                'ted_ele_eflux_atmo': append_array, varformat, 'ted_ele_eflux_atmo_*'
                ; TED proton atmospheric integral energy flux at 120 km
                'ted_pro_eflux_atmo': append_array, varformat, 'ted_pro_eflux_atmo_*'
                ; TED electron and proton total atmospheric integral energy flux at 120 km
                'ted_total_eflux_atmo': append_array, varformat, 'ted_total_eflux_atmo'
                ; TED electron characteristic energy channel
                'ted_ele_energy': append_array, varformat, 'ted_ele_energy*'
                ; TED proton characteristic energy channel
                'ted_pro_energy': append_array, varformat, 'ted_pro_energy*'
                ; TED electron maximum differential flux
                'ted_ele_max_flux': append_array, varformat, 'ted_ele_max_flux_*'
                ; TED proton maximum differential flux
                'ted_pro_max_flux': append_array, varformat, 'ted_pro_max_flux_*'
                ; TED electron background integral energy flux
                'ted_ele_eflux_bg': append_array, varformat, 'ted_ele_eflux_bg*'
                ; TED proton background integral energy flux
                'ted_pro_eflux_bg': append_array, varformat, 'ted_pro_eflux_bg*'
                ; TED pitch angles (at satellite and foot of field line)
                'ted_pitch_angles': append_array, varformat, 'ted_alpha_*'
                ; TED IFC flag
                'ted_ifc_flag': append_array, varformat, 'ted_ifc_on'
                ; MEPED electron integral flux, in energy for each telescope
                'mep_ele_flux': append_array, varformat, 'mep_ele_flux*'
                ; MEPED proton differential flux, in energy for each telescope
                'mep_pro_flux': append_array, varformat, 'mep_pro_flux*'
                ; MEPED proton integral flux,  >6174 keV, for each telescope
                'mep_pro_flux_p6': append_array, varformat, 'mep_pro_flux_p6*'
                ; MEPED omni-directional proton differential flux
                'mep_omni_flux': append_array, varformat, 'mep_omni_flux*'
                ; MEPED pitch angles (satellite and foot print)
                'mep_pitch_angles': append_array, varformat, 'meped_alpha_*'
                ; IFC flag for MEPED, (0=off, 1=on)
                'mep_ifc_flag': append_array, varformat, 'mep_ifc_on'
                else: dprint, dlevel = 0, 'Unknown data type!'

            endcase
        endelse
    endfor
    
    for j = 0, n_elements(pathformat)-1 do begin
        relpathnames = file_dailynames(file_format=pathformat[j], trange=tr, /unique)

        files = file_retrieve(relpathnames, _extra=source, /last_version)
        
        if keyword_set(downloadonly) then continue
        poes_cdf2tplot, files, prefix = prefix_array[j]+'_', suffix = suffix, verbose = verbose, $
            /load_labels, tplotnames=tplotnames, varformat = varformat
    endfor

    ; make sure some tplot variables were loaded
    tn_list_after = tnames('*')
    new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])
    
    ; check for data types with data for multiple telescopes in a single tplot variable. 
    for prefix_idx = 0, n_elements(prefix_array)-1 do begin
        mep_ele_flux = where(new_tnames eq prefix_array[prefix_idx]+'_mep_ele_flux', ele_count)
        if ele_count ne 0 then begin
            poes_split_telescope_data, prefix_array[prefix_idx]+'_mep_ele_flux', ['0', '90'], tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[prefix_idx]+'_mep_ele_flux_err', ['0', '90'], tplotnames = tplotnames
        endif

        mep_pro_flux = where(new_tnames eq prefix_array[prefix_idx]+'_mep_pro_flux', pro_count)
        if pro_count ne 0 then begin
            poes_split_telescope_data, prefix_array[prefix_idx]+'_mep_pro_flux', ['0', '90'], tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[prefix_idx]+'_mep_pro_flux_err', ['0', '90'], tplotnames = tplotnames
        endif
        
        ted_ele_flux = where(new_tnames eq prefix_array[prefix_idx]+'_ted_ele_flux', ele_count)
        if ele_count ne 0 then begin
            poes_split_telescope_data, prefix_array[prefix_idx]+'_ted_ele_flux', ['0', '30'], tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[prefix_idx]+'_ted_ele_flux_err', ['0', '30'], tplotnames = tplotnames
        endif

        ted_pro_flux = where(new_tnames eq prefix_array[prefix_idx]+'_ted_pro_flux', pro_count)
        if pro_count ne 0 then begin
            poes_split_telescope_data, prefix_array[prefix_idx]+'_ted_pro_flux', ['0', '30'], tplotnames = tplotnames
            poes_split_telescope_data, prefix_array[prefix_idx]+'_ted_pro_flux_err', ['0', '30'], tplotnames = tplotnames
        endif
    endfor

    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
        
end
