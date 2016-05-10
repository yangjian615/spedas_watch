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
; $LastChangedDate: 2016-05-09 14:56:40 -0700 (Mon, 09 May 2016) $
; $LastChangedRevision: 21051 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_set_metadata.pro $
;-
;
pro mms_eis_set_metadata, tplotnames, probe = probe, level=level, data_rate = data_rate, suffix = suffix, datatype = datatype, no_interp=no_interp
    if undefined(probe) then probe = '1'
    if undefined(level) then level = ''
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(suffix) then suffix = ''
    if undefined(datatype) then datatype = 'extof'
    
    case datatype of 
        'extof': begin
            ylim,'*_extof_proton_flux_omni*', 55, 1000, 1
            ylim,'*_extof_alpha_flux_omni*', 80, 650, 1
            ylim,'*_extof_oxygen_flux_omni*', 145, 950, 1
            zlim, '*_extof_proton_flux_omni*', 0, 0, 1
            zlim, '*_extof_alpha_flux_omni*', 0, 0, 1
            zlim, '*_extof_oxygen_flux_omni*', 0, 0, 1
            options, '*_extof_*_flux_omni*', ystyle=1
            if undefined(no_interp) && data_rate eq 'srvy' then options, '*extof_*_flux_omni*', no_interp=0, y_no_interp=0
        end
        'phxtof': begin
            ; still todo: need to set ylimits based on P#
            ; energy depends on version of files
            
            zlim, '*phxtof_*_flux_omni*', 0, 0, 1
            options, '*_phxtof_*_flux_omni*', ystyle=1
            if undefined(no_interp) && data_rate eq 'srvy' then options, '*phxtof_*_flux_omni*', no_interp=0, y_no_interp=0
        end
        'electronenergy': begin
            ylim,'*_electronenergy_electron_flux_omni*', 40, 660, 1
            zlim, '*_electronenergy_electron_flux_omni*', 0, 0, 1
            options, '*_electronenergy_electron_flux_omni*', ystyle=1
            if undefined(no_interp) && data_rate eq 'srvy' then options, '*_electronenergy_electron_flux_omni*', no_interp=0, y_no_interp=0
        end  
    endcase

end