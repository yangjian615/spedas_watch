;+
; Procedure:    
;         goes_lib
;         
; Purpose:
;         Provides an interface to various routines for postprocessing GOES data
;               
; Notes:
;         Most of these routines were provided by Juan Rodriguez, CIRES
;           with modifications by A. Kellerman
;   
;  
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-28 14:10:44 -0800 (Fri, 28 Feb 2014) $
; $LastChangedRevision: 14467 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_lib.pro $
;-

; Procedure: goes_pitch_angles
; Purpose: Uses magnetometer data to calculate the MAGED/MAGPD 
;          pitch angles for each of the 9 telescopes
; Input: 
;     H_values: required, tplot variable containing B-field values in ENP coordinates
;     Htotal: required, tplot variable containing B-field magnitude
; Output:
;     goes_pitch_angles: tplot variable containing pitch angle bins for the 9-telescope directions
pro goes_pitch_angles, H_values, Htotal, prefix = prefix, suffix = suffix
    compile_opt idl2
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    
    s35 = sin(35.0d0*!dtor)
    c35 = cos(35.0d0*!dtor)
    s70 = sin(70.0d0*!dtor)
    c70 = cos(70.0d0*!dtor)

    get_data, H_values, data=Hdata
    get_data, Htotal, data=Htstruct
    
    ; check that valid structs were returned
    if ~is_struct(Hdata) || ~is_struct(Htstruct) then begin
        dprint, dlevel = 1, 'Error calculating pitch angles, possibly due to invalid tplot variables.'
        return
    endif 
    
    Ht = Htstruct.Y[*]
    He = Hdata.Y[*,0]
    Hp = Hdata.Y[*,1]
    Hn = Hdata.Y[*,2]
    
    pitch_angles = fltarr(n_elements(Hn), 9)

    pitch_angles[*,0] = acos(He/Ht)*!radeg
    pitch_angles[*,1] = acos(( s35*Hn + c35*He)/Ht)*!radeg
    pitch_angles[*,2] = acos((-s70*Hn + c70*He)/Ht)*!radeg
    pitch_angles[*,3] = acos((-s35*Hn + c35*He)/Ht)*!radeg
    pitch_angles[*,4] = acos(( s70*Hn + c70*He)/Ht)*!radeg
    pitch_angles[*,5] = acos((-s35*Hp + c35*He)/Ht)*!radeg
    pitch_angles[*,6] = acos(( s70*Hp + c70*He)/Ht)*!radeg
    pitch_angles[*,7] = acos(( s35*Hp + c35*He)/Ht)*!radeg
    pitch_angles[*,8] = acos((-s70*Hp + c70*He)/Ht)*!radeg

    store_data, prefix + '_pitch_angles', data={x:Hdata.X, y:pitch_angles}
