;+
; NAME: mvn_euv_ionization
; SYNTAX: 
;       structure = mvn_euv_ionization(fismdata)
;       
; PURPOSE:
;       calculates ionization frequencies for six major species in the
;       Martian atmosphere
;
; ARGUMENTS:
;     fismdata is the structure produced when the procedure
;     get_data.pro is used To retrieve data from the tplot variable
;     'mvn_euv_l3_y'
;
; RETURNS:
;     a data structure containing ionization frequencies of the six
;     major species: CO2, O2, O, CO, N2, Ar according to the
;         photoionization cross-sections from the SwRI database:
;         http://phidrates.space.swri.edu/ 

; need a really simple integrator, should work the same way as
; int_tabulated
function int_simple, x, f, df = df, dx = dx, error= error
  nx = n_elements (x)
  deltax = x [1:*] -x [0: nx -2]
  area =  deltax*0.5*(f [1:*] +f [0: nx -2])
  
  if keyword_set (df) or keyword_set (dx) then begin
     if not keyword_set (df) then df = fltarr(nx)
     if not keyword_set (dx) then dx = fltarr(nx)

     integral = 0
     error = 0.0
     for K = 1, nx-1 do begin
        fterm = 0.5*(f[k-1] + f[k])
        xterm = x[k] - x[k-1]
        ferr = 0.5*sqrt(df[k-1]^2 + df[k]^2)
        xerr = sqrt(dx[k-1]^2 + dx[k]^2)
        z = xterm*fterm
        zerr = abs(z)*sqrt((xerr/xterm)^2 + (ferr/fterm)^2)
        integral = integral + z
        error = sqrt(error^2.0 + zerr^2)
     endfor
     return, integral
  endif else return,  total (area,/nan)
end


