;+
; PROCEDURE:
;         mms_load_fpi_fix_angles
;
; PURPOSE:
;         Helper routine for setting the hard coded angles in the FPI load routine
;
; NOTE:
;         Expect this routine to be made obsolete after adding the angles to the CDF
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-11-25 11:46:26 -0800 (Wed, 25 Nov 2015) $
;$LastChangedRevision: 19478 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fpi_fix_angles.pro $
;-
pro mms_load_fpi_fix_angles, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = 'mms1'
    fpi_angles = mms_fpi_angles()

    spectra_where = strmatch(tplotnames, prefix + '_???_*itchAngDist_*En')

    if n_elements(spectra_where) ne 0 then begin
        for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
                get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                if is_struct(fpi_d) then begin
                    ; set some metadata before saving
                    en = strsplit(tplotnames[var_idx], '_', /extract)
                    en = en[n_elements(strsplit(tplotnames[var_idx], '_', /extract))-1]
                    options, tplotnames[var_idx], ysubtitle='[deg]'
                    options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+en+'!CPAD'
                    options, tplotnames[var_idx], ztitle='Counts'
                    zlim, tplotnames[var_idx], 0, 0, 1
                    store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_angles}, dlimits=dl
                endif
            endif
        endfor
    endif
end