end
; Procedure: goes_remove_ifcs
;   
; Juan Rodriguez, CIRES, August 30, 2011
; Modified October 20, 2011, to also account for difference in number of points
; between Btsc and Ht
;
; IFCs are not removed by SWPC processing from the GOES 13-15 magnetic field 
; 1-minute averages in spacecraft coordinates (sc).
; However, they are removed from the PEN coordinates.
;
; Use fill values in ht_1 (from PEN coordinates) to filter out IFCs (and other issues,
; perhaps) in the sc-coordinate fields.  Also despikes data if ht > 512 nT.
pro goes_remove_ifcs, b_sc, Htotal, btsc_num_pts, ht_num_pts
    compile_opt idl2
    get_data, b_sc, data=b_sc_data, dlimits=b_sc_dlimits
    get_data, Htotal, data=Htotal_data, dlimits=Htotal_dlimits
    ; check that valid structs were returned
    if (~is_struct(b_sc_data) || ~is_struct(b_sc_dlimits) $
    || ~is_struct(Htotal_data) || ~is_struct(Htotal_dlimits)) then begin
        dprint, dlevel = 1, 'Error removing IFCs, possibly due to invalid tplot variables.'
        return
    endif 
    Ht_fillvalue = Htotal_dlimits.cdf.vatt.fillval
    
    ; find where Htotal equals the fill value
    ht_ifc = where(Htotal_data.Y eq Ht_fillvalue, htifc_count)
    if htifc_count gt 0 then begin
        newbscvar = b_sc_data.Y
        newbscvar[ht_ifc,0] = Ht_fillvalue
        newbscvar[ht_ifc,1] = Ht_fillvalue
        newbscvar[ht_ifc,2] = Ht_fillvalue
    endif 
    
    ; account for the difference in number of points between Btsc and Ht
    npdiff = where(btsc_num_pts ne ht_num_pts, numptscount)
    if numptscount gt 0 then begin
        if undefined(newbscvar) then begin
            newbscvar = b_sc_data.Y
            newhtvar = Htotal_data.Y
        endif 
        newbscvar[npdiff,0] = Ht_fillvalue
        newbscvar[npdiff,1] = Ht_fillvalue
        newbscvar[npdiff,2] = Ht_fillvalue
        newhtvar[npdiff] = Ht_fillvalue
    endif 
    
    ; despike data if Ht > 512 nT
    htspike = where(Htotal_data.Y gt 512.0, spikecount)
    if spikecount gt 0 then begin
        if undefined(newbscvar) then begin
            newbscvar = b_sc_data.Y
            newhtvar = Htotal_data.Y
        endif 
        newbscvar[npdiff,0] = Ht_fillvalue
        newbscvar[npdiff,1] = Ht_fillvalue
        newbscvar[npdiff,2] = Ht_fillvalue
        newhtvar[npdiff] = Ht_fillvalue
    endif 
    
    ; now store the data in a new tplot variable
    if ~undefined(newbscvar) then store_data, b_sc + '_ifcs_removed', data = {x: b_sc_data.X, y: newbscvar}, dlimits = b_sc_dlimits
    if ~undefined(newhtvar) then store_data, Htotal + '_ifcs_removed', data = {x: Htotal_data.X, y: newhtvar}, dlimits = Htotal_dlimits
end
; Procedure: goes_ht_quadrature
;
; Dec 9, 2011. Calculate total field from the quadrature sum of the components
; in spacecraft body reference frame.
pro goes_ht_quadrature, b_sc
    compile_opt idl2
    get_data, b_sc, data=b_sc_data, dlimits=b_sc_dlimits
    ; check that a valid struct was returned
    if ~is_struct(b_sc_data) || ~is_struct(b_sc_dlimits) then begin
        dprint, dlevel = 1, 'Error calculating total field from the quadrature sum of the components, possibly due to invalid tplot variables.'
        return
    endif
    ; get the default fill value
    bscfillvalue = b_sc_dlimits.cdf.vatt.fillval
    
    ; check where the components are equal to the fill value
    bscfill = where(b_sc_data.Y[*,0] eq bscfillvalue or b_sc_data.Y[*,1] eq bscfillvalue or b_sc_data.Y[*,2] eq bscfillvalue, fillcount)
    htcorr = sqrt((b_sc_data.Y[*,0])^2+(b_sc_data.Y[*,1])^2+(b_sc_data.Y[*,2])^2)
    if fillcount gt 0 then htcorr[bscfill] = bscfillvalue
    store_data, 'ht_corr_quad', data = {x: b_sc_data.X, y: htcorr}, dlimits = b_sc_dlimits
end

