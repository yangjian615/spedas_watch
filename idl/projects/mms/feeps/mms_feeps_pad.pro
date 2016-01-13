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
;     **** this routine needs to be updated for v4.3 CDFs **** 
;     **** you shouldn't trust the results of this procedure until this comment has been removed ****
;   
;     Based on the EIS pitch angle code by Brian Walsh
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-12 15:13:27 -0800 (Tue, 12 Jan 2016) $
;$LastChangedRevision: 19721 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_pad.pro $
;-

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
    ;tdeflag, prefix+'_epd_feeps_pitch_angle', 'linear', /overwrite
    get_data, prefix+'_epd_feeps_pitch_angle'+suffix, data=pa_data, dlimits=pa_dlimits
    
    ; From Allison Jaynes @ LASP: The 6,7,8 sensors (out of 12) are ions, 
    ; so in the pitch angle array, the 5,6,7 columns (counting from zero) will be the ion pitch angles.
    particle_idxs = datatype eq 'electron' ? [2, 3, 4, 10, 11] : [5, 6, 7]
    ;electron_idxs = [0, 1, 2, 3, 4, 8, 9, 10, 11] ; all 9, but some are missing at the moment

    particle_pa = pa_data.Y[*, particle_idxs]
    
    flux_file = fltarr(n_elements(pa_data.x),9)
    pa_flux = fltarr(n_elements(pa_data.x),n_pabins)
    pa_num_in_bin = fltarr(n_elements(pa_data.X), n_pabins)
    for t=0, n_elements(particle_idxs)-1 do begin
        tdeflag, prefix+'_epd_feeps_top_intensity_sensorID_'+strcompress(string(particle_idxs[t]+1), /rem)+suffix, 'linear', /overwrite
        get_data, prefix+'_epd_feeps_top_intensity_sensorID_'+strcompress(string(particle_idxs[t]+1), /rem)+suffix, data = d
        
        indx = where((d.v lt energy[1]) and (d.v gt energy[0]), energy_count)
        if energy_count eq 0 then begin
            dprint, dlevel = 0, 'Energy range selected is not covered by the detector for FEEPS ' + datatype + ' data'
            continue
        endif
        for i=0l, n_elements(d.x)-1 do begin ; loop through time
            flux_file[i,t] = total(reform(d.y[i,indx]), /nan)  ; start with lowest energy
            for j=0, n_pabins-1 do begin ; loop through pa bins
                if (particle_pa[i,t] gt pa_bins[j]) and (particle_pa[i,t] lt pa_bins[j+1]) then begin
                    pa_flux[i,j] = pa_flux[i,j] + flux_file[i,t]

                    ; we track the number of data points we put in each bin
                    ; so that we can average later
                    pa_num_in_bin[i,j] += 1.0
                endif
            endfor
        endfor
    endfor
    ;feeps_bin_info, pa_bins, pa_flux, pa_num_in_bin, particle_pa, flux_file, 0
    ;stop
    ; calculate the average for each bin
    new_pa_flux = fltarr(n_elements(d.x),n_pabins)

    ; loop over time
    for i=0, n_elements(pa_flux[*,0])-1 do begin
        ; loop over bins
        for bin_idx = 0, n_elements(pa_flux[i,*])-1 do begin
            if pa_num_in_bin[i,bin_idx] ne 0.0  then new_pa_flux[i,bin_idx] = pa_flux[i,bin_idx]/pa_num_in_bin[i,bin_idx]
        endfor
    endfor
    
   ; feeps_bin_info, pa_bins, new_pa_flux, pa_num_in_bin, particle_pa, flux_file, 0

    en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV'
    new_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'

    store_data, new_name, data={x:d.x, y:new_pa_flux, v:pa_label}
    options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
        zlog = 1, ytitle = 'MMS'+probe+' FEEPS ' + datatype, ysubtitle=en_range_string+'!CPA [Deg]', ztitle=data_units

    ; calculate the spin average
    ;mms_feeps_pad_spinavg, probe=probe, datatype=datatype, energy=energy, bin_size=bin_size, data_units=data_units

end