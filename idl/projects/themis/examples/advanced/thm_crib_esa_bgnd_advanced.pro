;+
;Procedure:
;  thm_crib_esa_bgnd_advanced
;
;
;Purpose:
;  Demonstrate application of advanced background removal routines.
;  These routines attempt to calculate and subtract ESA background
;  based on ESA count statistics and SST electron data.
;
;  Photo-electron and secondary backgrounds are also calculated 
;  for ESA electrons but are not currently subtracted. 
;
;  *** This is a work in progress, please report any bugs/issues! ***
;
;
;Notes:
;
;       
;See also:
;  thm_crib_esa_bgnd_remove
;  thm_crib_part_products
;
;  thm_load_esa_bgk (main routine to calculate background)
;  thm_pse_bkg_auto (calculate pser-based background)
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-06-27 18:32:34 -0700 (Mon, 27 Jun 2016) $
;$LastChangedRevision: 21378 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_esa_bgnd_advanced.pro $
;-


del_data, '*'

probe = 'c'
datatype = 'peir'

timespan, '2011-07-14/08', 4, /hours
trange = timerange()


;background determination requires state and some particle data be loaded
;  -peer and peir data must be loaded manually
;  -pser data will be loaded automatically (loaded here for clarity)
thm_part_load, probe=probe, trange=trange, datatype=['peer','peir']
thm_part_load, probe=probe, trange=trange, datatype='pser', /get_support
thm_load_state, probe=probe, trange=trange, /get_support


;calculate background
;  -assumes peer & peir data are present, will load pser data as needed
;  -if both iesa and sst data sets are present, will use the lower background estimate 
;  -uses iesa data for background in the inner magnetosphere
thm_load_esa_bkg, probe=probe


;get energy spectra and moments with and without background subtracted
;  -using /esa_bgnd_advanced will disable default anode-based background subtraction
;  -/esa_bgnd_advanced can also be used with thm_part_combine and thm_part_slice2d
thm_part_products, probe=probe, trange=trange, datatype=datatype, outputs='energy moments'
thm_part_products, probe=probe, trange=trange, datatype=datatype, outputs='energy moments', $
                   /esa_bgnd_advanced, suffix='_sub'


options, '*density*', yrange=[1e-3,1]
options, '*eflux_energy*', zrange=[10,1e6]

window, xs=900, ys=1000
tplot, 'th'+probe+'_'+datatype+'_' + ['density*','eflux_energy*']


end