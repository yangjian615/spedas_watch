;+
; Procedure:
;         poes_overview_plot
;         
; Purpose:
;         Generates overview plots for POES data
;              
; Keywords:
;         probe: 
;         date: 
;         duration:
;         
; Notes:
;       
;       
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-11-14 10:13:54 -0800 (Fri, 14 Nov 2014) $
; $LastChangedRevision: 16185 $
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
    
    if undefined(date) then date = '2013-03-17'
    if undefined(probe_in) then probe_in = 'noaa19'
    if undefined(duration) then duration = 1 ; days

    timespan, date, duration, /day
    
    window_xsize = 750
    window_ysize = 800
    
    poes_load_data, probes = probe_in, datatype = ['ted_ele_eflux', 'ted_pro_eflux', 'mep_ele_flux', 'mep_pro_flux', 'mep_omni_flux']

    ; combine high/low energy efluxes so that we can plot different telescopes on different plots
    ; ted_ele_tel0_*_eflux  
    join_vec, tnames(probe_in+'_'+'ted_ele_tel?_*_eflux'), 'ted_ele_eflux_tel0'
    
    ; ted ele tel30 eflux
    join_vec, tnames(probe_in+'_'+'ted_ele_tel??_*_eflux'), 'ted_ele_eflux_tel30'
    
    ; ted pro tel0 eflux
    join_vec, tnames(probe_in+'_'+'ted_pro_tel?_*_eflux'), 'ted_pro_eflux_tel0'
    
    ; ted pro tel30 eflux
    join_vec, tnames(probe_in+'_'+'ted_pro_tel??_*_eflux'), 'ted_pro_eflux_tel30'
    
    
    ; setup the plot
    window, xsize=window_xsize, ysize=window_ysize
    time_stamp,/off
    loadct2,43
    !p.charsize=0.8
    
    tplot, ['ted_ele_eflux_tel30', 'ted_ele_eflux_tel0', 'ted_pro_eflux_tel0', 'ted_pro_eflux_tel30', probe_in+'_mep_ele_flux_tel?', probe_in+'_mep_ele_flux_tel??', probe_in+'_mep_pro_flux_tel?', probe_in+'_mep_pro_flux_tel??', probe_in+'_mep_omni_flux']
    stop

end