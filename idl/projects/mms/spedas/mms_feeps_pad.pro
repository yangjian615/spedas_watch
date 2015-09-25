;+
; PROCEDURE:
;         mms_feeps_pad
;
; PURPOSE:
;         Calculate pitch angle distributions using data from the
;           MMS Fly's Eye Energetic Particle Sensor (FEEPS)
;
; KEYWORDS:
;         trange: time range of interest
;         probe: value for MMS SC #
;         datatype: 'electron' or 'ion'
;         energy: energy range to include in the calculation
;         bin_size: size of the pitch angle bins
;
; EXAMPLES:
;
;
; OUTPUT:
;
;
; NOTES:
;     Based on the EIS pitch angle code by Brian Walsh
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-09-24 14:17:09 -0700 (Thu, 24 Sep 2015) $
;$LastChangedRevision: 18919 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_feeps_pad.pro $
;-
pro mms_feeps_pad_spinavg, probe=probe, species = species, data_units = data_units, $
    datatype = datatype, energy = energy, bin_size = bin_size
    if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
    if undefined(datatype) then datatype = 'electron'
    if undefined(data_units) then data_units = 'cps'
    if undefined(suffix) then suffix = ''
    if undefined(energy) then energy = [0, 1000]
    if undefined(bin_size) then bin_size = 15

    en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV'
    units_label = data_units eq 'Counts' ? 'Counts': '[(cm!E2!N s sr KeV)!E-1!N]'

    prefix = 'mms'+probe+'_epd_feeps_'
    ; get the spin #s asscoiated with each measurement
    get_data, prefix + 'spin', data=spin_nums

    ; find where the spins start
    spin_starts = uniq(spin_nums.Y)
    pad_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'

    get_data, pad_name, data=pad_data, dlimits=pad_dl

    if ~is_struct(pad_data) then begin
        stop
        dprint, dlevel = 0, 'Error, variable containing valid PAD data missing.'
        return
    endif

    spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(pad_data.Y[0, *]))
    spin_times = dblarr(n_elements(spin_starts))

    current_start = 0
    ; loop through the spins for this telescope
    for spin_idx = 0, n_elements(spin_starts)-1 do begin
        ; loop over energies
        ;spin_sum_flux[spin_idx, *] = total(pad_data.Y[current_start:spin_starts[spin_idx], *], 1)
        spin_sum_flux[spin_idx, *] = average(pad_data.Y[current_start:spin_starts[spin_idx], *], 1)
        spin_times[spin_idx] = pad_data.X[current_start]
        current_start = spin_starts[spin_idx]+1
    endfor

    suffix = suffix + '_spin'
    newname = prefix+en_range_string+'_pad'+suffix

    ; rebin the data before storing it
    ; the idea here is, for bin_size = 15 deg, rebin the data from center points to:
    ;    new_bins = [0, 15, 30, 45, 60, 75, 90, 105, 120, 135 , 150, 165, 180]

    n_pabins = 180./bin_size
    new_bins = 180.*indgen(n_pabins+1)/n_pabins

    rebinned_data = congrid(spin_sum_flux, n_elements(spin_starts), n_elements(new_bins), /center, /interp)

    store_data, newname, data={x: spin_times, y: rebinned_data, v: new_bins}, dlimits=flux_dl
    options, newname, spec=1, ystyle=1, ztitle=units_label, ytitle='MMS'+probe+' FEEPS '+datatype, ysubtitle=en_range_string+'!CPAD (deg)'
    ylim, newname, 1., 180.
    zlim, newname, 0, 0, 1
    ;options, newname, no_interp=0
    tdegap, newname, /overwrite
end



