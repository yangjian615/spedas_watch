;+
; PROCEDURE:
;         mms_fpi_burst_energies
;
; PURPOSE:
;         Returns the energies for burst mode FPI spectra.  This routine uses 
;            the alternating energy tables set by the parity bit
;
; NOTE:
;         Burst mode FPI data must be loaded prior to calling this function
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-22 11:26:48 -0800 (Tue, 22 Dec 2015) $
;$LastChangedRevision: 19646 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_burst_energies.pro $
;-
function mms_fpi_burst_energies, species, probe
  if undefined(probe) then begin
    dprint, dlevel = 'Error, need probe to find burst mode energies'
    return, 0
  endif else probe = strcompress(string(probe), /rem)
  if undefined(species) then begin
    dprint, dlevel = 'Error, need species to find burst mode energies'
    return, 0
  endif else species = strcompress(string(species), /rem)

  en_table = mms_get_fpi_info()

  ; get the step table
  step_name = (tnames('mms'+probe+'_d'+species+'s_stepTable_parity'))[0]
  if step_name eq '' then begin
    dprint, 'Cannot find energy table data: mms'+probe+'_d'+species+'s_stepTable_parity'
    return, 0
  endif
  get_data, step_name, data=step

  if species eq 'i' then energy_table = transpose(en_table.ion_energy) $
  else if species eq 'e' then energy_table = transpose(en_table.electron_energy)

  en_out = transpose(energy_table[*,step.y])
  return, en_out
end