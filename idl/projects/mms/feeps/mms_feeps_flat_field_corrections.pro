;+
; PROCEDURE:
;       mms_feeps_flat_field_corrections
;
; PURPOSE:
;       Apply flat field correction factors to FEEPS ion data
;
; NOTES:
; 
;   From Drew Turner, 1/18/17:
;       Here are the correction factors that we need to apply to the current 
;       ION counts/rates/fluxes in the CDF files.  
;       NOTE, THIS IS A DIFFERENT TYPE OF CORRECTION THAN THAT FOR THE ELECTRONS!  
;       These shifts should be applied to the counts/rates/fluxes data EYE-BY-EYE on each spacecraft.  
;       These are multiplication factors (i.e., Jnew = Jold * Gcorr). 
;       For those equations, Jold is the original count/rate/flux array and
;       Jnew is the corrected version of the arrays using the factors listed below.
;       
;MMS1:
;Top6: Gcorr = 0.7
;Top7: Gcorr = 2.5
;Top8: Gcorr = 1.5
;Bot6: Gcorr = 0.9
;Bot7: Gcorr = 1.2
;Bot8: Gcorr = 1.0
;
;MMS2:
;Top6: Gcorr = 1.3
;Top7: BAD EYE
;Top8: Gcorr = 0.8
;Bot6: Gcorr = 1.4
;Bot7: BAD EYE
;Bot8: Gcorr = 1.5
;
;MMS3:
;Top6: Gcorr = 0.7
;Top7: Gcorr = 0.8
;Top8: Gcorr = 1.0
;Bot6: Gcorr = 0.9
;Bot7: Gcorr = 0.9
;Bot8: Gcorr = 1.3
;
;MMS4:
;Top6: Gcorr = 0.8
;Top7: BAD EYE
;Top8: Gcorr = 1.0
;Bot6: Gcorr = 0.8
;Bot7: Gcorr = 0.6
;Bot8: Gcorr = 0.9
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-01-18 15:59:59 -0800 (Wed, 18 Jan 2017) $
; $LastChangedRevision: 22624 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_flat_field_corrections.pro $
;-


pro mms_feeps_flat_field_corrections, data_rate = data_rate
  if undefined(data_rate) then data_rate = 'brst'

  G_corr = hash()
  G_corr['mms1-top6'] = 0.7
  G_corr['mms1-top7'] = 2.5
  G_corr['mms1-top8'] = 1.5
  G_corr['mms1-bot6'] = 0.9
  G_corr['mms1-bot7'] = 1.2
  G_corr['mms1-bot8'] = 1.0

  G_corr['mms2-top6'] = 1.3
  G_corr['mms2-top7'] = 0 ; bad eye
  G_corr['mms2-top8'] = 0.8
  G_corr['mms2-bot6'] = 1.4
  G_corr['mms2-bot7'] = 0 ; bad eye
  G_corr['mms2-bot8'] = 1.5
  
  G_corr['mms3-top6'] = 0.7
  G_corr['mms3-top7'] = 0.8
  G_corr['mms3-top8'] = 1.0
  G_corr['mms3-bot6'] = 0.9
  G_corr['mms3-bot7'] = 0.9
  G_corr['mms3-bot8'] = 1.3

  G_corr['mms4-top6'] = 0.8
  G_corr['mms4-top7'] = 0 ; bad eye
  G_corr['mms4-top8'] = 1.0
  G_corr['mms4-bot6'] = 0.8
  G_corr['mms4-bot7'] = 0.6
  G_corr['mms4-bot8'] = 0.9
  
  probes = ['1', '2', '3', '4']
  sensor_ids = ['6', '7', '8']
  sensor_types = ['top', 'bot']
  
  for probe_idx = 0, n_elements(probes)-1 do begin
    for sensor_type = 0, n_elements(sensor_types)-1 do begin
      for sensor_id = 0, n_elements(sensor_ids)-1 do begin
        correction = G_corr['mms'+probes[probe_idx]+'-'+sensor_types[sensor_type]+sensor_ids[sensor_id]]

        cr_var = 'mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_l2_ion_'+sensor_types[sensor_type]+'_count_rate_sensorid_'+sensor_ids[sensor_id]
        i_var = 'mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_l2_ion_'+sensor_types[sensor_type]+'_intensity_sensorid_'+sensor_ids[sensor_id]
        c_var = 'mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_l2_ion_'+sensor_types[sensor_type]+'_counts_sensorid_'+sensor_ids[sensor_id]
        
        get_data, cr_var, data=count_rate, dlimits=cr_dl, limits=cr_l
        get_data, i_var, data=intensity, dlimits=i_dl, limits=i_l
        get_data, c_var, data=counts, dlimits=c_dl, limits=c_l

        if is_struct(count_rate) then store_data, cr_var, data={x: count_rate.X, y: count_rate.Y*correction, v: count_rate.V}, dlimits=cr_dl, limits=cr_l
        if is_struct(intensity) then store_data, i_var, data={x: intensity.X, y: intensity.Y*correction, v: intensity.V}, dlimits=i_dl, limits=i_l
        if is_struct(counts) then store_data, c_var, data={x: counts.X, y: counts.Y*correction, v: counts.V}, dlimits=c_dl, limits=c_l
      endfor
    endfor
  endfor

end
