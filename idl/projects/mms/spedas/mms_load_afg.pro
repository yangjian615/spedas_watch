;+
; PROCEDURE:
;         mms_load_dfg
;
; PURPOSE:
;         Load data from the Analog Fluxgate (AFG) Magnetometer onboard MMS
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
;$LastChangedDate: 2015-09-09 07:56:34 -0700 (Wed, 09 Sep 2015) $
;$LastChangedRevision: 18735 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_afg.pro $
;-

pro mms_load_afg, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
    no_update = no_update

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(level) then level = 'ql'
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_fgm, trange = trange, probes = probes, level = level, instrument = 'afg', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update

end