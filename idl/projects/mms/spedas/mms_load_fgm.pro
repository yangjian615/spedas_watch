;+
; PROCEDURE:
;         mms_load_fgm
;         
; PURPOSE:
;         Load MMS AFG and/or DFG data
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: instrument, AFG, DFG, etc.
;         datatype: not implemented yet 
;         local_data_dir: local directory to store the CDF files
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     1) See the notes in mms_load_data for rules on the use of MMS data
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-23 13:05:38 -0700 (Thu, 23 Jul 2015) $
;$LastChangedRevision: 18229 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fgm.pro $
;-

; takes in 4-d AFG/DFG data as a tplot variable and splits into 2 tplot variables: 
;   1) b_total, 2) b_vector (Bx, By, Bz)
pro mms_split_fgm_data, tplot_name, tplotnames = tplotnames
    get_data, tplot_name, data=fgm_data, dlimits=fgm_dlimits
    
    if is_struct(fgm_data) && is_struct(fgm_dlimits) then begin
        store_data, tplot_name + '_bvec', data={x: fgm_data.X, y: [[fgm_data.Y[*, 0]], [fgm_data.Y[*, 1]], [fgm_data.Y[*, 2]]]}, dlimits=fgm_dlimits
        store_data, tplot_name + '_btot', data={x: fgm_data.X, y: fgm_data.Y[*, 3]}, dlimits=fgm_dlimits
        
        ; need to add the newly created variables from the previous procedure to the list of tplot names
        append_array, tplotnames, tplot_name + '_bvec'
        append_array, tplotnames, tplot_name + '_btot'
        
        ; remove the old variable
        del_data, tplot_name
    endif else begin
        dprint, dlevel = 0, 'Error splitting the tplot variable: ', tplot_name
    endelse
end

; sets colors and labels for tplot
pro mms_load_fix_metadata, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = ''
    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]
    
            case tplot_name of
                prefix[sc_idx] + '_dfg_srvy_dmpa_bvec': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' DFG'
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_dfg_srvy_dmpa_btot': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + ' DFG'
                    options, /def, tplot_name, 'labels', ['B_total']
                end
                prefix[sc_idx] + '_dfg_srvy_gsm_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' DFG'
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end
                prefix[sc_idx] + '_afg_srvy_dmpa_bvec': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' AFG'
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_afg_srvy_dmpa_btot': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + ' AFG'
                    options, /def, tplot_name, 'labels', ['B_total']
                end
                prefix[sc_idx] + '_afg_srvy_gsm_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' AFG'
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end
                prefix[sc_idx] + '_ql_pos_gsm': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'labels', ['Xgsm', 'Ygsm', 'Zgsm', 'R']
                end
                prefix[sc_idx] + '_ql_pos_gse': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'labels', ['Xgse', 'Ygse', 'Zgse', 'R']
                end
                else: ; not doing anything
            endcase
        endfor
    endfor
end

pro mms_load_fgm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, instrument = instrument, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data
    
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    
    if undefined(level) then level = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(local_data_dir) then local_data_dir = ''

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        get_support_data = get_support_data, tplotnames = tplotnames
        
    ; set some of the metadata for the DFG/AFG instruments
    mms_load_fix_metadata, tplotnames, prefix = 'mms' + probes
    
end