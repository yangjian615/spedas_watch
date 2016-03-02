;+
; PROCEDURE:
;         mms_load_fpi_fix_dist
;
; PURPOSE:
;         Helper routine for setting the hard coded energies in the FPI load routine
;         This will swap the indices stored in the skymap v1 field for the actual
;         energy values.
;
; NOTE:
;         Expect this routine to be made obsolete after adding the energies to the CDF
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-01 16:45:13 -0800 (Tue, 01 Mar 2016) $
;$LastChangedRevision: 20280 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_fix_dist.pro $
;-
pro mms_load_fpi_fix_dist, tplotnames, probe = probe, level = level, data_rate = data_rate, $
                           datatype = datatype, suffix = suffix

  if undefined(suffix) then suffix = ''
  if undefined(datatype) then begin
      dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_fix_dist'
      return
  endif
  if undefined(level) then begin
      dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_dist'
      return
  endif
  if undefined(level) then begin
      dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_dist'
      return
  endif

  prefix = 'mms' + strcompress(string(probe), /rem)
  
  regex = level eq 'l2' ? prefix+'_d([ei])s_dist_'+data_rate+suffix : $
                          prefix+'_d([ei])s_.*SkyMap_dist'+suffix
  
  idx = where( stregex(tplotnames,regex,/bool), n)
  if n eq 0 then return

  species = (stregex(tplotnames,regex,/subex,/extract))[1,*]

  for i=0, n-1 do begin

    ;avoid unnecessary copies
    get_data, tplotnames[idx[i]], ptr=data

    if ~is_struct(data) then continue

    ;attempt to only do this once
    if n_elements(*data.v1) gt 32 then continue 

    ;load before loop if this needs to be done more than once or twice (it shouldn't)
    if data_rate eq 'brst' then begin
      energies = mms_fpi_burst_energies(species[idx[i]], probe, level=level, suffix=suffix)
    endif else begin
      energies = mms_fpi_energies(species[idx[i]], probe=probe, level=level, suffix=suffix)
    endelse
    
    if n_elements(energies) le 1 then continue

    ;replace field with energies
    *data.v1 = energies

  endfor  

end