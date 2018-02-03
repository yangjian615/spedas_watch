;+
; PROCEDURE:
;   mms_eis_combine_proton_pad.pro
;
; PURPOSE:
;   Combine ExTOF and PHxTOF proton PADs into a single combined tplot variable
;
; KEYWORDS:
;         probes:             string indicating value for MMS SC #
;         data_rate:          data rate ['srvy' (default), 'brst']
;         data_units:         data units ['flux' (default), 'cps', 'counts']
;         size_pabin:         size of the pitch angle bins
;         energy:             energy range to include in the calculation
;
; CREATED BY: I. Cohen, 2017-11-17
;
; REVISION HISTORY:
;       + 2017-11-17, I. Cohen      : changed probes keyword to probes
;       
;
;-
pro mms_eis_combine_proton_pad, probes=probes, data_rate = data_rate, data_units = data_units, size_pabin = size_pabin, energy = energy
  ;
  compile_opt idl2
  if not KEYWORD_SET(data_rate) then data_rate = 'srvy'
  if not KEYWORD_SET(data_units) then data_units = 'flux'
  if (data_units ne 'flux') then begin
    print,'Combination of PHxTOF and ExTOF data products is only recommended for flux data!'
    return
  endif
  if not KEYWORD_SET(size_pabin) then size_pabin = 15
  if not KEYWORD_SET(energy) then energy = [55,800]
  ;
  if (data_rate eq 'brst') then eis_prefix = 'mms'+probes+'_epd_eis_brst_' else eis_prefix = 'mms'+probes+'_epd_eis_'
  units_label = data_units eq 'cps' ? '1/s': '1/(cm!U2!N-sr-s-keV)'
  ;
  ; set up the number of pa bins to create
  size_pabin = double(size_pabin)
  n_pabins = 180./size_pabin
  pa_bins = 180.*indgen(n_pabins+1)/n_pabins
  pa_label = 180.*indgen(n_pabins)/n_pabins+size_pabin/2.
  ;
  ; Account for angular response (finite field of view) of instruments
  pa_halfang_width = 10.0         ; [deg]
  delta_pa = size_pabin/2d
  ;
  extof_pads_var = tnames(eis_prefix+'extof*proton*pads')
  if (extof_pads_var eq '') then begin
    print, 'CANNOT FIND EXTOF PROTON PAD VARIABLE FROM MMS_EIS_PAD.PRO'
    return
  endif
  get_data,extof_pads_var,data=extof_pad
  ;
  mms_eis_combine_proton_spec, probes=probes, data_rate = data_rate, data_units = data_units
  get_data,eis_prefix+'combined_proton_flux_omni',data=proton_combined_spec
  if (isa(proton_combined_spec,'STRUCT') eq 0) then begin
    print,'COMBINED EIS PROTON SPECTRUM FROM MMS_EIS_COMBINE_PROTON_SPEC.PRO NOT FOUND!
    return
  endif
  ;
  phxtof_pads_var = tnames(eis_prefix+'phxtof*pads')
  if (phxtof_pads_var eq '') then begin
    print, 'CANNOT FIND PHXTOF PROTON PAD VARIABLE FROM MMS_EIS_PAD.PRO'
    return
  endif
  get_data,phxtof_pads_var,data=phxtof_pad
  ;
  ; Make sure ExTOF and PHxTOF data have the same time dimension
  data_size = [n_elements(phxtof_pad.x),n_elements(extof_pad.x)]
  if (data_size[0] eq data_size[1]) then begin
    time_data = phxtof_pad.x
    phxtof_pad_data = phxtof_pad.y
    extof_pad_data = extof_pad.y
  endif else if (data_size[0] gt data_size[1]) then begin
    time_data = extof_pad.x
    phxtof_pad_data = phxtof_pad.y[0:n_elements(extof_pad.x)-1,*,*]
    extof_pad_data = extof_pad.y
  endif else if (data_size[0] lt data_size[1]) then begin
    time_data = phxtof_pad.x
    phxtof_pad_data = phxtof_pad.y
    extof_pad_data = extof_pad.y[0:n_elements(phxtof_pad.x)-1,*,*]
  endif
  ;
  energy_size = where((proton_combined_spec.v ge energy[0]) and (proton_combined_spec.v le energy[1]))
  proton_pad = dblarr(n_elements(time_data),n_pabins,n_elements(energy_size)) + !Values.d_NAN                                               ; time x bins x energy
  ;
  target_phxtof_energies = where(phxtof_pad.v2 lt 42, n_target_phxtof_energies)
  target_phxtof_crossover_energies = where(phxtof_pad.v2 gt 42, n_target_phxtof_crossover_energies)
  target_extof_crossover_energies = where(extof_pad.v2 lt 81, n_target_extof_crossover_energies)
  target_extof_energies = where(extof_pad.v2 gt 81, n_target_extof_energies)
  ;
  proton_pad[*,*,0:n_target_phxtof_energies-1] = phxtof_pad_data[*,*,target_phxtof_energies]
  for tt=0,n_elements(time_data)-1 do for bb=0,n_pabins-1 do for ii=0,n_target_phxtof_crossover_energies-1 do proton_pad[tt,bb,n_target_phxtof_energies:n_target_phxtof_energies+ii] = average([phxtof_pad_data[tt,bb,target_phxtof_crossover_energies[ii]],extof_pad_data[tt,bb,target_extof_crossover_energies[ii]]],/NAN)
  proton_pad[*,*,n_elements(phxtof_pad.v2):-1] = extof_pad_data[*,*,target_extof_energies]
  proton_energy = [phxtof_pad.v2[target_phxtof_energies],(phxtof_pad.v2[target_phxtof_crossover_energies]+extof_pad.v2[target_extof_crossover_energies])/2d,extof_pad.v2[target_extof_energies]]
  for ee=0,n_elements(proton_energy)-1 do begin
    store_data,eis_prefix+'combined_'+strtrim(string(fix(proton_energy[ee])),2)+'keV_proton_flux_omni_pad',data={x:time_data,y:reform(proton_pad[*,*,ee]),v:pa_label}
    options,eis_prefix+'combined_'+strtrim(string(fix(proton_energy[ee])),2)+'keV_proton_flux_omni_pad', spec=1, yrange = [0,180], ystyle=1, /no_interp, /extend_y_edges, $
      ytitle='mms'+probes+'!C'+data_rate+'!Cproton!C'+strtrim(string(fix(proton_energy[ee])),2)+'keV', ysubtitle='PA!C[deg]', minzlog=.01, ztitle=units_label
    zlim,eis_prefix+'combined_'+strtrim(string(fix(proton_energy[ee])),2)+'keV_proton_flux_omni_pad', 5e2, 1e4, 1
    tdegap, eis_prefix+'combined_'+strtrim(string(fix(proton_energy[ee])),2)+'keV_proton_flux_omni_pad', /overwrite
  endfor
  ;
  proton_pad_integral = dblarr(n_elements(time_data),n_pabins) + !Values.d_NAN                                                              ; time x bins
  store_data,eis_prefix+'combined_proton_flux_omni_pads',data={x:time_data,y:proton_pad,v1:pa_label,v2:proton_energy}
  tdegap,eis_prefix+'combined_proton_flux_omni_pads',/overwrite
  for tt=0,n_elements(time_data)-1 do for bb=0,n_pabins-1 do proton_pad_integral[tt,bb] = average(proton_pad[tt,bb,*],/NAN)
  store_data,eis_prefix+'combined_'+strtrim(string(fix(energy[0])),2)+'-'+strtrim(string(fix(energy[-1])),2)+'keV_proton_flux_omni_pad', data={x:time_data,y:proton_pad_integral,v:pa_label}
  options,eis_prefix+'combined_'+strtrim(string(fix(energy[0])),2)+'-'+strtrim(string(fix(energy[-1])),2)+'keV_proton_flux_omni_pad', spec=1, yrange = [0,180], ystyle=1, /no_interp, /extend_y_edges, $
    ytitle='mms'+probes+'!C'+data_rate+'!Cproton!C'+strtrim(string(fix(energy[0])),2)+'-'+strtrim(string(fix(energy[-1])),2)+'keV', ysubtitle='PA!C[deg]', minzlog=.01, ztitle=units_label
  zlim,eis_prefix+'combined_'+strtrim(string(fix(energy[0])),2)+'-'+strtrim(string(fix(energy[-1])),2)+'keV_proton_flux_omni_pad', 5e2, 1e4, 1
  tdegap, eis_prefix+'combined_'+strtrim(string(fix(energy[0])),2)+'-'+strtrim(string(fix(energy[-1])),2)+'keV_proton_flux_omni_pad', /overwrite
  ;
end