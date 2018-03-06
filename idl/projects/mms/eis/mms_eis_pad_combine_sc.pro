;+
; PROCEDURE:
;         mms_eis_pad_combine_sc
;
; PURPOSE: Generate composite pitch angle distributions from the EIS sensors across the MMS spacecraft
;       
; CAVEAT: This procedure does not work across HV turnoffs during periods of time when the EIS instruments
;         had varying HV turnoff locations/times (prior to Phase 2b)
;
; KEYWORDS:
;         probes:       value for MMS SC #
;         trange:       time range of interest
;         species:      proton (default), alpha, oxygen, electron
;         level:        data level ['l1a','l1b','l2pre','l2' (default)] 
;         data_rate:    instrument data rates ['brst', 'srvy' (default), 'fast', 'slow']
;         energy:       energy range to include in the calculation
;         datatype:     extof (default), phxtof, electronenergy
;         suffix:       suffix used when loading the data
;
; CREATED BY: I. Cohen, 2017-08-14
;
; REVISION HISTORY:
;       + 2017-11-14, I. Cohen    : removed num_smooth keyword and calls to spd_smooth_time
;       + 2017-11-15, I. Cohen    : removed n_pad_spec and num_smooth keywords; added energy, data_units, datatype, and species keywords to mirror call to mms_eis_pad.pro
;       + 2017-11-17, I. Cohen    : removed combination of phxtof and extof data to rely on use of mms_eis_pad.pro and mms_eis_pad_combine_proton_pad.pro;
;                                   replaced species keyword definition with species and removed species
;       + 2018-01-04, I. Cohen    : fixed if statement for species case of 'proton'
;       + 2018-02-05, I. Cohen    : added suffix keyword
;       + 2018-02-19, I. Cohen    : added ability to handle multiple species                   
;
;-
pro mms_eis_pad_combine_sc, probes = probes, trange = trange, species = species, level = level, data_rate = data_rate, $
                energy = energy, data_units = data_units, datatype = datatype, suffix = suffix
  ;
  compile_opt idl2
  if not KEYWORD_SET(probes) then if (time_double(trange[0]) gt time_double('2016-01-31')) then probes = ['2','3','4'] else probes = ['1','2','3','4']
  if not KEYWORD_SET(data_rate) then data_rate = 'srvy' else data_rate = strlowcase(data_rate)
  if not KEYWORD_SET(scopes) then scopes = ['0','1','2','3','4','5']
  if not KEYWORD_SET(level) then level = 'l2'
  if not KEYWORD_SET(energy) then energy = [55,800]
  if not KEYWORD_SET(data_units) then data_units = 'flux'
  if not KEYWORD_SET(datatype) then datatype = 'extof'
  if not KEYWORD_SET(species) then species = 'proton'
  if not KEYWORD_SET(suffix) then suffix = ''
  if (datatype[0] eq 'electronenergy') then species = 'electron'
  if undefined(combine_proton_spec) then combine_proton_spec = 0
  case species of
    'proton':   if (energy[0] gt 50) and (energy[1] gt 50) then datatype = 'extof' $
                  else if (energy[0] lt 50) and (energy[1] lt 50) then datatype = 'phxtof' $
                  else begin
                    if (combine_proton_spec eq 1) then datatype = ['combined','phxtof','extof']  else datatype = ['phxtof','extof']
                  endelse
    'alpha':      datatype = 'extof'
    'oxygen':     datatype = 'extof'
    'electron':   datatype = 'electronenergy'
  endcase
  ;
  ; Combine flux from all MMS spacecraft into omni-directional array
  if (data_rate eq 'brst') then allmms_prefix = 'mms'+probes[0]+'-'+probes[-1]+'_epd_eis_brst_' else allmms_prefix = 'mms'+probes[0]+'-'+probes[-1]+'_epd_eis_'
  ;
  for dd=0,n_elements(datatype)-1 do begin
    ;
    ; Determine spacecraft with smallest number of time steps to use as reference spacecraft
    if (data_rate eq 'brst') then allmms_pad_vars = tnames('mms*_epd_eis_brst_'+datatype[dd]+'_'+species+'*pads') else allmms_pad_vars = tnames('mms*_epd_eis_'+datatype[dd]+'_'+species+'*pads')
    if (n_elements(allmms_pad_vars) ne n_elements(probes)) then begin
      print, 'EIS data from one or more EIS instruments is missing'
      probes = probes[where(probes eq strmid(allmms_pad_vars,3,1))]
    endif
    time_size = dblarr(n_elements(probes))
    for pp=0,n_elements(probes)-1 do begin
      get_data, allmms_pad_vars[pp], data=thisprobe_pad
      time_size[pp] = n_elements(thisprobe_pad.x)
    endfor
    ref_sc_time_size = min(time_size, ref_sc_loc)
    ;
    ; Define common energy grid across EIS instruments
    get_data, allmms_pad_vars[ref_sc_loc], data=temp_refprobe
    n_energy_chans = dblarr(n_elements(probes))
    for pp=0,n_elements(probes)-1 do begin
      get_data, allmms_pad_vars[pp], data=thisprobe_pad
      n_energy_chans[pp] = n_elements(thisprobe_pad.v2) 
    endfor
    size_energy = min(n_energy_chans,loc_ref_energy)
    energy_data = dblarr(size_energy,n_elements(probes))
    common_energy = dblarr(size_energy)
    for pp=0,n_elements(probes)-1 do begin
      get_data, allmms_pad_vars[pp], data=thisprobe_pad
      energy_data[*,pp] = thisprobe_pad.v2[0:size_energy-1]
    endfor
    for ee=0,n_elements(common_energy)-1 do common_energy[ee] = average(energy_data[ee,*],/NAN)
    ;
    ; create PA labels
    n_pabins = n_elements(temp_refprobe.v1)
    size_pabin = 180d / n_pabins
    pa_label = 180d*indgen(n_pabins)/n_pabins+size_pabin/2.
    ;
    allmms_pad_thisenergy = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v1),n_elements(common_energy),n_elements(probes))                       ; time x bins x energy x spacecraft
    allmms_pad_energy_avg = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v1),n_elements(common_energy))                                          ; time x bins x energy
    allmms_pad_avg = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v1))                                                                           ; time x bins
    ;
    for pp=0,n_elements(probes)-1 do begin                                                                                                                      ; loop through telescopes
      if (data_rate eq 'brst') then thissc_pad_vars = tnames(['mms'+probes[pp]+'_epd_eis_brst_'+datatype[dd]+'_??keV_'+species+'_flux_omni_pad','mms'+probes[pp]+'_epd_eis_brst_'+datatype[dd]+'_???keV_'+species+'_flux_omni_pad']) $
        else thissc_pad_vars = tnames(['mms'+probes[pp]+'_epd_eis_'+datatype[dd]+'_??keV_'+species+'_flux_omni_pad','mms'+probes[pp]+'_epd_eis_'+datatype[dd]+'_???keV_'+species+'_flux_omni_pad'])
      ;
      for ee=0,n_elements(common_energy)-1 do begin
         get_data,thissc_pad_vars[ee],data=temp_data_pad
  ;       start_time_loc = where((temp_data_pad.x ge temp_refprobe.x[0]) and (temp_data_pad.x le temp_refprobe.x[1]))
         allmms_pad_thisenergy[*,*,ee,pp] = temp_data_pad.y[0:n_elements(temp_refprobe.x)-1,*]
      endfor    
    endfor
    ;
    for ee=0,n_elements(common_energy)-1 do begin
      ;
      for tt=0,n_elements(temp_refprobe.x)-1 do for bb=0,n_elements(temp_refprobe.v1)-1 do allmms_pad_energy_avg[tt,bb,ee] = average(allmms_pad_thisenergy[tt,bb,ee,*],/NAN)
      ;
  ;    allmms_pad_energy_avg[where(allmms_pad_energy_avg eq 0)] = !Values.d_NAN
      store_data, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_flux_omni_pad', data={x:temp_refprobe.x,y:reform(allmms_pad_energy_avg[*,*,ee]),v:pa_label}
      options, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_flux_omni_pad', yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
        ysubtitle='PA [Deg]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001
      zlim, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_flux_omni_pad', 5e2, 1e4, 1
      tdegap, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_flux_omni_pad', /overwrite
    endfor
    ;
    store_data,allmms_prefix+datatype[dd]+'_'+species+'_flux_omni_pads',data={x:temp_refprobe.x,y:allmms_pad_energy_avg,v1:pa_label,v2:common_energy}
    tdegap,allmms_prefix+datatype[dd]+'_'+species+'_flux_omni_pads',/overwrite
    ;
  ;  allmms_pad_energy_avg[where(allmms_pad_energy_avg eq 0)] = !Values.d_NAN
    for tt=0,n_elements(temp_refprobe.x)-1 do for bb=0,n_elements(temp_refprobe.v1)-1 do allmms_pad_avg[tt,bb] = average(allmms_pad_energy_avg[tt,bb,*],/NAN)
    store_data, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_flux_omni_pad', data={x:temp_refprobe.x,y:allmms_pad_avg,v:pa_label}
    options, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_flux_omni_pad', yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
      ysubtitle='PA [Deg]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001, /extend_y_edges
    zlim, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_flux_omni_pad', 5e2, 1e4, 1
    tdegap, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_flux_omni_pad', /overwrite
    ;
    spd_smooth_time, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_flux_omni_pad', newname=allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_flux_omni_pad_smth', 20, /nan
  endfor
  ;
end