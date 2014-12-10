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
;         error: error state, 0 for no error, 1 for an error
;         
; Notes:
;       
;       
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-12-08 13:55:26 -0800 (Mon, 08 Dec 2014) $
; $LastChangedRevision: 16408 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_overview_plot.pro $
;-

pro poes_overview_plot, date = date, probe = probe_in, duration = duration, error = error, $
                        gui_overplot = gui_overplot, oplot_calls = oplot_calls
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
    
    if undefined(date) then date = '2013-03-17/00:00:00'
    if undefined(probe_in) then probe_in = 'noaa19'
    if undefined(duration) then duration = 0.08333 ; days
    ;if undefined(duration) then duration = 1 ; days

    timespan, date, duration, /day
    
    window_xsize = 850
    window_ysize = 900
    
    poes_load_data, probes = probe_in

    poes_plots = probe_in+['_ted_ele_flux_tel0_fixed', '_ted_ele_flux_tel30_fixed', $
        '_ted_pro_flux_tel0_fixed', '_ted_pro_flux_tel30_fixed', $
        '_mep_ele_flux_tel?', '_mep_ele_flux_tel??', $
        '_mep_pro_flux_tel?', '_mep_pro_flux_tel??']

    if undefined(gui_overplot) then begin
        ; setup the plot
        window, xsize=window_xsize, ysize=window_ysize
        time_stamp,/off
        loadct2,43
        !p.charsize=0.8
        
        tplot_options, 'title', strupcase(probe_in)
        
        tplot, poes_plots
    
        ; add the ephem labels
        options, /def, probe_in+'_mlt', 'ytitle', 'MLT'
        options, /def, probe_in+'_mag_lat_sat', 'ytitle', 'Lat'
        
        tplot, var_label=[probe_in+'_mlt', probe_in+'_mag_lat_sat']
    endif else begin
        tplot_gui, /no_verify, /add_panel, poes_plots, var_label=[probe_in+'_mlt', probe_in+'_mag_lat_sat']
    
    endelse
    error = 0
end