; Procedure: goes_epead_center_pitch_angles
; Purpose: 
; Input:
; Juan Rodriguez, CIRES, August 30, 2011
;
; Calculates EPEAD telescope pitch angles from GOES magnetic field in s/c coordinates
;
; Note that 'w' and 'e' here correspond to the EPEADs labelled respectively
; 'w' and 'e' in telemetry, and in the NGDC netCDF files, not necessarily to the 
; actual west and east look directions.
; EPEAD-West looks eastwards when the spacecraft is upright, and vice versa.
pro goes_epead_center_pitch_angles, Bsc, Bt
    compile_opt idl2
    get_data, Bsc, data = bsc_data, dlimits = bsc_dlimits
    get_data, Bt, data = bt_data, dlimits = bt_dlimits
    
    ; check that valid structs were returned
    if (~is_struct(bsc_data) || ~is_struct(bsc_dlimits) || ~is_struct(bt_data) || ~is_struct(bt_dlimits)) then begin
        dprint, dlevel = 1, 'Error calculating EPEAD center pitch angles, possibly due to invalid tplot variables.'
        return
    endif
    
    ; get the default fill value
    bscfillvalue = bsc_dlimits.cdf.vatt.fillval
    
    w_pitch_angle = acos(bsc_data.Y[*,0]/bt_data.Y)*!radeg
    e_pitch_angle = acos(-bsc_data.Y[*,0]/bt_data.Y)*!radeg
    
    ; check if the x component or the total is equal to the fill value
    bscfill = where(bsc_data.Y[*,0] eq bscfillvalue or bt_data.Y eq bscfillvalue, fillcount)
    
    if fillcount gt 0 then begin
        w_pitch_angle[bscfill] = bscfillvalue
        e_pitch_angle[bscfill] = bscfillvalue
    endif 
    newpad = fltarr(n_elements(w_pitch_angle), 2)
    newpad[*,0] = e_pitch_angle
    newpad[*,1] = w_pitch_angle
    
    ; update the attributes
    labels = ['E pitch angles', 'W pitch angles']
    str_element, bsc_dlimits, 'labels', labels, /add
    
    ; store the pitch angle information
    store_data, 'goes_epead_center_pitch_angles', data = {x:bsc_data.X, y:newpad}, dlimits = bsc_dlimits
end
; Procedure: goes_epead_contam_cor
; Purpose: 
;         Corrects 1-minute EPEAD E1 and E2 electron fluxes for proton contamination  
;         using uncorrected 1-minute EPEAD P3-P7 solar proton data.  Uses the same method
;         as used by the SWPC operational processing.
; 
; Input: 
;         e_uncor: 2-element array containing the names of tplot variables containing uncorrected flux from 
;         the first two electron channels, E1 and E2, corresponding to the (> 0.6 MeV) and (> 2 MeV) energy bands
;         p_uncor: 4-element array containing the names of tplot variables with uncorrected, 1-minute P3-P7 EPEAD data
;         
; Output:
;         Creates new tplot variable containing corrected fluxes (e1_cor, e2_cor) and the magnitude of the correction 
;         (de1, de2) in cm^-2 s^-1 sr^-1
; 
; Originally provided by Juan Rodriguez, CIRES, August 30, 2011

