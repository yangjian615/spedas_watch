;+
; PROCEDURE:
;         mms_load_fpi_fix_spectra
;
; PURPOSE:
;         Helper routine for setting the hard coded energies in the FPI load routine
;
; NOTE:
;         Expect this routine to be made obsolete after adding the energies to the CDF
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-11-25 11:46:26 -0800 (Wed, 25 Nov 2015) $
;$LastChangedRevision: 19478 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fpi_fix_spectra.pro $
;-
pro mms_load_fpi_fix_spectra, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = 'mms1'

    spectra_where = strmatch(tplotnames, prefix + '_???_*nergySpectr_*')

    if n_elements(spectra_where) ne 0 then begin
        for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
                get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                if is_struct(fpi_d) then begin
                    ; set some metadata before saving
                    options, tplotnames[var_idx], ysubtitle='[keV]'

                    ; get the direction and species from the variable name
                    spec_pieces = strsplit(tplotnames[var_idx], '_', /extract)
                    part_direction = (spec_pieces)[n_elements(spec_pieces)-1]
                    species = strmid(spec_pieces[2], 0, 1)
                    species = species eq 'e' ? 'electron' : 'ion'
                    fpi_energies = mms_fpi_energies(species)

                    options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+species+'!C'+part_direction
                    options, tplotnames[var_idx], ysubtitle='[keV]'
                    options, tplotnames[var_idx], ztitle='Counts'
                    ylim, tplotnames[var_idx], 0, 0, 1
                    zlim, tplotnames[var_idx], 0, 0, 1

                    store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_energies}, dlimits=dl
                endif
            endif
        endfor
    endif
end