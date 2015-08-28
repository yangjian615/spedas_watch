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
;         datatype: 'aspoc' for L2 data, 'asp1' or 'asp2' for L1b data
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
;$LastChangedDate: 2015-08-27 15:50:38 -0700 (Thu, 27 Aug 2015) $
;$LastChangedRevision: 18645 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_aspoc.pro $
;-

pro mms_load_aspoc, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, tplotnames = tplotnames, $
                  no_color_setup = no_color_setup, instrument = instrument
                  
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    ; for ASPOC data, datatype = instrument
    if undefined(datatype) then instrument = 'aspoc' else instrument = datatype
    if instrument eq 'asp1' || instrument eq 'asp2' then datatype = 'beam' else datatype = ''
    
    if undefined(level) && instrument eq 'aspoc' then level = 'l2' else level = 'l1b'

    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup, $
        suffix = '_' + level ; set the suffix to the level to avoid clobbering l1b and l2 data
        
    for tvar_idx = 0, n_elements(tplotnames)-1 do begin
        tvar_name = tplotnames[tvar_idx]
        if instrument ne 'aspoc' && strfilter(tvar_name, '*_asp_*') ne '' then begin
            str_replace, tvar_name, '_asp_', '_'+instrument+'_'
            tplot_rename, tplotnames[tvar_idx], tvar_name
        endif
    endfor
end