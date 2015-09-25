;+
; PROCEDURE:
;         mms_load_edi
;
; PURPOSE:
;         Load data from the Electron Drift Instrument (EDI) onboard MMS
;
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         datatype: type of data to load
;         local_data_dir: local directory to store the CDF files
;         no_color_setup: don't setup graphics configuration; use this 
;             keyword when you're using this load routine from a 
;             terminal without an X server running
;
; OUTPUT:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-09-24 09:34:51 -0700 (Thu, 24 Sep 2015) $
;$LastChangedRevision: 18916 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_edi.pro $
;-

pro mms_edi_set_metadata, tplotnames, prefix = prefix, data_rate = data_rate
    if undefined(prefix) then prefix = 'mms1'
    if undefined(instrument) then instrument = 'edi'
    if undefined(data_rate) then data_rate = 'srvy'
    instrument = strlowcase(instrument) ; just in case we get an upper case instrument
    
    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]
    
            case tplot_name of
                prefix[sc_idx] + '_'+instrument+'_E_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Ex', 'Ey', 'Ez']
                end 
                prefix[sc_idx] + '_'+instrument+'_E_bc_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument) + ' BC'
                    options, /def, tplot_name, 'labels', ['Ex', 'Ey', 'Ez']
                end 
                prefix[sc_idx] + '_'+instrument+'_v_ExB_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Vx', 'Vy', 'Vz']
                end 
                prefix[sc_idx] + '_'+instrument+'_v_ExB_bc_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument) + ' BC'
                    options, /def, tplot_name, 'labels', ['Vx', 'Vy', 'Vz']
                end
                else:
            endcase
        endfor
    endfor

end

pro mms_load_edi, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
    no_update = no_update

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'efield'
    if undefined(level) then level = 'ql'
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'edi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update
    
    mms_edi_set_metadata, tplotnames, data_rate=data_rate

end