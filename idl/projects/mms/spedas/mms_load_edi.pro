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
;$LastChangedDate: 2015-08-19 13:46:28 -0700 (Wed, 19 Aug 2015) $
;$LastChangedRevision: 18530 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_edi.pro $
;-

pro mms_load_edi, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'amb'
    if undefined(level) then level = 'l1a'
    if undefined(data_rate) then data_rate = 'fast'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'edi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup

end