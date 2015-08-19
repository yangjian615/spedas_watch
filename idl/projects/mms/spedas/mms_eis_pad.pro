;+
; PROCEDURE:
;         mms_eis_pad
;
; PURPOSE:
;         Calculate pitch angle distributions using data from the 
;           MMS Energetic Ion Spectrometer (EIS)
;
; KEYWORDS:
;         trange: time range of interest
;         probe: value for MMS SC #
;         species: 'ion', 'electron', or 'all'
;         energy: energy range to include in the calculation
;         bin_size: size of the pitch angle bins
;         data_units: flux or cps
;         data_name: extof, phxtof
;         ion_type: array containing types of particles to include. 
;               for PHxTOF data, valid options are 'proton', 'oxygen'
;               for ExTOF data, valid options are 'proton', 'oxygen', and/or 'alpha'
;
; EXAMPLES:
; 
; 
; OUTPUT:
;
;
; NOTES:
;     This was written by Brian Walsh; minor modifications by egrimes@igpp
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-18 09:53:47 -0700 (Tue, 18 Aug 2015) $
;$LastChangedRevision: 18512 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_eis_pad.pro $
;-

pro mms_eis_pad,probe = probe, trange = trange, species = species, $
                energy = energy, bin_size = bin_size, data_units = data_units, $
                data_name = data_name, ion_type = ion_type

; energy range in keV
  
 ; get_timespan, tspan
  if not KEYWORD_SET(trange) then trange = ['2015-06-28', '2015-06-29']
  if not KEYWORD_SET(probe) then probe = '1'
  if not KEYWORD_SET(species) then species = 'all'
  if not KEYWORD_SET(ion_type) then ion_type = ['oxygen', 'proton']
  if not KEYWORD_SET(energy) then energy = [35,45] ; set default energy as lowest energy channel in keV
  if not KEYWORD_SET(bin_size) then bin_size = 10 ; set default energy as lowest energy channel in keV
  if not KEYWORD_SET(data_units) then data_units = 'flux'
  
  ; would be good to get this from the metadata eventually
  units_label = data_units eq 'cps' ? 'Counts/s': '#/(cm^2-sr-s-keV)'
  if not KEYWORD_SET(data_name) then data_name = 'extof'

  if energy[0] gt energy[1] then begin
    print, 'Low energy must be given first, then high energy in "energy" keyword'
    stop
  endif

  ; set up the number of pa bins to create
  bin_size = float(bin_size)
  n_pabins = 180./bin_size
  pa_bins = 180.*indgen(n_pabins+1)/n_pabins
  pa_label = 180.*indgen(n_pabins)/n_pabins+bin_size/2.
  
  
  ;pa_label = indgen(n_pabins)*180./2./n_pabins
  
  status = 1
  ;============= ion ==============
  if ((species eq 'ion') or (species eq 'all')) then begin
  
    ; check to make sure the data exist
    get_data, 'mms'+probe+'_epd_eis_' + data_name + '_pitch_angle_t0', data=d, index = index
    if index eq 0 then begin
      print, 'No ion data is currently loaded for probe '+probe+' for the selected time period'
      status = 0
      stop
    endif
    
    ; if data exists continue
    if status ne 0 then begin
      for ion_type_idx = 0, n_elements(ion_type)-1 do begin
          ; get pa from each detector
          get_data, 'mms'+probe+'_epd_eis_' + data_name + '_pitch_angle_t0', data = d
          flux_file = fltarr(n_elements(d.x),6) ; time steps, look direction
          pa_file = fltarr(n_elements(d.x),6) ; time steps, look direction
          pa_file[*,0] = d.y
          pa_flux = fltarr(n_elements(d.x),n_pabins)
          
          for t=0, 5 do begin
            get_data, 'mms'+probe+'_epd_eis_' + data_name + '_pitch_angle_t'+STRTRIM(t, 1), data = d
            pa_file[*,t] = reform(d.y)
          
          ; get flux from each detector
            get_data, 'mms'+probe+'_epd_eis_' + data_name + '_' + ion_type[ion_type_idx] + '_' + data_units + '_t'+STRTRIM(t, 1), data = d
            
            ; get energy range of interest
            e = d.v
            indx = where((e lt energy[1]) and (e gt energy[0]), energy_count)
                    
            if energy_count eq 0 then begin
              print, 'Energy range selected is not covered by the detector for ' + data_name + ' ' + ion_type[ion_type_idx] + ' ' + data_units
              continue
            endif
            
            ; Loop through each time step and get:
            ; 1.  the total flux for the energy range of interest for each detector
            ; 2.  flux in each pa bin
            for i=0, n_elements(d.x)-1 do begin ; loop through time
              flux_file[i,t] = total(reform(d.y[i,indx]))  ; start with lowest energy
              
              for j=0, n_pabins-1 do begin ; loop through pa bins
                if (pa_file[i,t] gt pa_bins[j]) and (pa_file[i,t] lt pa_bins[j+1]) then begin
                  pa_flux[i,j] = flux_file[i,t]
                endif
              endfor
            endfor
          endfor
          en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV
          new_name = 'mms'+probe+'_epd_eis_ion_' + data_name + '_' + en_range_string + '_' + ion_type[ion_type_idx] + '_' + data_units + '_pad'
          store_data, new_name, data={x:d.x, y:pa_flux, v:pa_label}
          options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1 , $
            zlog = 1, ytitle = 'MMS'+probe+' EIS ' + ion_type[ion_type_idx], ysubtitle='PA [Deg]', ztitle=units_label
      endfor
                  
    endif
  
  
  endif
  

  status = 1
  ;============ elect ============
  if ((species eq 'electron') or (species eq 'all')) then begin

