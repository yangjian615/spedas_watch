;+
;
; PROCEDURE:
;     mms_eis_set_metadata
;
; PURPOSE:
;     This procedure sets some metadata for EIS data products
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-29 14:51:10 -0700 (Fri, 29 Apr 2016) $
; $LastChangedRevision: 20981 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_set_metadata.pro $
;-
;
pro mms_eis_set_metadata, tplotnames, probe = probe, level=level, data_rate = data_rate, suffix = suffix, no_interp=no_interp
    if undefined(probe) then probe = '1'
    if undefined(level) then level = ''
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix = ''

    ylim,'*_electronenergy_electron_flux_omni*', 40, 660, 1
    ylim,'*_extof_proton_flux_omni*', 55, 1000, 1
    ylim,'*_extof_alpha_flux_omni*', 80, 650, 1
    ylim,'*_eis_extof_oxygen_flux_omni*', 145, 950, 1
    options, '*_extof_proton_flux_omni*', ystyle=1
    
    if undefined(no_interp) && data_rate eq 'srvy' then options, '*_omni*', no_interp=0, y_no_interp=0
end