
;+
;Procedure:
;  mms_part_products_crib
;
;Purpose:
;  Basic example on how to use mms_part_products to generate pitch angle and gyrophase distributions
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-12-11 14:25:49 -0800 (Fri, 11 Dec 2015) $
;$LastChangedRevision: 19614 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_part_products_crib.pro $
;
;-
  ;clear data
  del_data,'*'
  ;set time interval
  probe='3'
  species='e'
  ;timespan,'2015-09-21/13:52', 2, /min
  ;trange = timerange()
  ;trange = ['2015-09-19/09:08:13', '2015-09-19/09:09']
  ;trange = ['2015-09-19/09:08:48', '2015-09-19/09:09:00']
  trange = ['2015-09-19/09:08:00', '2015-09-19/09:08:15']
  timespan,trange
  
  level = 'def'     ; 'pred'
 
  ;load state data.(needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, level=level

  ;load particle data
  mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
    probe=probe, trange=trange
    
  ;load magnetic field data
  mms_load_dfg, probe=probe, trange=trange 
 
  ;Until coordinate systems are properly labeled in mms metadata, this variable must be dmpa
  bname = 'mms'+probe+'_dfg_srvy_l2pre_dmpa_bvec'
  
  ;Not all mms position data have coordinate systems labeled in metadata, this one does
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;convert particle data to 3D structures
  name =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'
 
  mms_part_products,name,mag_name=bname,pos_name=pos_name,trange=trange,outputs=['phi','theta','pa','gyro','energy']
  tplot,'mms'+probe+'_d'+species+'s_brstSkyMap_dist'+['energy','theta','phi','pa','gyro']
  tlimit,['2015-09-19/09:08:14', '2015-09-19/09:08:15']
  stop
 
end