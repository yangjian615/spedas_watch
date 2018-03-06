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
;       + 2017-12-04, I. Cohen          : added creation of spin-averaged variable; changed to calculate combined
;                                         variables for each individual telescope, instead of just the omni variable;
;                                         added calls to mms_eis_spin_avg.pro and mms_eis_omni.pro
;       + 2018-01-19, I. Cohen          : added capability to handle multiple s/c at once and combine at the end
;       + 2018-02-19, I. Cohen          : added "total" to NAN creation on lines 77-78 to fix syntax
;                                         
;-
pro mms_eis_combine_proton_spec, probes=probes, data_rate = data_rate, data_units = data_units
  ;
  compile_opt idl2
  if not KEYWORD_SET(probes) then probes = '1'
  if not KEYWORD_SET(data_rate) then data_rate = 'srvy'
  if not KEYWORD_SET(data_units) then data_units = 'flux'
  if (data_units ne 'flux') then begin
    print,'Combination of PHxTOF and ExTOF data products is only recommended for flux data!'
    return
  endif
  ;
  for pp=0,n_elements(probes)-1 do begin
    ;
    if (data_rate eq 'brst') then eis_prefix = 'mms'+probes[pp]+'_epd_eis_brst_' else eis_prefix = 'mms'+probes[pp]+'_epd_eis_'
    ;
    extof_vars = tnames(eis_prefix+'extof_proton_P?_'+data_units+'_t?')
    if (extof_vars[0] eq '') then begin
      print,'Must load ExTOF data to combine proton spectra'
      return
    endif
    phxtof_vars = tnames(eis_prefix+'phxtof_proton_P?_'+data_units+'_t?')
    if (phxtof_vars[0] eq '') then begin
      print,'Must load PHxTOF data to combine proton spectra'
      return
    endif
    str = string(strsplit(extof_vars[0], '_', /extract))
    if (data_rate eq 'brst') then p_num = strmid(str[6],1,1) else p_num = strmid(str[5],1,1)
    ;
    for aa=0,n_elements(extof_vars)-1 do begin
      ;
      ; Make sure ExTOF and PHxTOF data have the same time dimension
      get_data,extof_vars[aa],data=proton_extof
      get_data,phxtof_vars[aa],data=proton_phxtof
      data_size = [n_elements(proton_phxtof.x),n_elements(proton_extof.x)]
      if (data_size[0] eq data_size[1]) then begin
        time_data = proton_phxtof.x
        phxtof_spec_data = proton_phxtof.y
        extof_spec_data = proton_extof.y
      endif else if (data_size[0] gt data_size[1]) then begin
        time_data = proton_extof.x
        phxtof_spec_data = proton_phxtof.y[0:n_elements(proton_extof.x)-1,*]
        extof_spec_data = proton_extof.y
      endif else if (data_size[0] lt data_size[1]) then begin
        time_data = proton_phxtof.x
        phxtof_spec_data = proton_phxtof.y
        extof_spec_data = proton_extof.y[0:n_elements(proton_phxtof.x)-1,*]
      endif
      if (total(where(phxtof_spec_data eq 0)) ge 0) then phxtof_spec_data[where(phxtof_spec_data eq 0)] = !Values.d_NAN
      if (total(where(extof_spec_data eq 0) ge 0)) then extof_spec_data[where(extof_spec_data eq 0)] = !Values.d_NAN
      ;
      target_phxtof_energies = where(proton_phxtof.v lt 42, n_target_phxtof_energies)
      target_phxtof_crossover_energies = where(proton_phxtof.v gt 42, n_target_phxtof_crossover_energies)
      target_extof_crossover_energies = where(proton_extof.v lt 81, n_target_extof_crossover_energies)
      target_extof_energies = where(proton_extof.v gt 81, n_target_extof_energies)
      n_energies = n_target_phxtof_energies +  n_target_phxtof_crossover_energies + n_target_extof_energies
      ;
      combined_array = dblarr(n_elements(time_data),n_energies) + !Values.d_NAN                                         ; time x energy
      combined_energy = dblarr(n_energies) + !Values.d_NAN                                                              ; energy
      ;
      ; Combine spectra and store new tplot variable
      combined_array[*,0:n_target_phxtof_energies-1] = phxtof_spec_data[*,target_phxtof_energies]
      for tt=0,n_elements(time_data)-1 do for ii=0,n_target_phxtof_crossover_energies-1 do combined_array[tt,n_target_phxtof_energies+ii] = average([phxtof_spec_data[tt,target_phxtof_crossover_energies[ii]],extof_spec_data[tt,target_extof_crossover_energies[ii]]],/NAN)
      combined_array[*,n_elements(proton_phxtof.v):-1] = extof_spec_data[*,target_extof_energies]
      combined_energy = [proton_phxtof.v[target_phxtof_energies],(proton_phxtof.v[target_phxtof_crossover_energies]+proton_extof.v[target_extof_crossover_energies])/2d,proton_extof.v[target_extof_energies]]
      ;
      combined_array[where(finite(combined_array) eq 0)] = 0d
      store_data,eis_prefix+'combined_proton_P'+p_num[0]+'_'+data_units+'_t'+strtrim(string(aa),2),data={x:time_data,y:combined_array,v:combined_energy}
      tdegap,eis_prefix+'combined_proton_P'+p_num[0]+'_'+data_units+'_t'+strtrim(string(aa),2), /overwrite
      options,eis_prefix+'combined_proton_P'+p_num[0]+'_'+data_units+'_t'+strtrim(string(aa),2),spec=1,zrange=[5e0,5e4],zticks=0,zlog=1,minzlog=0.01,yrange=[14,650],yticks=2,ystyle=1,ylog=0,no_interp=1, $
        ysubtitle='Energy!C[keV]',ztitle='1/(cm!E2!N-sr-s-keV)'
      ;
    endfor
    ;
    mms_eis_spin_avg, probe=probes[pp], datatype='combined', species='proton', data_units = data_units, data_rate = data_rate
    ;
    mms_eis_omni, probes[pp], species='proton', datatype='combined', tplotnames = tplotnames, suffix = '', data_units = data_units, data_rate = data_rate
    mms_eis_omni, probes[pp], species='proton', datatype='combined', tplotnames = tplotnames, suffix = '_spin', data_units = data_units, data_rate = data_rate
    ;
  endfor
  ;
  if (n_elements(probes) gt 1) then mms_eis_spec_combine_sc, probes=probes, species = 'proton', data_units = data_units, datatype = 'combined', data_rate = data_rate
end