pro goes_epead_contam_cor, e_uncor, p_uncor
    compile_opt idl2
    ; Coefficients derived by Herb Sauer (1995) to convert the uncorrected solar proton
    ; fluxes in channels P3-P6 to the electron count rate correction in channels E1 & E2   
    e1coeff = [0.07, 1.40, 3.90, 30.0]
    e2coeff = [0.30, 9.00, 18.0, 96.0]
    
    ; Geometrical factors for E1 and E2 integral fluxes
    e1g = 0.75 ; E1 geometrical factor, cm^2 sr^1
    e2g = 0.05 ; E2 geometrical factor, cm^2 sr^1

    ; Define minimum flux to be reported
    mincr = 6.67e-3 ; minimum count rate, currently used in operational processing
    mine1flux = mincr/e1g ; convert minimum cr to minimum E1 flux
    mine2flux = mincr/e2g ; convert minimum cr to minimum E2 flux
    
    for e_uncor_idx = 0, n_elements(e_uncor)-1 do begin
        e_uncor_tname = e_uncor[e_uncor_idx]
        if e_uncor_idx eq 0 then begin
            get_data, e_uncor_tname, data=e_uncor_data, dlimits = e_uncor_dlimits
            
            ; check that valid structs were returned
            if ~is_struct(e_uncor_data) || ~is_struct(e_uncor_dlimits) then begin
                dprint, dlevel = 1, 'Error calculating EPEAD contamination corrections, possibly due to invalid tplot variables.'
                return
            endif
            
            newe_uncor_data = fltarr(e_uncor_data.Y, 2)
            newe_uncor_data[*,0] = e_uncor_data.Y
            ; we're going to need the fill value
            e_fillvalue = e_uncor_dlimits.cdf.vatt.fillval
        endif else begin
            get_data, e_uncor_tname, data=e_uncor_data, dlimits = e_uncor_dlimits
            
            ; check that valid structs were returned
            if ~is_struct(e_uncor_data) || ~is_struct(e_uncor_dlimits) then begin
                dprint, dlevel = 1, 'Error calculating EPEAD contamination corrections, possibly due to invalid tplot variables.'
                return
            endif
            
            newe_uncor_data[*,1] = e_uncor_data.Y
        endelse
    endfor
    
    for p_uncor_idx = 0, n_elements(p_uncor)-1 do begin
        p_uncor_tname = p_uncor[p_uncor_idx]
        if p_uncor_idx eq 0 then begin
            get_data, p_uncor_tname, data = p_uncor_data, dlimits = p_uncor_dlimits
            
            ; check that valid structs were returned
            if ~is_struct(p_uncor_data) || ~is_struct(p_uncor_dlimits) then begin
                dprint, dlevel = 1, 'Error calculating EPEAD contamination corrections, possibly due to invalid tplot variables.'
                return
            endif
            
            newp_uncor_data = fltarr(p_uncor_data.Y,4)
            newp_uncor_data[*,0] = p_uncor_data.Y
            ; we're going to need the fill value
            p_fillvalue = p_uncor_dlimits.cdf.vatt.fillval
        endif else begin
            get_data, p_uncor_tname, data = p_uncor_data, dlimits = p_uncor_dlimits
         
            ; check that valid structs were returned
            if ~is_struct(p_uncor_data) || ~is_struct(p_uncor_dlimits) then begin
                dprint, dlevel = 1, 'Error calculating EPEAD contamination corrections, possibly due to invalid tplot variables.'
                return
            endif
            
            newp_uncor_data[*,p_uncor_idx] = p_uncor_data.Y
        endelse
    endfor
    
    e1_fill = where(newe_uncor_data[*,0] eq e_fillvalue or newp_uncor_data[*,0] eq p_fillvalue or newp_uncor_data[*,1] $
        eq p_fillvalue or newp_uncor_data[*,2] eq p_fillvalue or newp_uncor_data[*,3] eq p_fillvalue, e1fillcount)
    e2_fill = where(newe_uncor_data[*,1] eq e_fillvalue or newp_uncor_data[*,0] eq p_fillvalue or newp_uncor_data[*,1] $
        eq p_fillvalue or newp_uncor_data[*,2] eq p_fillvalue or newp_uncor_data[*,3] eq p_fillvalue, e2fillcount)

    ; count rate corrections, convert to integral flux
    de1 = (e1coeff[0]*newp_uncor_data[*,0] + e1coeff[1]*newp_uncor_data[*,1] + e1coeff[2]*newp_uncor_data[*,2] + $
            e1coeff[3]*newp_uncor_data[*,3])/e1g
    de2 = (e2coeff[0]*newp_uncor_data[*,0] + e2coeff[1]*newp_uncor_data[*,1] + e2coeff[2]*newp_uncor_data[*,2] + $
            e2coeff[3]*newp_uncor_data[*,3])/e2g
    
    ; subtract this from the uncorrected integral flux
    e1_cor = newe_uncor_data[*,0] - de1
    e2_cor = newe_uncor_data[*,1] - de2
    
    ; replace fluxes less than minimum flux with minimum flux values
    e1low = where(e1_cor lt mine1flux, e1lowcount)
    e2low = where(e2_cor lt mine2flux, e2lowcount)
    if e1lowcount gt 0 then e1_cor[e1low] = mine1flux
    if e2lowcount gt 0 then e2_cor[e2low] = mine2flux
    
    ; replace fluxes with fill value if uncorrected flux or the protons fluxes used to correct are fill values
    if e1fillcount gt 0 then e1_cor[e1_fill] = e_fillvalue
    if e2fillcount gt 0 then e2_cor[e2_fill] = e_fillvalue
    
    ; store the corrected fluxes
    store_data, 'e1_cor', data = e1_cor, dlimits = e_uncor_dlimits
    store_data, 'e2_cor', data = e2_cor, dlimits = e_uncor_dlimits
