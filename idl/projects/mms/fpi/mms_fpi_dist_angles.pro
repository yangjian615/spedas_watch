;+
; PROCEDURE:
;         mms_fpi_dist_angles
;
; PURPOSE:
;         Returns the azimuth/elevation for FPI distributions.
;
; NOTE:
;         Azimuth/elevation should be fetched together because of differences in  
;         convention between the tables in mms_get_fpi_info and the supplementary vars.
;         This routine might be obsolete once the angles are added to the data CDFs.
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-29 13:56:07 -0700 (Mon, 29 Aug 2016) $
;$LastChangedRevision: 21766 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_dist_angles.pro $
;-

pro mms_fpi_dist_angles, probe=probe, level=level, data_rate=data_rate, species=species, $
                         suffix=suffix, phi=phi, theta=theta

    compile_opt idl2, hidden


  ;ensure output is correct or undefined
  undefine, phi, theta
  
  ;probe/level/rate/species should already be defined & filtered
  if undefined(suffix) then suffix = ''

  ;no supplementary variables for l1 data
  if level ne 'l2' then begin
    info = mms_get_fpi_info()
    phi = info.azimuth
    theta = 90 - info.elevation ;expected to be in colatitude
    return
  endif

  ;get l2 angles
  get_data, 'mms'+probe+'_d'+species+'s_phi_'+data_rate+suffix, ptr=phi_ptr
  get_data, 'mms'+probe+'_d'+species+'s_theta_'+data_rate+suffix, ptr=theta_ptr

  if ~is_struct(phi_ptr) || ~is_struct(theta_ptr) then begin
    dprint, dlevel=0, 'Cannot find tplot variables containing azimuth/elevation data'
    return
  endif

  ;azimuths appear off by 180° compared to hard coded table and moments/phi spec output
  phi = (*phi_ptr.y + 180.) mod 360

  ;elevations appear to be in reverse order
  ; (i.e. 0th element corresponds to element N-1 along corresponding data dimension)
  theta = reverse( *theta_ptr.y, size( *theta_ptr.y, /n_dim) ) 

end