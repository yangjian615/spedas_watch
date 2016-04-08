
;+
;Procedure:
;  mms_part_products_crib_l1
;
;Purpose:
;  Basic example on how to use mms_part_products to generate particle
;  spectrograms and moments from level 1 MMS HPCA and FPI distributions.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-04-07 15:45:54 -0700 (Thu, 07 Apr 2016) $
;$LastChangedRevision: 20747 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_part_products_crib_l1.pro $
;
;-


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
                    outputs=['energy','phi','theta']

  tplot, name+'_'+['energy','theta','phi']
  tlimit, trange

  stop

  ; !!!!!! words of caution <------ by egrimes, 4/7/2016:
  ; While you can use mms_part_products to generate particle moments for FPI from
  ; the distributions, these calculations are currently missing several important
  ; components, including photoelectron removal and S/C potential corrections.
  ; The official moments released by the team include these, and are the scientific
  ; products you should use in your analysis; see mms_load_fpi_crib to see how to load
  ; the FPI moments released by the team (des-moms, dis-moms datatypes)
  ; tplot, name+'_'+['density','avgtemp']
  ; stop



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

  timespan, '2015-10-20/05:56:30', 5, /min  ;brst
  ;timespan, '2015-11-16/06:32:00', 20, /min  ;brst/srvy
  trange = timerange()
  
  ;load particle data
  mms_load_hpca, probe=probe, trange=trange, data_rate=data_rate, level=level, $
                 datatype='ion'
                 
  ;load azimuth data (this requires a second step for l1 data)
  mms_load_hpca, probe=probe, trange=trange, $
                 data_rate=data_rate, level='l1a', datatype='spinangles', $
                 varformat='*_angles_per_ev_degrees'

  ;name of tplot variable containing the particle data
  name =  'mms'+probe+'_hpca_'+species+'_phase_space_density'
 
  mms_part_products, name, mag_name=bname, pos_name=pos_name, trange=trange,$
                     outputs=['energy','phi','theta','moments']

  tplot,name+'_'+['energy','theta','phi']

  stop

  tplot, name+'_'+['density', 'avgtemp']
  
  stop


 end