;+
; PROCEDURE:
;         mms_hpca_spin_sum
;
; PURPOSE:
;         Calculates spin-summed fluxes for the HPCA instrument
;
; KEYWORDS:
;
; OUTPUT:
;
;
; NOTES:
;     Must have support data loaded with mms_load_hpca, /get_support_data
;        tplot variable required is: mms#_hpca_start_azimuth
;     Still under developement, egrimes, 1/29/2016
;     
;     
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-29 15:31:07 -0800 (Fri, 29 Jan 2016) $
;$LastChangedRevision: 19854 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_spin_sum.pro $
;-

pro mms_hpca_spin_sum, probe = probe, varname
    if undefined(probe) then begin
        dprint, dlevel = 0, 'Error, must provide probe # to spin-sum the HPCA data'
        return
    endif else begin
        probe = strcompress(string(probe), /rem)
    endelse
    
    get_data, 'mms'+probe+'_hpca_start_azimuth', data=start_az
    
    if ~is_struct(start_az) then begin
        dprint, dlevel = 0, 'Error, couldn''t find the variable containing the start azimuth'
        return
    endif
    spin_starts = where(start_az.Y eq 0, count_starts)
    
    if count_starts eq 0 then begin
        dprint, dlevel = 0, 'Error, couldn''t identify spin starts from start_azimuth tplot variable'
        return
    endif

    get_data, varname, data=hpca_data
    
    if ~is_struct(hpca_data) then begin
        dprint, dlevel = 0, 'Error, couldn''t load data from the variable: ' + varname
        return
    endif
    
    spin_summed = dblarr(n_elements(spin_starts), n_elements(hpca_data.Y[0, *]))
    
    for spin_idx = 0, n_elements(spin_starts)-2 do begin
        spin_summed[spin_idx, *] = total(hpca_data.Y[spin_starts[spin_idx]:spin_starts[spin_idx+1]-1,*], 1, /nan, /double)
    endfor
    
    new_varname = varname+'_spin'
    
    store_data, new_varname, data={x: start_az.X[spin_starts], y: spin_summed, v: hpca_data.V}
    options, new_varname, spec=1
    ylim, new_varname, 0, 0, 1
    zlim, new_varname, 0, 0, 1
end