end
; Procedure: goes_part_omni_flux
; 
; Purpose: 
;     Creates a tplot variable containing the MAGED or MAGPD omni-directional flux 
; 
; Input:
;     particle_tvar - MAGED or MAGPD tplot variable
;  
; Output: 
;     Tplot variable containing the MAGED or MAGPD omni-directional flux 
;     with '_omni' appended to the name
; 
; Based on A. Kellerman's get_goes_magpd implementation of the 
; GOES MAGED/MAGPD omni-directional flux calculations. To calculate 
; omni-directional fluxes: 
;     9 telescopes, 30-degree full cone angle each
;     solid angle is 2*pi(1-cos(15*pi/180)) for each cone
pro goes_part_omni_flux, particle_tvar
    get_data, particle_tvar, data=particle_data, dlimits=particle_dlimits
    
    if ~is_struct(particle_data) || ~is_struct(particle_dlimits) then begin
        dprint, dlevel = 1, 'Error calculating omni-directional flux, possibly due to an invalid tplot variable'
        return
    endif
    frac_total_sa = 18.*!pi*(1-cos(15*!dtor))/(4*!pi) ;for all 9 telescopes, sr
    omni_flux = total(particle_data.Y, 2, /double)/frac_total_sa
    store_data, particle_tvar+'_omni', data={x: particle_data.X, y: omni_flux}, dlimits=particle_dlimits
end
; Procedure:
;     goes_maged_omni_flux
;     
; Purpose:
;     Calculates the omni-directional electron flux for each energy channel 
;     and combines the data into a single tplot variable
pro goes_maged_omni_flux, prefix, suffix
    
    ; energy channels for the MAGED instrument, from the GOES-N databook
    energies = fltarr(5,2)
    energies[0,0] = 30.
    energies[0,1] = 50.
    energies[1,0] = 50.
    energies[1,1] = 100.
    energies[2,0] = 100.
    energies[2,1] = 200.
    energies[3,0] = 200.
    energies[3,1] = 350.
    energies[4,0] = 350.
    energies[4,1] = 600.
 
    centered_energies = intarr(5)
    tvar_names = strarr(5)
    for i = 0, 4 do begin
        ; center energy channels
        centered_energies[i] = round((energies[i,1]-energies[i,0])/2.+energies[i,0])
        maged_tvar = prefix + '_maged_'+strcompress(string(centered_energies[i]), /rem)+'keV_dtc_cor_flux'+suffix
        goes_part_omni_flux, maged_tvar
        tvar_names[i] = maged_tvar+'_omni'
    endfor
    join_vec, tvar_names, prefix + '_maged_dtc_cor_omni_flux'+suffix
    
    ; update the plotting options
    options, /def, prefix + '_maged_dtc_cor_omni_flux'+suffix, 'ylog', 1
    options, /def, prefix + '_maged_dtc_cor_omni_flux'+suffix, 'labflag', 1
    options, /def, prefix + '_maged_dtc_cor_omni_flux'+suffix, 'labels', strcompress(string(centered_energies)+' keV', /rem)
    options, /def, prefix + '_maged_dtc_cor_omni_flux'+suffix, 'ytitle', 'Electrons!C [e/(cm!U2!N-s-sr-keV)]'
    options, /def, prefix + '_maged_dtc_cor_omni_flux'+suffix, 'ysubtitle', ''
