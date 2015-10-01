;+
; PROCEDURE:
;         mms_load_hpca
;         
; PURPOSE:
;         Load data from the MMS Hot Plasma Composition Analyzer (HPCA)
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         local_data_dir: local directory to store the CDF files
;         varformat: format of the variable names in the CDF to load
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
;$LastChangedDate: 2015-09-30 15:41:40 -0700 (Wed, 30 Sep 2015) $
;$LastChangedRevision: 18975 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_hpca.pro $
;-

pro mms_load_hpca, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, varformat = varformat, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update
                

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'ion'
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(varformat) then begin
       ; allow for the following datatypes:
       ; count_rate, flux, vel_dist, rf_corr, bkgd_corr
       case datatype of 
            'ion': varformat = '*_RF_corrected'
            'rf_corr': varformat = '*_RF_corrected'
            'count_rate': varformat = '*_count_rate'
            'flux': varformat = '*_flux'
            'vel_dist': varformat = '*_vel_dist_fn'
            'bkgd_corr': varformat = '*_bkgd_corrected'
            'moments': varformat = '*'
            else: varformat = '*_RF_corrected'
       endcase
       if ~undefined(varformat) && varformat ne '*' then datatype = 'ion'
       
    endif
    ;if level eq 'sitl' then varformat = '*'
    
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'hpca', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, varformat = varformat, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update
    
    if undefined(tplotnames) then return
    
    ; if the user requested HPCA ion data, need to:
    ; 1) sum over anodes for normalized counts, count rate, 
    ;    RF and background corrected count rates
    ; 2) average over anodes for flux, velocity distributions
    ;if datatype eq 'ion' then mms_hpca_calc_anodes, tplotnames=tplotnames, fov=fov, probes=probes

    for probe_idx = 0, n_elements(probes)-1 do mms_hpca_set_metadata, tplotnames, prefix = 'mms'+probes[probe_idx]
end