
;+
;Procedure:
;  mms_part_products_crib
;
;Purpose:
;  Basic example on how to use mms_part_products to generate pitch angle and gyrophase distributions
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-27 08:50:32 -0800 (Sat, 27 Feb 2016) $
;$LastChangedRevision: 20243 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_part_products_crib.pro $
;
;-

;===================================
; FPI
;===================================

  ;clear data
  del_data,'*'
  ;set time interval
  probe='1'
  species='e'
  rate='brst'
  level = 'l2'

  trange = ['2016-01-20/19:50:00', '2016-01-20/20:00:00']
  timespan,trange
  
  level = 'def'     ; 'pred'
 
  ;load state data.(needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, level=level

  ;load particle data
  mms_load_fpi, data_rate=rate, level='l2', datatype='d'+species+'s-dist', $
    probe=probe, trange=trange
    
  ;load magnetic field data
  mms_load_fgm, probe=probe, trange=trange, /no_att, level='l2'
 
  ;Until coordinate systems are properly labeled in mms metadata, this variable must be dmpa
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  
  ;Not all mms position data have coordinate systems labeled in metadata, this one does
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;convert particle data to 3D structures
  ; the following name is valid in the L1b files:
  ;name =  'mms'+probe+'_d'+species+'s_'+rate+'SkyMap_dist'
  ; and this one is valid for L2 data:
  name = 'mms'+probe+'_d'+species+'s_dist_'+rate
 
  mms_part_products,name,mag_name=bname,pos_name=pos_name,trange=trange,outputs=['phi','theta','pa','gyro','energy', 'moments'],probe=probe

  tplot,name+'_'+['energy','theta','phi','pa','gyro']
  tlimit,['2016-01-20/19:50:00', '2016-01-20/20:00:00']

  stop
 
  ; plot the moments
  window, 1
  tplot, name+'_'+['density', 'avgtemp']
  
  stop

;===================================
; HPCA
;===================================

  ;clear data
  del_data,'*'

  ;setup
  probe='1'
  species='hplus'
  data_rate = 'brst'
  ;data_rate = 'srvy'

  timespan, '2015-10-20/05:56:30', 5, /min  ;brst
  ;timespan, '2015-11-16/06:32:00', 20, /min  ;brst/srvy
  trange = timerange()
  
  ;load particle data
  mms_load_hpca, data_rate=data_rate, level='l1b', datatype='vel_dist', $
                 probe=probe, trange=trange

  ;load azimuth data
  mms_load_hpca, probe=probe, trange=trange, $
                 data_rate=data_rate, level='l1a', datatype='spinangles', $
                 varformat='*_angles_per_ev_degrees'

  ;load state data (needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, trange=trange

  ;load magnetic field data (for field aligned coordinates)
  mms_load_fgm, probe=probe, trange=trange, /no_att, level='l2'
 
  ;until coordinate systems are properly labeled in mms metadata, this variable must be dmpa
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  
  ;not all mms position data have coordinate systems labeled in metadata, this one does
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;name of tplot variable containing the particle data
  name =  'mms'+probe+'_hpca_'+species+'_vel_dist_fn'
 
  mms_part_products, name, mag_name=bname, pos_name=pos_name, trange=trange,$
                    outputs=['phi','theta','pa','gyro','energy', 'moments'],probe=probe

  tplot,name+'_'+['energy','theta','phi','pa','gyro']

end