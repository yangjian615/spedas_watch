;+
; Procedure:
;         poes_overview_plot
;         
; Purpose:
;         Generates overview plots for POES data
;              
; Keywords:
;         probe: POES probe to create an overview plot for (noaa18, noaa19, etc.)
;         
;         date: Start date for the overview plot
;         duration: Duration of the overview plot
;         
; Notes:
;       
;       
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-12-03 08:47:59 -0800 (Wed, 03 Dec 2014) $
; $LastChangedRevision: 16344 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_overview_plot.pro $
;-

pro poes_overview_plot, date = date, probe = probe_in, duration = duration
    compile_opt idl2
    
    ; Catch errors and return
    catch, errstats
    if errstats ne 0 then begin
        error = 1
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return 
    endif

    thm_init
    poes_init
    
    if undefined(date) then date = '2013-03-17/9:00:00'
    if undefined(probe_in) then probe_in = 'noaa19'
    if undefined(duration) then duration = 0.08333 ; days

    timespan, date, duration, /day
    
    window_xsize = 850
    window_ysize = 900
    
    poes_load_data, probes = probe_in

    
    ; setup the plot
    window, xsize=window_xsize, ysize=window_ysize
    time_stamp,/off
    loadct2,43
    !p.charsize=0.8
    
    tplot_options, 'title', strupcase(probe_in)
    
    ; need to remove -1s from the TED electron/proton fluxes
    ted_fluxes = probe_in+['_ted_ele_flux_tel0', '_ted_ele_flux_tel30', $
    '_ted_pro_flux_tel0', '_ted_pro_flux_tel30']

    ; we need to "fix" every TED flux tplot variable. By "fix", I mean:
    ;   1) replace all -1s in the data with NaNs
    ;   2) change the fillval in the metadata to NaN
    ;   3) set the y-axis to plot as log by default

    for ted_flux_idx = 0, n_elements(ted_fluxes)-1 do begin
        get_data, ted_fluxes[ted_flux_idx], data=poes_data_to_fix, dlimits=poes_dlimits_to_fix
        
        poes_dlimits_to_fix.cdf.vatt.fillval = !values.F_NAN
        str_element, poes_dlimits_to_fix, 'ylog', 1, /add_replace
        poes_fixed_data = poes_data_to_fix
        
        ; change -1s to NaNs
        for j = 0, n_elements(poes_data_to_fix.Y[0,*])-1 do begin
            poes_fixed_data.Y[where(poes_data_to_fix.Y[*,j] eq -1),j] = !values.f_nan
        endfor
        
        store_data, ted_fluxes[ted_flux_idx]+'_fixed', data=poes_fixed_data, dlimits=poes_dlimits_to_fix
        tdeflag, ted_fluxes[ted_flux_idx]+'_fixed', 'linear', /overwrite
    endfor
    
    tplot, probe_in+['_ted_ele_flux_tel0_fixed', '_ted_ele_flux_tel30_fixed', $
    '_ted_pro_flux_tel0_fixed', '_ted_pro_flux_tel30_fixed', $
    '_mep_ele_flux_tel?', '_mep_ele_flux_tel??', $
    '_mep_pro_flux_tel?', '_mep_pro_flux_tel??']

    ; add the ephem labels
    options, /def, probe_in+'_mlt', 'ytitle', 'MLT'
    options, /def, probe_in+'_mag_lat_sat', 'ytitle', 'Lat'
    tplot, var_label=[probe_in+'_mlt', probe_in+'_mag_lat_sat']
    
end