end
; Procedure: goes_magpd_omni_flux
; 
; Purpose:
;     Calculates the omni-directional electron flux for each energy channel 
;     and combines the data into a single tplot variable
pro goes_magpd_omni_flux, prefix, suffix

    ; energies for the MAGPD instrument, from the GOES-N databook
    energies = fltarr(5,2)
    ; keV
    energies[0,0] = 80.
    energies[0,1] = 110.
    energies[1,0] = 110.
    energies[1,1] = 170.
    energies[2,0] = 170.
    energies[2,1] = 250.
    energies[3,0] = 250.
    energies[3,1] = 350.
    energies[4,0] = 350.
    energies[4,1] = 800.
 
    centered_energies = intarr(5)
    tvar_names = strarr(5)
    for i = 0, 4 do begin
        ; center energy channels
        centered_energies[i] = round((energies[i,1]-energies[i,0])/2.+energies[i,0])
        magpd_tvar = prefix + '_magpd_'+strcompress(string(centered_energies[i]), /rem)+'keV_dtc_cor_flux'+suffix
        goes_part_omni_flux, magpd_tvar
        tvar_names[i] = magpd_tvar+'_omni'
    endfor
    join_vec, tvar_names, prefix + '_magpd_dtc_cor_omni_flux'+suffix
    
    ; update the plotting options
    options, /def, prefix + '_magpd_dtc_cor_omni_flux'+suffix, 'ylog', 1
    options, /def, prefix + '_magpd_dtc_cor_omni_flux'+suffix, 'labels', strcompress(string(centered_energies)+' keV', /rem)
    options, /def, prefix + '_magpd_dtc_cor_omni_flux'+suffix, 'labflag', 1
    options, /def, prefix + '_magpd_dtc_cor_omni_flux'+suffix, 'ytitle', 'Protons!C [p/(cm!U2!N-s-sr-keV)]'
    options, /def, prefix + '_magpd_dtc_cor_omni_flux'+suffix, 'ysubtitle', ''
end
; Procedure: goes_epead_comb_electron_flux
;
; Purpose: 
;    Combines the EPEAD electron flux data into a single tplot variable
;
pro goes_epead_comb_electron_flux, prefix, suffix
    energies = strarr(3)
    tvarnames = strarr(3)
    ; MeV
    energies[0] = '0.6'
    energies[1] = '2'
    energies[2] = '4'

    for i = 0, 2 do begin
        get_data, prefix+'_elec_'+energies[i]+'MeV_uncor_flux'+suffix, data=elec_data, dlimits=elec_dlimits
        if (is_struct(elec_data) && is_struct(elec_dlimits)) then begin
            total_values = (elec_data.Y[*,0]+elec_data.Y[*,1])/2.
            store_data, prefix+'_elec_'+energies[i]+'MeV_uncor_flux_comb'+suffix, data={x: elec_data.X, y: total_values}, dlimits=elec_dlimits
            tvarnames[i] = prefix+'_elec_'+energies[i]+'MeV_uncor_flux_comb'+suffix
        endif else begin
            dprint, dlevel = 1, 'Error combining EPEAD electron flux - no valid data?'
            return
        endelse
    endfor
    join_vec, tvarnames, prefix+'_elec_uncor_comb_flux'+suffix
    
    options, /def, prefix+'_elec_uncor_comb_flux'+suffix, 'ylog', 1
    options, /def, prefix+'_elec_uncor_comb_flux'+suffix, 'labflag', 1
    options, /def, prefix+'_elec_uncor_comb_flux'+suffix, 'ytitle', 'Electrons!C [e/(cm!U2!N-s-sr)]'
    options, /def, prefix+'_elec_uncor_comb_flux'+suffix, 'labels', energies+' MeV'
    options, /def, prefix+'_elec_uncor_comb_flux'+suffix, 'ysubtitle', ''
end
; Procedure: goes_eps_comb_proton_flux
;
; Purpose:
;     Combines the EPS proton flux into two tplot variables, 
;     one for the telescope data and one for the dome data
;
pro goes_eps_comb_proton_flux, prefix, suffix
    telescope_energies = strarr(3)
    dome_energies = strarr(4)
    ; MeV
    telescope_energies[0] = '2.4'
    telescope_energies[1] = '6.5'
    telescope_energies[2] = '12'
    dome_energies[0] = '27.5'
    dome_energies[1] = '60'
    dome_energies[2] = '122.5'
    dome_energies[3] = '332.5'
    
    join_vec, prefix+'_prot_'+telescope_energies+'MeV_flux'+suffix, prefix+'_eps_tele_protons'+suffix
    join_vec, prefix+'_prot_'+dome_energies+'MeV_flux'+suffix, prefix+'_eps_dome_protons'+suffix
    options, /def, prefix+'_eps_dome_protons'+suffix, 'ylog', 1
    options, /def, prefix+'_eps_dome_protons'+suffix, 'ytitle', 'Protons!C [p/(cm!U2!N-s-sr-MeV)]'
    options, /def, prefix+'_eps_dome_protons'+suffix, 'labels', dome_energies+' MeV'
    options, /def, prefix+'_eps_dome_protons'+suffix, 'labflag', 1
    options, /def, prefix+'_eps_dome_protons'+suffix, 'ysubtitle', ''
    
    
    options, /def, prefix+'_eps_tele_protons'+suffix, 'ylog', 1
    options, /def, prefix+'_eps_tele_protons'+suffix, 'ytitle', 'Protons!C [p/(cm!U2!N-s-sr-MeV)]'
    options, /def, prefix+'_eps_tele_protons'+suffix, 'labels', telescope_energies+' MeV'
    options, /def, prefix+'_eps_tele_protons'+suffix, 'labflag', 1
    options, /def, prefix+'_eps_tele_protons'+suffix, 'ysubtitle', ''
