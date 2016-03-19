
;+
;Procedure:
;  mms_part_products_crib
;
;Purpose:
;  Basic example on how to use mms_part_products to generate pitch angle and gyrophase distributions
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-18 17:31:20 -0700 (Fri, 18 Mar 2016) $
;$LastChangedRevision: 20511 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_part_products_crib.pro $
;
;-


;==========================================================
; FPI - L2
;==========================================================

  ;clear data
  del_data,'*'

  ;setup
  probe='1'
  species='e'
  rate='brst'
  level = 'l2'

  ;use short time range for data due to high resolution
  ;use longer time range for support data to ensure we have enough to work with
  timespan, '2016-01-20/19:50:00', 15, /sec
  trange = timerange()
  support_trange = trange + [-60,60]
 
  ;load particle data
  mms_load_fpi, probe=probe, trange=trange, data_rate=rate, level=level, datatype='d'+species+'s-dist'
                
  ;load state data (needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, trange=support_trange, /ephemeris

  ;load magnetic field data
  mms_load_fgm, probe=probe, trange=support_trange, level=level, /no_attitude
 
  ;magnetic field vector
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  
  ;spacecraft position
  ; -currently wrong, FAC spectrograms will be skipped
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;L2 particle data
  name = 'mms'+probe+'_d'+species+'s_dist_'+rate
 
  ;generate products
  mms_part_products, name, trange=trange, $
                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
                     outputs=['phi','theta','energy','moments','pa','gyro']

  ;plot spectrograms
  tplot,name+'_'+['energy','theta','phi','pa','gyro']
  tlimit,trange
  
  stop
 
  ;plot moments
  tplot, name+'_'+['density', 'avgtemp']
  
  stop



;==========================================================
; HPCA - L2
;==========================================================

  ;clear data
  del_data,'*'

  ;setup
  probe = '1'
  species = 'hplus'
  data_rate = 'srvy'
  level = 'l2'
  
  timespan, '2015-10-20/05:56:30', 5, /min
  trange = timerange()
  
  ;load particle data
  mms_load_hpca, probe=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

  ;load state data (needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, trange=trange, /ephemeris

  ;load magnetic field data (for field aligned coordinates)
  mms_load_fgm, probe=probe, trange=trange, level=level, /no_attitude
 
  ;magnetic field vector
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  
  ;spacecraft position
  ; -currently wrong, FAC spectrograms will be skipped
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;L2 particle data
  name =  'mms'+probe+'_hpca_'+species+'_phase_space_density'
 
  ;generate products
  mms_part_products, name, trange=trange,$
                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
                     outputs=['energy','phi','theta','pa','gyro','moments']

  tplot,name+'_'+['energy','theta','phi','pa','gyro']

  stop

  ; plot the moments
  tplot, name+'_'+['density', 'avgtemp']
  
  stop



;==========================================================
; FPI - L1  (non-public data)
;==========================================================

  del_data,'*'

  ;setup
  probe='1'
  species='i'
  level ='l1b'
  rate='brst'

  timespan, '2015-10-20/05:56:30', 5, /min
  trange = timerange()

  ;load particle data
  mms_load_fpi, probe=probe, trange=trange, data_rate=rate, level=level, datatype='d'+species+'s-dist'
   
  ;convert particle data to 3D structures
  name =  'mms'+probe+'_d'+species+'s_'+rate+'SkyMap_dist'

  mms_part_products, name, mag_name=bname, pos_name=pos_name, trange=trange,$
                    outputs=['energy','phi','theta','moments']

  tplot, name+'_'+['energy','theta','phi']
  tlimit, trange

  stop

  tplot, name+'_'+['density','avgtemp']

  stop



;===================================
; HPCA - L1  (non-public data)
;===================================

  ;clear data
  del_data,'*'

  ;setup
  probe='1'
  species='hplus'
  data_rate = 'brst'
  level = 'l1b'
  ;data_rate = 'srvy'

  timespan, '2015-10-20/05:56:30', 5, /min  ;brst
  ;timespan, '2015-11-16/06:32:00', 20, /min  ;brst/srvy
  trange = timerange()
  
  ;load particle data
  mms_load_hpca, data_rate=data_rate, level=level, datatype='vel_dist', $
                 probe=probe, trange=trange

  ;load azimuth data
  ;this requires a second step for l1 data
  mms_load_hpca, probe=probe, trange=trange, $
                 data_rate=data_rate, level='l1a', datatype='spinangles', $
                 varformat='*_angles_per_ev_degrees'

  ;name of tplot variable containing the particle data
  name =  'mms'+probe+'_hpca_'+species+'_vel_dist_fn'
 
  mms_part_products, name, mag_name=bname, pos_name=pos_name, trange=trange,$
                     outputs=['energy','phi','theta','moments']

  tplot,name+'_'+['energy','theta','phi']

  stop

  tplot, name+'_'+['density', 'avgtemp']
  
  stop


end