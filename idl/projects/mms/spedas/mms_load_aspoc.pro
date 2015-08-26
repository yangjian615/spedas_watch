;+
; PROCEDURE:
;         mms_load_aspoc
;         
; PURPOSE:
;         Load data from the Active Spacecraft Potential Control (ASPOC)
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         local_data_dir: local directory to store the CDF files
;         no_color_setup: don't setup graphics configuration; use this
;             keyword when you're using this load routine from a
;             terminal without an X server running
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;    
; 
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-25 16:01:06 -0700 (Tue, 25 Aug 2015) $
;$LastChangedRevision: 18616 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_aspoc.pro $
;-

pro mms_load_aspoc, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, tplotnames = tplotnames, $
                  no_color_setup = no_color_setup, instrument = instrument
                  
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = '' 
    if undefined(level) then level = 'l2' 
    if undefined(data_rate) then data_rate = 'srvy'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'aspoc', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, $
        suffix = '_' + level ; set the suffix to the level to avoid clobbering l1b and l2 data
    
end