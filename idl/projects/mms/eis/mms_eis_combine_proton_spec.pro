;+
; mms_eis_combine_proton_spec.pro
;
; PURPOSE:
;   Combine ExTOF and PHxTOF proton energy spectra into a single combined tplot variable
;
; KEYWORDS:
;         probes:             string indicating value for MMS SC #
;         data_rate:          data rate ['srvy' (default), 'brst']
;         data_units:         data units ['flux' (default), 'cps', 'counts']
;
; CREATED BY: I. Cohen, 2017-05-24
;
; REVISION HISTORY:
;       + 2017-06-05, I. Cohen          : added capability to handle burst data
;       + 2017-06-07, I. Cohen          : added capability to handle different data_units
;       + 2017-08-10, I. Cohen          : added warning that combination should only be done for flux data
;       + 2017-08-15, I. Cohen          : adjusted handling of overlapping energy range in combined spectrum
;       + 2017-10-30, I. Cohen          : removed "_omni" suffix
;       + 2017-11-17, I. Cohen          : altered how energy array is constructed; allowed for differences
;                                         in number of time steps between phxtof and extof data; changed probe
;                                         keyword to probes                       
;
;-
pro mms_eis_combine_proton_spec, probes=probes, data_rate = data_rate, data_units = data_units, suffix = suffix
  ;
  compile_opt idl2
  if not KEYWORD_SET(data_rate) then data_rate = 'srvy'
  if not KEYWORD_SET(data_units) then data_units = 'flux'
  if not KEYWORD_SET(suffix) then suffix = ''
  
  if (data_units ne 'flux') then begin
    print,'Combination of PHxTOF and ExTOF data products is only recommended for flux data!'
    return
  endif
  ;
  if (data_rate eq 'brst') then eis_prefix = 'mms'+probes+'_epd_eis_brst_' else eis_prefix = 'mms'+probes+'_epd_eis_'
  ;
  get_data,eis_prefix+'extof_proton_'+data_units+'_omni'+suffix,data=proton_extof
  if ~is_struct(proton_extof) then begin
    print,'Must load ExTOF data to combine proton spectra'
    return
  endif
  get_data,eis_prefix+'phxtof_proton_'+data_units+'_omni'+suffix,data=proton_phxtof
  if ~is_struct(proton_phxtof) then begin
    print,'Must load PHxTOF data to combine proton spectra'
    return
  endif
  ;
  ; Make sure ExTOF and PHxTOF data have the same time dimension
  data_size = [n_elements(proton_phxtof.x),n_elements(proton_extof.x)]
  if (data_size[0] eq data_size[1]) then begin
    time_data = proton_phxtof.x
    phxtof_pad_data = proton_phxtof.y
    extof_pad_data = proton_extof.y
  endif else if (data_size[0] gt data_size[1]) then begin
    time_data = proton_extof.x
    phxtof_pad_data = proton_phxtof.y[0:n_elements(proton_extof.x)-1,*]
    extof_pad_data = proton_extof.y
  endif else if (data_size[0] lt data_size[1]) then begin
    time_data = proton_phxtof.x
    phxtof_pad_data = proton_phxtof.y
    extof_pad_data = proton_extof.y[0:n_elements(proton_phxtof.x)-1,*]
  endif
;  if (n_elements(proton_phxtof.x) ne n_elements(proton_extof.x)) then begin
;    these_times = where(proton_phxtof.x eq proton_extof.x)
;    if (n_elements(these_times) eq n_elements(proton_phxtof.x)) then begin
;      new_proton_extof_x = proton_extof.x[where((proton_extof.x ge proton_phxtof.x[0]) and (proton_extof.x le proton_phxtof.x[-1]))]
;      new_proton_extof_y = proton_extof.y[where((proton_extof.x ge proton_phxtof.x[0]) and (proton_extof.x le proton_phxtof.x[-1])),*]
;      new_proton_phxtof_x = proton_phxtof.x
;      new_proton_phxtof_y = proton_phxtof.y
;    endif else if (n_elements(these_times) eq n_elements(proton_extof.x)) then begin
;      new_proton_phxtof_x = proton_phxtof.x[where((proton_phxtof.x ge proton_extof.x[0]) and (proton_phxtof.x le proton_extof.x[-1]))]
;      new_proton_phxtof_y = proton_phxtof.y[where((proton_phxtof.x ge proton_extof.x[0]) and (proton_phxtof.x le proton_extof.x[-1])),*]
;      new_proton_extof_x = proton_extof.x
;      new_proton_extof_y = proton_extof.y
;    endif
;  endif else begin
;    these_times = proton_phxtof.x
;    new_proton_phxtof_x = proton_phxtof.x
;    new_proton_phxtof_y = proton_phxtof.y
;    new_proton_extof_x = proton_extof.x
;    new_proton_extof_y = proton_extof.y
;  endelse
  ;
  target_phxtof_energies = where(proton_phxtof.v lt 42, n_target_phxtof_energies)
  target_phxtof_crossover_energies = where(proton_phxtof.v gt 42, n_target_phxtof_crossover_energies)
  target_extof_crossover_energies = where(proton_extof.v lt 81, n_target_extof_crossover_energies)
  target_extof_energies = where(proton_extof.v gt 81, n_target_extof_energies)
  n_energies = n_target_phxtof_energies +  n_target_phxtof_crossover_energies + n_target_extof_energies
  ;
  combined_array = dblarr(n_elements(time_data),n_energies) + !Values.d_NAN                                         ; time x energy
  combined_energy = dblarr(n_energies) + !Values.d_NAN                                                                ; energy
  ;
  ; Combine spectra and store new tplot variable
  ;
  combined_array[*,0:n_target_phxtof_energies-1] = phxtof_pad_data[*,target_phxtof_energies]
  for tt=0,n_elements(time_data)-1 do for ii=0,n_target_phxtof_crossover_energies-1 do combined_array[tt,n_target_phxtof_energies:n_target_phxtof_energies+ii] = average([phxtof_pad_data[tt,target_phxtof_crossover_energies[ii]],extof_pad_data[tt,target_extof_crossover_energies[ii]]],/NAN)
  combined_array[*,n_elements(proton_phxtof.v):-1] = extof_pad_data[*,target_extof_energies]
  combined_energy = [proton_phxtof.v[target_phxtof_energies],(proton_phxtof.v[target_phxtof_crossover_energies]+proton_extof.v[target_extof_crossover_energies])/2d,proton_extof.v[target_extof_energies]]
  ;
  store_data,eis_prefix+'combined_proton_flux_omni'+suffix,data={x:time_data,y:combined_array,v:combined_energy}
  tdegap, eis_prefix+'combined_proton_flux_omni'+suffix, /overwrite
  options,eis_prefix+'combined_proton_'+data_units+'_omni'+suffix,spec=1,zrange=[5e0,5e4],zticks=0,zlog=1,minzlog=0.01,yrange=[14,650],yticks=2,ystyle=1,ylog=0,no_interp=1, $
    ytitle='mms'+probes+'!Ceis!C'+data_rate+'!Ccombined!Cproton!Comni',ysubtitle='Energy!C[keV]',ztitle='1/(cm!E2!N-sr-s-keV)'
  ;
end