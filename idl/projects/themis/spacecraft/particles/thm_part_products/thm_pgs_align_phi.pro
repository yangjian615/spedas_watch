;+
;Procedure:
;  thm_pgs_align_phi
;
;Purpose:
;  Align phi bins with respect to energy in order to reduce 
;  fringing artifacts on field aligned spectrograms.
;
;
;Input:
;  data: single sanitized data structure
;  
;
;Output:
;  -Phi values in DATA will be averaged across energy.
;  -If the inter-energy phi difference is too large for an
;   accurate average over energy then an error will be thrown.
;   (Hopefully this will never happen, if it does a more
;    sofisticated algorithm will be needed)
;  
;
;Notes:
;  -sigh
;   
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-12-18 18:39:35 -0800 (Wed, 18 Dec 2013) $
;$LastChangedRevision: 13708 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_align_phi.pro $
;-

pro thm_pgs_align_phi, data

    compile_opt idl2, hidden


  ;number of energies
  enum = dimen1(data.phi)

  ;average phi over energy
  phi_ave = total(data.phi,1)/enum
  phi_ave = phi_ave ## replicate(1,enum)
  
  ;For now we will warn if the phi difference between
  ;energies is too large.  If it is the phi values at 
  ;particular energies and thetas will need to be rotated.
  if total( abs(phi_ave-data.phi) gt 0.5*data.dphi ) gt 0 then begin
  
    message, 'Difference in phi values between energies is too large '+ $
             'to allow accurate averaging.
  
  endif else begin
  
    data.phi = phi_ave
  
  endelse
  
  
end