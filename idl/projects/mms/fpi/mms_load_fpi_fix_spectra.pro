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
;$LastChangedDate: 2015-12-23 09:07:16 -0800 (Wed, 23 Dec 2015) $
;$LastChangedRevision: 19653 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_fix_spectra.pro $
;-
pro mms_load_fpi_fix_spectra, tplotnames, probe = probe, level = level, data_rate = data_rate, datatype = datatype
    if undefined(datatype) then begin
        dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_fix_spectra'
        return
    endif
    if undefined(level) then begin
        dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_spectra'
        return
    endif
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    prefix = 'mms' + probe

    ; the following works because the FPI spectra datatypes are:
    ; QL: des, dis
    ; L1b: des-dist, dis-dist
    species_arr = strmid(datatype, 1, 1)
    
    for species_idx = 0, n_elements(species_arr)-1 do begin
        species = species_arr[species_idx]
        spec_regex = level eq 'ql' ? prefix + '_?'+species+'?_*nergySpectr_*' : prefix + '_fpi_'+species+'EnergySpectr_*'
        spectra_where = strmatch(tplotnames, spec_regex)

        if n_elements(spectra_where) ne 0 then begin
          for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
              get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
              if is_struct(fpi_d) then begin
                ; set some metadata before saving
                options, tplotnames[var_idx], ysubtitle='[eV]'
    
                ; get the direction from the variable name
                spec_pieces = strsplit(tplotnames[var_idx], '_', /extract)
                if level ne 'ql' then begin
                  ; assumption here: name of the variable is:
                  ; mms3_fpi_iEnergySpectr_pZ
                  part_direction = (spec_pieces)[n_elements(spec_pieces)-1]
                endif else begin
                  ; assumption here: name of the variable is:
                  ; mms3_dis_energySpectr_pZ
                  part_direction = (spec_pieces)[n_elements(spec_pieces)-1]
                endelse
                species_str = species eq 'e' ? 'electron' : 'ion'
    
                if data_rate ne 'brst' then fpi_energies = mms_fpi_energies(species) $
                else fpi_energies = mms_fpi_burst_energies(species, probe)
    
                options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+species_str+'!C'+part_direction
                options, tplotnames[var_idx], ysubtitle='[eV]'
                options, tplotnames[var_idx], ztitle='Counts'
                ylim, tplotnames[var_idx], 0, 0, 1
                zlim, tplotnames[var_idx], 0, 0, 1
    
                store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_energies}, dlimits=dl
              endif
            endif
          endfor
        endif
      
    endfor
end