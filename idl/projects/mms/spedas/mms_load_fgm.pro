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
;$LastChangedDate: 2015-08-04 15:49:48 -0700 (Tue, 04 Aug 2015) $
;$LastChangedRevision: 18396 $
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
pro mms_load_fix_metadata, tplotnames, prefix = prefix, instrument = instrument
    if undefined(prefix) then prefix = ''
    if undefined(instrument) then instrument = 'dfg'
    instrument = strlowcase(instrument) ; just in case we get an upper case instrument
    
    for sc_idx = 0, n_elements(prefix)-1 do begin
        for name_idx = 0, n_elements(tplotnames)-1 do begin
            tplot_name = tplotnames[name_idx]
    
            case tplot_name of
                prefix[sc_idx] + '_'+instrument+'_srvy_gse_bvec': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_'+instrument+'_srvy_gse_btot': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['B_total']
                end 
                prefix[sc_idx] + '_'+instrument+'_srvy_dmpa_bvec': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz']
                end
                prefix[sc_idx] + '_'+instrument+'_srvy_dmpa_btot': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [0]
                    options, /def, tplot_name, 'ytitle',  strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['B_total']
                end
                prefix[sc_idx] + '_'+instrument+'_srvy_gsm_dmpa': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument)
                    options, /def, tplot_name, 'labels', ['Bx', 'By', 'Bz', 'Btotal']
                end
                prefix[sc_idx] + '_'+instrument+'_srvy_omb': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument) + ' OMB'
                end 
                prefix[sc_idx] + '_'+instrument+'_srvy_bcs': begin
                    options, /def, tplot_name, 'labflag', 1
                    options, /def, tplot_name, 'colors', [2,4,6,8]
                    options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + ' ' + strupcase(instrument) + ' BCS'
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
    probes = strcompress(string(probes)) ; force the array to be an array of strings
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    if undefined(trange) then trange = ['2015-06-22/18:00', '2015-06-23']
    
    if undefined(level) then level = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = instrument, $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, tplotnames = tplotnames

    ; load the atttude data to do the coordinate transformation 
    mms_load_state, trange = trange, probes = probes, level = 'def', datatypes=['spinras', 'spindec']

    ; DMPA coordinates to GSE, for each probe
    for probe_idx = 0, n_elements(probes)-1 do begin
        this_probe = 'mms'+strcompress(string(probes[probe_idx]), /rem)
        ; make sure the attitude data has been loaded before doing the cotrans operation
        if tnames(this_probe+'_defatt_spinras') ne '' && tnames(this_probe+'_defatt_spindec') ne '' $
            && tnames(this_probe+'_'+instrument+'_srvy_dmpa') ne '' then begin
            dmpa2gse, this_probe+'_'+instrument+'_srvy_dmpa', this_probe+'_defatt_spinras', $
                this_probe+'_defatt_spindec', this_probe+'_'+instrument+'_srvy_gse'
            append_array, tplotnames, this_probe+'_'+instrument+'_srvy_gse'
            
            ; split the FGM data into 2 tplot variables, one containing the vector and one containing the magnitude
            mms_split_fgm_data, this_probe+'_'+instrument+'_srvy_dmpa', tplotnames = tplotnames
            mms_split_fgm_data, this_probe+'_'+instrument+'_srvy_gse', tplotnames = tplotnames
        endif
    endfor
    
    ; set some of the metadata for the DFG/AFG instruments
    mms_load_fix_metadata, tplotnames, prefix = 'mms' + probes, instrument = instrument

end