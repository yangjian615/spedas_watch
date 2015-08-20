;+
; PROCEDURE:
;         mms_load_scm
;         
; PURPOSE:
;         Load data from the MMS Search Coil Magnetometer (SCM)
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
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-19 13:45:26 -0700 (Wed, 19 Aug 2015) $
;$LastChangedRevision: 18529 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_scm.pro $
;-
pro mms_set_scm_options, tplotnames, prefix = prefix,datatype = datatype, coord=coord
    if undefined(prefix) then prefix = ''

    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]
            
            case tplot_name of
                prefix[sc_idx] + '_scm_'+datatype+'_'+coord : begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) +' '+ datatype +' ('+coord+')' ;' SCM'
                    options, /def, tplot_name, 'labels', ['1', '2', '3']
                    
                end
                else: ; not doing anything
            endcase
        endfor
    endfor

end

pro mms_load_scm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, tplotnames = tplotnames, $
                  no_color_setup = no_color_setup
                  
    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'scf' 
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'fast'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'scm', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames, $
        no_color_setup = no_color_setup
    
    if level eq 'l1a' then coord = '123'
    if level eq 'l1b' then coord = 'scm123'
    if level eq 'l2'  then coord = 'gse'
    
    mms_set_scm_options, tplotnames, prefix = 'mms' + probes,datatype = datatype, coord=coord
end