;+
; NAME: mvn_euv_l3_load
; SYNTAX: 
;       mvn_euv_l3_load,/daily
;       or
;       mvn_euv_l3_load,/minute
; PURPOSE:
;       Load procedure for the EUV L3 (FISM) daily or minute data
; KEYWORDS: daily, minute, ionization_frequency
;
;   Daily:     
;         loads flare-subtracted data for each day
;   Minute:    
;         loads data with one minute cadence
;   ionization_frequency:
;         If set to any nonzero value, calculates ionization
;         frequencies for CO2, O2, O, CO, N2, according to the
;         photoionization cross-sections from the SwRI database: http://phidrates.space.swri.edu/
;   
; HISTORY:      
; VERSION: 
;  $LastChangedBy: rlillis3 $
;  $LastChangedDate: 2017-02-28 19:02:33 -0800 (Tue, 28 Feb 2017) $
;  $LastChangedRevision: 22876 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/euv/mvn_euv_l3_load.pro $
;CREATED BY:  ali 20150401
;FILE: mvn_euv_l3_load.pro
;-

pro mvn_euv_l3_load,trange=trange,daily=daily,minute=minute,tplot=tplot, $
                    ionization_frequency = ionization_frequency
                    
  
  if keyword_set(daily) then begin
    L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_daily_YYYYMMDD_v??_r??.cdf'
  endif else L3_fileformat='maven/data/sci/euv/l3/YYYY/MM/mvn_euv_l3_minute_YYYYMMDD_v??_r??.cdf'

  files = mvn_pfp_file_retrieve(L3_fileformat,trange=trange,/daily_names,/valid_only)
  
  if files[0] eq '' then begin
    dprint,dlevel=2,'No EUVM L3 (FISM) files were found for the selected time range.'
    store_data,'mvn_euv_l3',/delete
    return
  endif
  
  cdf2tplot,files,prefix='mvn_euv_l3_'
  
  get_data,'mvn_euv_l3_y',data=fismdata; FISM Irradiances
  store_data,'mvn_euv_l3_y',/delete

  store_data,'mvn_euv_l3',data={x:fismdata.x,y:fismdata.y,v:reform(fismdata.v[0,*])}, $
    dlimits={ylog:0,zlog:1,spec:1,ytitle:'Wavelength (nm)',ztitle:'FISM Irradiance (W/m2/nm)'}
  
  if keyword_set(tplot) then tplot,'mvn_euv_l3'

  if keyword_set (ionization_frequency) then begin
     wavelength = reform(fismdata.v[0,*])
     path = FILE_DIRNAME(ROUTINE_FILEPATH('mvn_euv_l3_load'), /mark)
     Cross_section_file = path + 'photon_cross_sections.sav'
     
     ;print, 'Loading cross-section file...'
     restore, cross_section_file
     ;print, 'Done.'
     
     CO2_ionization_process_index = where(photo.CO2.process eq 'CO2 CO2+')
     CO2_ionization_xsection = $
        reform (interpol(photo.CO2.xsection[CO2_ionization_process_index,*], photo.Angstroms*0.1, $
                                        wavelength))
  
     O_ionization_process_index = where(photo.O3P.process eq 'O3P O+')
     O_ionization_xsection = $
        reform (interpol(photo.O3P.xsection[O_ionization_process_index,*], photo.Angstroms*0.1, $
                                      wavelength))

     O2_ionization_process_index1 = where(photo.O3P.process eq 'O2 O2+')
     O2_ionization_process_index2 = where(photo.O3P.process eq 'O2 O+O')
     O2_ionization_xsection = reform (interpol(photo.O2.xsection[O2_ionization_process_index1,*]+$
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

     plank_constant = 6.6d-34   ; standard units
     speed_light = 2.99D8       ; standard units
     
     
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
  endif
end


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
