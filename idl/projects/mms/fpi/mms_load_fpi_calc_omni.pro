;+
; PROCEDURE:
;         mms_load_fpi_calc_omni
;
; PURPOSE:
;         Calculates the omni-directional energy spectra (summed and averaged) 
;         from the individual tplot variables
;
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-19 08:43:08 -0800 (Tue, 19 Jan 2016) $
;$LastChangedRevision: 19755 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_calc_omni.pro $
;-
pro mms_load_fpi_calc_omni, probe, autoscale = autoscale, level = level, datatype = datatype
    if undefined(datatype) then begin
      dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_calc_omni'
      return
    endif
    if undefined(autoscale) then autoscale = 1
    if undefined(level) then level = 'sitl'
    
    ; in case the user passes datatype = '*'
    if (datatype[0] eq '*' || datatype[0] eq '') && level eq 'ql' then datatype=['des', 'dis']
    if (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist']

    species = strmid(datatype, 1, 1)

    for sidx=0, n_elements(species)-1 do begin
        spec_str_format = level eq 'sitl' ? 'EnergySpectr' : 'energySpectr'
        obs_str_format = level eq 'sitl' ? '_fpi_'+species[sidx] : '_d'+species[sidx]+'s_'
        obsstr='mms'+STRING(probe,FORMAT='(I1)')+obs_str_format

        ; get the energy spectra from the tplot variables
        get_data, obsstr+spec_str_format+'_pX', data=pX, dlimits=dl
        get_data, obsstr+spec_str_format+'_mX', data=mX, dlimits=dl
        get_data, obsstr+spec_str_format+'_pY', data=pY, dlimits=dl
        get_data, obsstr+spec_str_format+'_mY', data=mY, dlimits=dl
        get_data, obsstr+spec_str_format+'_pZ', data=pZ, dlimits=dl
        get_data, obsstr+spec_str_format+'_mZ', data=mZ, dlimits=dl

        ; skip avg/sum when we can't find the tplot names
        if ~is_struct(pX) || ~is_struct(mX) || ~is_struct(pY) || ~is_struct(mY) || ~is_struct(pZ) || ~is_struct(mZ) then continue

        e_omni_sum=(pX.Y+mX.Y+pY.Y+mY.Y+pZ.Y+mZ.Y)
        e_omni_avg=e_omni_sum/6.0

        if is_array(e_omni_sum) then begin
            store_data, obsstr+'EnergySpectr_omni_avg', data = {x:pX.X, y:e_omni_avg, v:pX.V}, dlimits=dl
            store_data, obsstr+'EnergySpectr_omni_sum', data = {x:pX.X, y:e_omni_sum, v:pX.V}, dlimits=dl
        endif

        species_str = species[sidx] eq 'e' ? 'electron' : 'ion'
        ; set the metadata for omnidirectional spectra
        options, obsstr+'EnergySpectr_omni_sum', ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str+'!Csum'
        options, obsstr+'EnergySpectr_omni_avg', ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str+'!Cavg'
        options, obsstr+'EnergySpectr_omni_sum', ysubtitle='[eV]'
        options, obsstr+'EnergySpectr_omni_avg', ysubtitle='[eV]'
        options, obsstr+'EnergySpectr_omni_sum', ztitle='Counts'
        options, obsstr+'EnergySpectr_omni_avg', ztitle='Counts'
        ylim, obsstr+'EnergySpectr_omni_avg', min(pX.V), max(pX.V), 1
        if autoscale then zlim, obsstr+'EnergySpectr_omni_avg', 0, 0, 1 else $
            zlim, obsstr+'EnergySpectr_omni_avg', min(e_omni_avg), max(e_omni_avg), 1
        ylim, obsstr+'EnergySpectr_omni_sum', min(pX.V), max(pX.V), 1
        if autoscale then zlim, obsstr+'EnergySpectr_omni_sum', 0, 0, 1 else $
            zlim, obsstr+'EnergySpectr_omni_sum', min(e_omni_sum), max(e_omni_sum), 1

        ; if autoscale isn't set, set the scale to the min/max of the average
        if ~autoscale then zlim, obsstr+'EnergySpectr_'+['pX', 'mX', 'pY', 'mY', 'pZ', 'mZ'], min(e_omni_avg), max(e_omni_avg), 1
    endfor
end