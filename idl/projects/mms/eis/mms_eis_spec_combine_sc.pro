;+
; PROCEDURE:
;         mms_eis_spec_combine_sc
;
; PURPOSE:
;         Combines omni-directional energy spectrogram variable from EIS on multiple MMS spacecraft
;
; KEYWORDS:
;         probes:        Probe # to calculate the spin average for
;                       if no probe is specified the default is probe '1'
;         datatype:     eis data types include ['electronenergy', 'extof', 'phxtof'].
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for eis include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts'].
;                       The default is 'flux'.
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         species:      proton (default), oxygen, alpha or electron
;         
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-11-20 09:38:39 -0800 (Mon, 20 Nov 2017) $
; $LastChangedRevision: 24316 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_spec_combine_sc.pro $
; 
; CREATED BY: I. Cohen, 2017-11-17
;
; REVISION HISTORY:
;
;-
pro mms_eis_spec_combine_sc, probes=probes, species = species, data_units = data_units, $
  datatype = datatype, data_rate = data_rate, suffix=suffix
  ;
  compile_opt idl2
  if undefined(probes) then probes='1' else probes = strcompress(string(probes), /rem)
  if undefined(datatype) then datatype = 'extof'
  if undefined(data_units) then data_units = 'flux'
  if undefined(species) then species = 'proton'
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  if datatype eq 'electronenergy' then species = 'electron'
  ;
  if (data_rate eq 'brst') then allmms_prefix = 'mms'+probes[0]+'-'+probes[-1]+'_epd_eis_brst_'+datatype+'_' else prefix = 'mms'+probes[0]+'-'+probes[-1]+'_epd_eis_'+datatype+'_'
  ;
  ; DETERMINE SPACECRAFT WITH SMALLEST NUMBER OF TIME STEPS TO USE AS REFERENCE SPACECRAFT
  omni_vars = tnames('mms?_epd_eis_brst_'+datatype+'_'+species+'_flux_omni')
  time_size = dblarr(n_elements(probes))
  for pp=0,n_elements(probes)-1 do begin
    get_data, omni_vars[pp], data=thisprobe_pad
    time_size[pp] = n_elements(thisprobe_pad.x)
  endfor
  ref_sc_time_size = min(time_size, ref_sc_loc)
  get_data, omni_vars[ref_sc_loc], data=temp_refprobe
  omni_spec_data = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v),n_elements(probes)) + !Values.d_NAN       ; time x energy x spacecraft
  omni_spec = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v)) + !Values.d_NAN                               ; time x energy
  energy_data = dblarr(n_elements(temp_refprobe.v),n_elements(probes))
  common_energy = dblarr(n_elements(temp_refprobe.v))  
  ;
  ; Average omni flux over all spacecraft and define common energy grid
  for pp=0,n_elements(omni_vars)-1 do begin
    get_data,omni_vars[pp],data=temp_data
    energy_data[*,pp] = temp_data.v[0:n_elements(common_energy)-1]
    start_time_loc = where((temp_data.x ge temp_refprobe.x[0]) and (temp_data.x le temp_refprobe.x[1]))
    omni_spec_data[0:ref_sc_time_size-1,*,pp] = temp_data.y[start_time_loc[0]:start_time_loc[0]+ref_sc_time_size-1,*]
  endfor
  for ee=0,n_elements(common_energy)-1 do common_energy[ee] = average(energy_data[ee,*],/NAN)
  ;
  ; Average omni flux over all spacecraft
  for tt=0,n_elements(temp_refprobe.x)-1 do for ee=0,n_elements(temp_refprobe.v)-1 do omni_spec[tt,ee] = average(omni_spec_data[tt,ee,*],/NAN)
  ;
  ; store new tplot variable
  omni_spec[where(finite(omni_spec) eq 0)] = 0d
  store_data, allmms_prefix+species+'_flux_omni', data={x:temp_refprobe.x,y:omni_spec,v:temp_refprobe.v}
  options, allmms_prefix+species+'_flux_omni', yrange = minmax(common_energy), ystyle=1, spec = 1, no_interp=1, ysubtitle='Energy [keV]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001
  zlim, allmms_prefix+species+'_flux_omni', 0, 0, 1
  ;
end