;    ; check to make sure the data exist
;    get_data, 'mms'+probe+'_epd_eis_electronenergy_pitch_angle_t0', data=d
;    if d eq 0 then begin
;      print, 'No ion data is currently loaded for probe '+probe+' for the selected time period'
;      status = 0
;    endif
    
  
  ; check to make sure the data exist
  get_data, 'mms'+probe+'_epd_eis_electronenergy_pitch_angle_t0', data=d, index = index
  if index eq 0 then begin
    print, 'No electron data is currently loaded for probe '+probe+' for the selected time period'
    status = 0
    stop
  endif
  
  ; if data exists continue
  if status ne 0 then begin
  
    ; get pa from each detector
    get_data, 'mms'+probe+'_epd_eis_electronenergy_pitch_angle_t0', data = d
    flux_file = fltarr(n_elements(d.x),6) ; time steps, look direction
    pa_file = fltarr(n_elements(d.x),6) ; time steps, look direction
    pa_file[*,0] = d.y
    pa_flux = fltarr(n_elements(d.x),n_pabins)
  
    for t=0, 5 do begin
      get_data, 'mms'+probe+'_epd_eis_electronenergy_pitch_angle_t'+STRTRIM(t, 1), data = d
      pa_file[*,t] = reform(d.y)
  
      ; get flux from each detector
      get_data, 'mms'+probe+'_epd_eis_electronenergy_electron_cps_t'+STRTRIM(t, 1), data = d
  
      ; get energy range of interest
      e = d.v
      indx = where((e lt energy[1]) and (e gt energy[0]))
  
      if indx[0] eq -1 then begin
        print, 'Energy range selected is not covered by the detector'
        stop
      endif
  
      ; Loop through each time step and get:
      ; 1.  the total flux for the energy range of interest for each detector
      ; 2.  flux in each pa bin
      for i=0l, n_elements(d.x)-1 do begin ; loop through time
        flux_file[i,t] = total(reform(d.y[i,indx]))  ; start with lowest energy
  
        for j=0, n_pabins-1 do begin ; loop through pa bins
          if (pa_file[i,t] gt pa_bins[j]) and (pa_file[i,t] lt pa_bins[j+1]) then begin
            pa_flux[i,j] = flux_file[i,t]
          endif
        endfor
  
      endfor
  
    endfor
  
  endif
  
  store_data, 'mms'+probe+'_epd_eis_electron_pad', data={x:d.x, y:pa_flux, v:pa_label}
  options, 'mms'+probe+'_epd_eis_electron_pad', yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
    zlog = 1, ytitle = 'MMS'+probe+' EIS Electron', ysubtitle='PA [Deg]', ztitle='Counts/s'
  
 endif

end