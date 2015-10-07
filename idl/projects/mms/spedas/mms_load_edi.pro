;+
; PROCEDURE:
;         mms_load_edi
;
; PURPOSE:
;         Load data from the Electron Drift Instrument (EDI) onboard MMS
;
; KEYWORDS:
;         trange: time range of interest [starttime, endtime] with the format ['YYYY-MM-DD','YYYY-MM-DD']
;             or to specificy less than a day ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes: list of probes, valid values for MMS probes are ['1','2','3','4']. If no probe
;             is specified the default is 1
;         level: indicates level of data processing. Current level is ['ql','l1a']. if no level
;             is specified the routine defaults to 'ql' (for survey mode).
;         datatype: data types include currently include ['efield', 'amb']. the default is 'efield'
;         data_rate: instrument data rates include ['brst', 'fast', 'slow', 'srvy']. the default
;             is 'srvy'
;         local_data_dir: local directory to store the CDF files; should be set if
;             you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source: specifies a different system variable. By default the MMS mission system variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;             (support data is specified in the CDF file)
;         tplotnames: names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using this load
;             routine from a terminal without an X server runningdo not set colors
;         time_clip: clip the data to the requested time range; note that if you do not use this keyword
;             you may load a longer time range than requested
;         no_update: set this flag to preserve the original data. if not set and newer data is found the
;             existing data will be overwritten
;
; OUTPUT:
;
; EXAMPLE:
;     See crib sheets mms_load_edi_crib.pro and mms_load_data_crib.pro for usage examples.
;     
;     load edi quick look survey data
;     MMS>  mms_load_edi, data_rate='srvy', probes=probe, datatype='efield', level='ql', $
;                trange=['2015-09-03', '2015-09-04']
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2015-10-06 07:56:30 -0700 (Tue, 06 Oct 2015) $
;$LastChangedRevision: 19008 $
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
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update

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