function mvn_euv_ionization,fismdata
  wavelength = reform(fismdata.v[0,*])
  path = FILE_DIRNAME(ROUTINE_FILEPATH('mvn_euv_l3_load'), /mark)
  Cross_section_file = path + 'photon_cross_sections.sav'
  
                                ;print, 'Loading cross-section file...'
  restore, cross_section_file
                                ;print, 'Done.'
  
  CO2_ionization_process_index1 = where(photo.CO2.process eq 'CO2 CO2+')
  CO2_ionization_process_index2 = where(photo.CO2.process eq 'CO2 CO+O')
  CO2_ionization_process_index3 = where(photo.CO2.process eq 'CO2 O+CO')
  CO2_ionization_process_index4 = where(photo.CO2.process eq 'CO2 C+O2')
  CO2_ionization_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_ionization_process_index1,*]+ $
                      photo.CO2.xsection[CO2_ionization_process_index2,*]+ $
                      photo.CO2.xsection[CO2_ionization_process_index3,*]+ $
                      photo.CO2.xsection[CO2_ionization_process_index4,*],$
                      photo.Angstroms*0.1, $
                      wavelength))
  
  O_ionization_process_index = where(photo.O3P.process eq 'O3P O+')
  O_ionization_xsection = $
     reform (interpol(photo.O3P.xsection[O_ionization_process_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  AR_ionization_process_index = where(photo.AR.process eq 'Ar Ar+')
  AR_ionization_xsection = $
     reform (interpol(photo.AR.xsection[AR_ionization_process_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  O2_ionization_process_index1 = where(photo.O3P.process eq 'O2 O2+')
  O2_ionization_process_index2 = where(photo.O3P.process eq 'O2 O+O')
  O2_ionization_xsection = $
     reform (interpol(photo.O2.xsection[O2_ionization_process_index1,*]+$
                      photo.O2.xsection[O2_ionization_process_index2,*],$
                      photo.Angstroms*0.1, $
                      wavelength))
  
  N2_ionization_process_index1 = where(photo.O3P.process eq 'N2 N2+')
  N2_ionization_process_index2 = where(photo.O3P.process eq 'N2 N+N')
  N2_ionization_xsection = reform (interpol(photo.N2.xsection[N2_ionization_process_index1,*]+$
                                            photo.N2.xsection[N2_ionization_process_index2,*],$
                                            photo.Angstroms*0.1, $
                                            wavelength))
  
  CO_ionization_process_index1 = where(photo.O3P.process eq 'CO CO+')
  CO_ionization_process_index2 = where(photo.O3P.process eq 'CO O+C')
  CO_ionization_process_index3 = where(photo.O3P.process eq 'CO C+O')
  CO_ionization_xsection = reform (interpol(photo.CO.xsection[CO_ionization_process_index1,*]+$
                                            photo.CO.xsection[CO_ionization_process_index2,*]+$
                                            photo.CO.xsection[CO_ionization_process_index3,*],$
                                            photo.Angstroms*0.1, $
                                            wavelength))
  
  ntimes = n_elements (fismdata.x)
  ionization_frequency_CO2 = fltarr(ntimes)
  ionization_frequency_CO = fltarr(ntimes)
  ionization_frequency_O = fltarr(ntimes)
  ionization_frequency_O2 = fltarr(ntimes)
  ionization_frequency_N2 = fltarr(ntimes)
  ionization_frequency_Ar = fltarr(ntimes)

  plank_constant = 6.6d-34      ; standard units
  speed_light = 2.99D8          ; standard units
  
  
  print, 'Calculating ionization frequencies...'
  
  for K = 0, nTIMES-1 do begin 
; photons per square centimeter per second
     photon_flux = 1e-4*reform (FISMDATA.y[k,*])*(1e-9*wavelength)/$
                   (plank_constant*speed_light)
; ionizations per second per nm
     diff_ionization_frequency_CO2 = CO2_ionization_xsection*photon_flux 
     diff_ionization_frequency_CO = CO_ionization_xsection*photon_flux 
     diff_ionization_frequency_O2 = O2_ionization_xsection*photon_flux 
     diff_ionization_frequency_N2 = N2_ionization_xsection*photon_flux 
     diff_ionization_frequency_O = O_ionization_xsection*photon_flux 
     diff_ionization_frequency_Ar = Ar_ionization_xsection*photon_flux 
; total radiance over the appropriate wavelength range
     ionization_frequency_CO2[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_CO2)
     ionization_frequency_CO[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_CO)
     ionization_frequency_O2[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_O2)
     ionization_frequency_N2[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_N2)
     ionization_frequency_O[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_O)
     ionization_frequency_Ar[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_Ar)
  endfor 
  print, 'Done'
  store_data, 'ionization_frequency_CO2', Data = {x:fismdata.x, y:ionization_frequency_CO2},$
              dlimits={ytitle:'CO2 Ionization !c Frequency, #/s'}
  store_data, 'ionization_frequency_CO', Data = {x:fismdata.x, y:ionization_frequency_CO},$
              dlimits={ytitle:'CO Ionization !c Frequency, #/s'}
  store_data, 'ionization_frequency_O2', Data = {x:fismdata.x, y:ionization_frequency_O2},$
              dlimits={ytitle:'O2 Ionization !c Frequency, #/s'}
  store_data, 'ionization_frequency_N2', Data = {x:fismdata.x, y:ionization_frequency_N2},$
              dlimits={ytitle:'N2 Ionization !c Frequency, #/s'}
  store_data, 'ionization_frequency_O', Data = {x:fismdata.x, y:ionization_frequency_O},$
              dlimits={ytitle:'O Ionization !c Frequency, #/s'}
  store_data, 'ionization_frequency_Ar', Data = {x:fismdata.x, y:ionization_frequency_Ar},$
              dlimits={ytitle:'Ar Ionization !c Frequency, #/s'}

; make a structure
  ionization_frequency = $
     {time:fismdata.x, $
      ionization_frequency_CO2: ionization_frequency_CO2, $
      ionization_frequency_CO: ionization_frequency_CO, $
      ionization_frequency_O2: ionization_frequency_O2, $
      ionization_frequency_N2: ionization_frequency_N2, $
      ionization_frequency_O: ionization_frequency_O, $
      ionization_frequency_Ar: ionization_frequency_Ar}

  return, ionization_frequency
end
