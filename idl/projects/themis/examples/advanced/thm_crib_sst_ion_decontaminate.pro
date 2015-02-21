;+
;Procedure: thm_crib_sst_ion_decontaminate
;
;Purpose:  A crib on showing how to subtract the SST-FT channels from the SST-O data to remove electron contamination from ion moments.
;
;
;Notes:
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-02-19 17:22:15 -0800 (Thu, 19 Feb 2015) $
; $LastChangedRevision: 17018 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_sst_ion_decontaminate.pro $
;-


trange = ['2010-06-05','2010-06-06']

;set the date and duration (in days)
timespan,trange

;set the spacecraft
probe = 'c'

;loads particle data for data psif
thm_part_load,probe=probe,datatype='psif'
;and psef
thm_part_load,probe=probe,datatype='psef'

sun_bins = dblarr(64)+1 ;allocate variable for bins, with all bins selected
; sun_bins[[0,8,16,24,30,32,33,34,40,48,58,55,56]] = 0

sun_bins[[0,8,16,24,32,33,40,47,48,55,56,57]] = 0

;In modeling the SST open(ion) side, the magnetic deflector should
;deflect electrons below 350 keV away from the deflector. In theory,
;electrons above 400 keV should be eliminated by anti-coincidence logic.
;In practice, the ion channels still get some contamination.  To
;eliminate the contaminated particles.  You can try subtracting
;electrons from the FT channel from the upper bins of the O channel.

dist_psif = thm_part_dist_array(probe=probe,type='psif',trange=trange,/sst_cal,method_clean='manual',sun_bins=sun_bins)
dist_psef = thm_part_dist_array(probe=probe,type='psef',trange=trange,/sst_cal,method_clean='manual',sun_bins=sun_bins)
thm_part_conv_units,dist_psif,units='eflux',/fractional_counts
thm_part_conv_units,dist_psef,units='eflux',/fractional_counts

;for comparison
thm_part_products,probe=probe,datatype='psif',trange=trange,outputs='moments energy',dist_array=dist_psif,suffix='_before'

;this code assumes that psif/psef are matched in angle/mode/time
;if they're not, this code will throw an error.
;To fix you can match time/mode/angle using
;thm_part_time_interpolate ;matches time/mode 
;then 
;thm_part_sphere_interpolate ;matches angle

;This part is not vectorized.  It may take a while
for i = 0,n_elements(dist_psef)-1 do begin ;loop over mode
  dim = dimen((*dist_psef[i]).energy)
  for j = 0,dim[2]-1l do begin ;loop over time
    psif_data = (*dist_psif[i])[j] ;pull out a distribution structure
    psef_data = (*dist_psef[i])[j]
    for k = 0,dim[1]-1l do begin ;loop over angle
      data8 = interpol(psef_data.data[*,k],psef_data.energy[*,k],psif_data.energy[8,k]) ;interpolate electron data to 8th sst ion bin
      psif_data.data[8,k]=(psif_data.data[8,k]-data8) > 0 ; subtract data(store max(result,0)
      data9 = interpol(psef_data.data[*,k],psef_data.energy[*,k],psif_data.energy[9,k]) ;interpolate electron data to 9th sst ion bin
      psif_data.data[9,k]=(psif_data.data[9,k]-data9) > 0 ; subtract data(store max(result,0)     
    endfor
    (*dist_psif[i])[j] = psif_data ;store the modified distribution structure
  endfor
endfor

thm_part_products,probe=probe,datatype='psif',trange=trange,outputs='moments energy',dist_array=dist_psif,suffix='_after'

stop

end