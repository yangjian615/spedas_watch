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
;
; OUTPUT:
;
;
; NOTES:
;     This was written by Brian Walsh; minor modifications by egrimes@igpp
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-31 13:04:42 -0700 (Fri, 31 Jul 2015) $
;$LastChangedRevision: 18328 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_eis_pad.pro $
;-

pro mms_eis_pad,probe = probe, trange=trange, species = species, energy = energy, bin_size = bin_size;,dataname=dataname

; energy range in keV
  
 ; get_timespan, tspan
  if not KEYWORD_SET(trange) then trange = ['2015-06-28', '2015-06-29']
  if not KEYWORD_SET(probe) then probe = '1'
  if not KEYWORD_SET(species) then species = 'all'
  if not KEYWORD_SET(energy) then energy = [35,45] ; set default energy as lowest energy channel in keV
  if not KEYWORD_SET(bin_size) then bin_size = 10 ; set default energy as lowest energy channel in keV

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
    get_data, 'mms'+probe+'_epd_eis_partenergy_pitch_angle_t0', data=d, index = index
    if index eq 0 then begin
      print, 'No ion data is currently loaded for probe '+probe+' for the selected time period'
      status = 0
      stop
    endif
    
    ; if data exists continue
    if status ne 0 then begin
      
      ; get pa from each detector
      get_data, 'mms'+probe+'_epd_eis_partenergy_pitch_angle_t0', data = d
      flux_file = fltarr(n_elements(d.x),6) ; time steps, look direction
      pa_file = fltarr(n_elements(d.x),6) ; time steps, look direction
      pa_file[*,0] = d.y
      pa_flux = fltarr(n_elements(d.x),n_pabins)

      for t=0, 5 do begin
        get_data, 'mms'+probe+'_epd_eis_partenergy_pitch_angle_t'+STRTRIM(t, 1), data = d
        pa_file[*,t] = reform(d.y)
      
      ; get flux from each detector
        get_data, 'mms'+probe+'_epd_eis_partenergy_nonparticle_cps_t'+STRTRIM(t, 1), data = d
        
        ; get energy range of interest
        e = d.v
        indx = where((e lt energy[1]) and (e gt energy[0]))
                
        if indx eq -1 then begin
          print, 'Energy range selected is not covered by the detector'
          stop
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
                  
    endif
  
    store_data, 'mms'+probe+'_epd_eis_ion_pad', data={x:d.x, y:pa_flux, v:pa_label}
    options, 'mms'+probe+'_epd_eis_ion_pad', yrange = [0,180],spec = 1,no_interp=1 , $
      zlog = 1, ytitle = 'MMS'+probe+' EIS Ion', ysubtitle='PA [Deg]', ztitle='Counts/s'
  
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
  options, 'mms'+probe+'_epd_eis_electron_pad', yrange = [0,180],spec = 1,no_interp=1, $
    zlog = 1, ytitle = 'MMS'+probe+' EIS Electron', ysubtitle='PA [Deg]', ztitle='Counts/s'
  
 endif

end