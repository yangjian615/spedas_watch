;+
; PROCEDURE:
;         mms_load_eis
;         
; PURPOSE:
;         Load data from the MMS Energetic Ion Spectrometer (EIS)
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         local_data_dir: local directory to store the CDF files
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
; HISTORY:
;     9/15/2015 - Ian Cohen at APL: added modifications to omni-directional calculations to be able to handle 
;                 ExTOF and PHxTOF data
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-09-15 12:36:24 -0700 (Tue, 15 Sep 2015) $
;$LastChangedRevision: 18801 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_eis.pro $
;-

; 
; PURPOSE:
;       Calculates the omni-directional CPS for all 6 telescopes
; 
; NOTES:
;       based on Brian Walsh's EIS code from 7/29/2015
;
pro mms_eis_cps_omni, probe, species = species, datatype = datatype, tplotnames = tplotnames, ion_type = ion_type
    ; default to electrons
    if undefined(species) then species = 'electron'
    if undefined(datatype) then datatype = 'electronenergy'
    probe = strcompress(string(probe), /rem)
    if species eq 'ion' then species_str = datatype+'_'+ion_type else species_str = datatype+'_'+species

    get_data, 'mms'+probe+'_epd_eis_'+species_str+'_cps_t0', data = d, dlimits=dl
    if is_struct(d) then begin
        counts_omni = dblarr(n_elements(d.x),n_elements(d.v))
        for i=0, 5 do begin ; loop through each detector
            get_data, 'mms'+probe+'_epd_eis_'+species_str+'_cps_t'+STRTRIM(i, 1), data = d
            for t=0l, n_elements(d.x)-1 do begin ; loop through each time step
                for v=0l, n_elements(d.v)-1 do begin ; loop on each energy channel
                    counts_omni[t,v] = counts_omni[t,v] + d.y[t,v]
                endfor
            endfor
        endfor
        store_data, 'mms'+probe+'_epd_eis_'+species_str+'_cps_omni', data={x:d.x, y:counts_omni/6., v:d.v}, dlimits=dl
        options, 'mms'+probe+'_epd_eis_'+species_str+'_cps_omni', ylog = 1, spec = 1, yrange = [30,3e3],$
          zlog = 1, ytitle = 'MMS'+probe+' EIS '+species+' OMNI', ysubtitle='Energy [keV]', ztitle='Counts/s', /default
        tplotnames = array_concat('mms'+probe+'_epd_eis_'+species_str+'_cps_omni', tplotnames)
    endif
end

; PURPOSE:
;       Calculates the omni-directional flux for all 6 telescopes
;
pro mms_eis_flux_omni, probe, species = species, datatype = datatype, tplotnames = tplotnames
    ; default to electrons
    if undefined(species) then species = 'electron'
    if undefined(datatype) then species = 'electronenergy'
    probe = strcompress(string(probe), /rem)
    species_str = datatype+'_'+species

    get_data, 'mms'+probe+'_epd_eis_'+species_str+'_flux_t0', data = d, dlimits=dl
    if is_struct(d) then begin
        flux_omni = dblarr(n_elements(d.x),n_elements(d.v))
        for i=0, 5 do begin ; loop through each detector
            get_data, 'mms'+probe+'_epd_eis_'+species_str+'_flux_t'+STRTRIM(i, 1), data = d
            for t=0l, n_elements(d.x)-1 do begin ; loop through each time step
                for v=0l, n_elements(d.v)-1 do begin ; loop on each energy channel
                    flux_omni[t,v] = flux_omni[t,v] + d.y[t,v]
                endfor
            endfor
        endfor
        store_data, 'mms'+probe+'_epd_eis_'+species_str+'_flux_omni', data={x:d.x, y:flux_omni/6., v:d.v}, dlimits=dl
        options, 'mms'+probe+'_epd_eis_'+species_str+'_flux_omni', ylog = 1, spec = 1, yrange = [30,3e3],$
            zlog = 1, ytitle = 'MMS'+probe+' EIS '+species+' OMNI', ysubtitle='Energy [keV]', ztitle='#/(s-sr-cm^2-keV)', /default
        tplotnames = array_concat('mms'+probe+'_epd_eis_'+species_str+'_flux_omni', tplotnames)
    endif
end

pro mms_load_eis, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'extof'
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'epd-eis', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update
    
    ; calculate the omni-directional quantities
    for probe_idx = 0, n_elements(probes)-1 do begin
        ;try both ions and electrons in case multiple datatypes were loaded
        if (datatype eq 'electronenergy') then begin
          mms_eis_cps_omni, probes[probe_idx], species='electron', datatype='electronenergy', tplotnames = tplotnames
          mms_eis_flux_omni, probes[probe_idx], species='electron', datatype='electronenergy', tplotnames = tplotnames
        endif
        if (datatype eq 'extof') then begin
          mms_eis_cps_omni, probes[probe_idx], species='proton', datatype='extof',tplotnames = tplotnames
          mms_eis_cps_omni, probes[probe_idx], species='alpha', datatype='extof',tplotnames = tplotnames
          mms_eis_cps_omni, probes[probe_idx], species='oxygen', datatype='extof',tplotnames = tplotnames
          mms_eis_flux_omni, probes[probe_idx], species='proton', datatype='extof',tplotnames = tplotnames
          mms_eis_flux_omni, probes[probe_idx], species='alpha', datatype='extof',tplotnames = tplotnames
          mms_eis_flux_omni, probes[probe_idx], species='oxygen', datatype='extof',tplotnames = tplotnames
        endif
        if (datatype eq 'phxtof') then begin
          mms_eis_cps_omni, probes[probe_idx], species='proton', datatype='phxtof',tplotnames = tplotnames      
          mms_eis_flux_omni, probes[probe_idx], species='proton', datatype='phxtof',tplotnames = tplotnames
        endif  
    endfor
end