pro mms_feeps_pad, bin_size = bin_size, probe = probe, energy = energy, suffix = suffix, datatype = datatype
    if undefined(datatype) then datatype='electron'
    if undefined(probe) then probe = '1'
    if undefined(suffix) then suffix = ''
    prefix = 'mms'+strcompress(string(probe), /rem)
    if undefined(bin_size) then bin_size = 15 ;deg
    if undefined(energy) then energy = [0,1000]
    data_units = '(cm!E2!N s sr KeV)!E-1!N'
    
    
    ; set up the number of pa bins to create
    bin_size = float(bin_size)
    n_pabins = 180./bin_size
    pa_bins = 180.*indgen(n_pabins+1)/n_pabins
    pa_label = 180.*indgen(n_pabins)/n_pabins+bin_size/2.
    
    ; get the pitch angles
    get_data, prefix+'_epd_feeps_pitch_angle', data=pa_data, dlimits=pa_dlimits
    
    ; From Allison Jaynes @ LASP: The 6,7,8 sensors (out of 12) are ions, 
    ; so in the pitch angle array, the 5,6,7 columns (counting from zero) will be the ion pitch angles.
    pa_ions = pa_data.Y[*,[5, 6, 7]]
    pa_unknown = pa_data.Y[*, [8, 9, 10, 11]]
    ;electron_idxs = [0, 1, 2, 3, 4, 8, 9, 10, 11] ; all 9, but some are missing at the moment
    electron_idxs = [2, 3, 4, 10, 11] 
    pa_electrons = pa_data.Y[*, electron_idxs]
    
; ----------------- for electrons:
    if datatype eq 'electron' then begin
        flux_file = fltarr(n_elements(pa_data.x),9)
        pa_flux = fltarr(n_elements(pa_data.x),n_pabins)
        for t=0, n_elements(electron_idxs)-1 do begin
    
            get_data, prefix+'_epd_feeps_top_intensity_sensorID_'+strcompress(string(electron_idxs[t]+1), /rem)+suffix, data = d
            e = d.v
    
            indx = where((e lt energy[1]) and (e gt energy[0]), energy_count)
            if energy_count eq 0 then begin
                dprint, dlevel = 0, 'Energy range selected is not covered by the detector for FEEPS ' + datatype + ' data'
                continue
            endif
            for i=0l, n_elements(d.x)-1 do begin ; loop through time
                flux_file[i,t] = total(reform(d.y[i,indx]), /nan)  ; start with lowest energy
                for j=0, n_pabins-1 do begin ; loop through pa bins
    
                    if (pa_electrons[i,t] gt pa_bins[j]) and (pa_electrons[i,t] lt pa_bins[j+1]) then begin
                        pa_flux[i,j] = flux_file[i,t]
    
                    endif
                endfor
            endfor
        endfor
        en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV
        new_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'
    
        store_data, new_name, data={x:d.x, y:pa_flux, v:pa_label}
        options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
            zlog = 1, ytitle = 'MMS'+probe+' FEEPS ' + datatype, ysubtitle=en_range_string+'!CPA [Deg]', ztitle=data_units
    
    endif
    
; ----------------- for ions:
    if datatype eq 'ion' then begin
        flux_file = fltarr(n_elements(pa_data.x),3)
        pa_flux = fltarr(n_elements(pa_data.x),n_pabins)
        ion_idx = [5, 6, 7]
    
        for t=0, 2 do begin
            get_data, prefix+'_epd_feeps_top_intensity_sensorID_'+strcompress(string(ion_idx[t]+1), /rem)+suffix, data = d
            ; get flux from each detector
            ;get_data, 'mms'+probe+'_epd_eis_' + datatype + '_' + ion_type[ion_type_idx] + '_' + data_units + '_t'+STRTRIM(t, 1)+suffix, data = d
    
            ; get energy range of interest
            e = d.v
            indx = where((e lt energy[1]) and (e gt energy[0]), energy_count)
    
            if energy_count eq 0 then begin
                print, 'Energy range selected is not covered by the detector for FEEPS ' + datatype + ' data'
                continue
            endif
    
            ; Loop through each time step and get:
            ; 1.  the total flux for the energy range of interest for each detector
            ; 2.  flux in each pa bin
            for i=0l, n_elements(d.x)-1 do begin ; loop through time
                flux_file[i,t] = total(reform(d.y[i,indx]), /nan)  ; start with lowest energy
                for j=0, n_pabins-1 do begin ; loop through pa bins
    
                    if (pa_ions[i,t] gt pa_bins[j]) and (pa_ions[i,t] lt pa_bins[j+1]) then begin
                        pa_flux[i,j] = flux_file[i,t]
    
                    endif
                endfor
            endfor
        endfor
        en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV
        new_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'
    
        store_data, new_name, data={x:d.x, y:pa_flux, v:pa_label}
        options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
            zlog = 1, ytitle = 'MMS'+probe+' FEEPS ' + datatype, ysubtitle=en_range_string+'!CPA [Deg]', ztitle=''
    endif
    
    mms_feeps_pad_spinavg, probe=probe, datatype=datatype, energy=energy, bin_size=bin_size, data_units=data_units
end