end
; Procedure: goes_eps_comb_elec_flux
;
; Purpose:
;     Combines the EPS integral electron flux into a single tplot variable
;
pro goes_eps_comb_electron_flux, prefix, suffix
    dome_energies = strarr(3)
    dome_energies[0] = '0.6'
    dome_energies[1] = '2.0' 
    dome_energies[2] = '4.0'
    
    ; 
    join_vec, prefix+'_elec_'+dome_energies+'MeV_iflux'+suffix, prefix+'_eps_dome_electrons'+suffix
    options, /def, prefix+'_eps_dome_electrons'+suffix, 'ylog', 1
    options, /def, prefix+'_eps_dome_electrons'+suffix, 'labels', dome_energies+' MeV'
    options, /def, prefix+'_eps_dome_electrons'+suffix, 'ytitle', 'Electrons!C [e/(cm!U2!N-s-sr)]'
    options, /def, prefix+'_eps_dome_electrons'+suffix, 'labflag', 1
    options, /def, prefix+'_eps_dome_electrons'+suffix, 'ysubtitle', ''
end
; Procedure: goes_epead_comb_proton_flux
;
; Purpose: 
;    Combines the EPEAD proton flux data into a single tplot variable
;
pro goes_epead_comb_proton_flux, prefix, suffix
    energies = strarr(7)
    tvarnames = strarr(7)
    ; MeV
    energies[0] = '2.5'
    energies[1] = '6.5'
    energies[2] = '11.6'
    energies[3] = '30.6'
    energies[4] = '63.1'
    energies[5] = '165'
    energies[6] = '433'
    for i = 0, 6 do begin
        get_data, prefix+'_prot_'+energies[i]+'MeV_uncor_flux'+suffix, data=prot_data, dlimits=prot_dlimits
        if (is_struct(prot_data) && is_struct(prot_dlimits)) then begin
            total_values = (prot_data.Y[*,0]+prot_data.Y[*,1])/2.
            store_data, prefix+'_prot_'+energies[i]+'MeV_uncor_flux_comb'+suffix, data={x: prot_data.X, y: total_values}, dlimits=prot_dlimits
            tvarnames[i] = prefix+'_prot_'+energies[i]+'MeV_uncor_flux_comb'+suffix
        endif else begin
            dprint, dlevel = 1, 'Error combining the EPEAD proton flux - no valid data?'
            return
        endelse
    endfor
    join_vec, tvarnames, prefix+'_prot_uncor_comb_flux'+suffix
    
    ; update the plotting options
    options, /def, prefix+'_prot_uncor_comb_flux'+suffix, 'ylog', 1
    options, /def, prefix+'_prot_uncor_comb_flux'+suffix, 'labels', energies+' MeV'
    options, /def, prefix+'_prot_uncor_comb_flux'+suffix, 'labflag', 1
    options, /def, prefix+'_prot_uncor_comb_flux'+suffix, 'ytitle', 'Protons!C [p/(cm!U2!N-s-sr-keV)]'
    options, /def, prefix+'_prot_uncor_comb_flux'+suffix, 'ysubtitle', ''
end

pro goes_lib
    ; does nothing
end