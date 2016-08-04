;+
;Procedure:
;  goes_part_products_crib_sheet
;
;Purpose:
;  Demonstrate generation of spectrograms from GOES MAGED and MAGPD data.
;
;$LastChangedDate: 2016-08-02 19:05:30 -0700 (Tue, 02 Aug 2016) $
;$LastChangedRevision: 21596 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/particles/goes_part_products_crib_sheet.pro $
;-


;==========================================================
; Basic spectra
;==========================================================

;setup
probe = '15'
datatype = 'maged'

timespan, '2012-01-01', 5, /days
trange = timerange()


;load particle data
goes_load_data, probe=probe, datatype=datatype, trange=trange, $
                /avg_1m, /noeph

;generate energy, phi, and theta spectra
;these will be in the spacecraft's coodinates
goes_part_products, probe=probe, datatype=datatype, trange=trange, $
                    output='energy phi theta'
 
tplot, 'g'+probe+'_'+datatype+'_dtc_cor_flux_' + ['energy','theta','phi']


stop


;==========================================================
; Field aligned spectra
;==========================================================

;setup
probe = '15'
datatype = 'maged'

timespan, '2012-01-01', 5, /days
trange = timerange()


;load magnetic field
goes_load_data, probe=probe, datatype='fgm', trange=trange, $
                /avg_1m, /noeph

;load particle data
goes_load_data, probe=probe, datatype=datatype, trange=trange, $
                /avg_1m, /noeph

;generate pitch angle and gyrophase spectra
;  -gyrophase will use mphigeo by default
;  -phigeo and rgeo also available, specify with fac_type keyword
goes_part_products, probe=probe, datatype=datatype, trange=trange, $
                    output='pa gyro'
 
tplot, 'g'+probe+'_'+datatype+'_dtc_cor_flux_' + ['pa','gyro']


stop



end
