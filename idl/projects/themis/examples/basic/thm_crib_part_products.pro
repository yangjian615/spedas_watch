
;+
;PROCEDURE: thm_crib_part_products
;PURPOSE:
;  Demonstrate basic usage of routine for generating particle moments and spectra.
;    
;NOTES:
;  A lot of features aren't shown here.  This crib is intended to Keep It Simple.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-03-05 16:56:44 -0800 (Wed, 05 Mar 2014) $
;$LastChangedRevision: 14507 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_part_products.pro $
;-

 compile_opt idl2

;----------------------------------------------------------------------------------------------------------------------------
;Example 1, ESA energy eflux spectra, theta(spacecraft spin-axis latitude, eflux), phi(spacecraft spin-axis latitutde, eflux)
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange 

tplot,['tha_peif_eflux_energy','tha_peif_eflux_theta','tha_peif_eflux_phi']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 2, SST energy eflux spectra, theta(spacecraft spin-axis latitude, eflux), phi(spacecraft spin-axis latitutde, eflux)
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='psif'
trange=['2008-02-23','2008-02-23/6']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange

tplot,['tha_psif_eflux_energy','tha_psif_eflux_theta','tha_psif_eflux_phi']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 3:  pitch angle and gyrophase
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load support data for pitch-angle and gyrophase rotation
thm_load_state,probe=probe,coord='gei',/get_support,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='pa gyro'

tplot,['tha_peif_eflux_gyro','tha_peif_eflux_pa']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 4: moments
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load potential and magnetic field data
thm_load_mom,probe=probe,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

;Note ESA background removal is now enabled by default.
;Use esa_bgnd=0 keyword to thm_part_products to disable background removal
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments'

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the labels
tplot,['tha_peef_density','tha_peef_velocity','tha_peef_t3']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 5: ESA Background Removal
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange
 
thm_load_mom,probe=probe,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

thm_part_load,probe=probe,trange=trange,datatype=datatype

;ESA background removal keywords and their default values are shown below.
;See thm_crib_esa_bgnd_remove for more.
;  **note: Old routines used /bgnd_remove instead of /esa_bgnd_remove to control background removal.
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments pa gyro', $
      /esa_bgnd_remove, bgnd_type='anode', bgnd_npoints=3, bgnd_scale=1

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the left-side labels
tplot,['tha_peef_density','tha_peef_velocity','tha_peef_t3','tha_peef_eflux_pa','tha_peef_eflux_gyro']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 6: Specifying non-default support parameters for moments
;----------------------------------------------------------------------------------------------------------------------------
 

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange
 

thm_load_mom,probe=probe,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

;Note ESA background removal is now enabled by default.
;Use esa_bgnd=0 keyword to thm_part_products to disable background removal
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments pa gyro', $
      mag_name='tha_fgs',pos_name='tha_state_pos',sc_pot_name='tha_pxxm_pot'

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the left-side labels
tplot,['tha_peef_density','tha_peef_velocity','tha_peef_t3','tha_peef_eflux_pa','tha_peef_eflux_gyro']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 7:  Specifying alternate field aligned coordinate systems
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load support data for pitch-angle and gyrophase rotation
thm_load_state,probe=probe,coord='gei',/get_support,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

thm_part_load,probe=probe,trange=trange,datatype=datatype

;options for fac_type are 'mphigeo','phigeo','xgse'
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='pa gyro',fac_type='xgse'

tplot,['tha_peif_eflux_gyro','tha_peif_eflux_pa']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 8:  Energy spectra with field aligned angle limits
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load support data for pitch-angle and gyrophase rotation
thm_load_state,probe=probe,coord='gei',/get_support,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

thm_part_load,probe=probe,trange=trange,datatype=datatype

;produce pitch angle and energy spectrograms from data in the specified pitch angle range
;use "gyro" keyword to set gyrophase range
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='pa energy',pitch=[45,135]

tplot,['tha_peef_eflux_pa','tha_peef_eflux_energy']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 9:  Product restricted to particular energy range 
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange,energy=[10,40000] ;eV

tplot,['tha_peif_eflux_energy','tha_peif_eflux_theta','tha_peif_eflux_phi']

stop


end