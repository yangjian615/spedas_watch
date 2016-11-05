
;+
;Procedure:
;  mms_part_products_crib
;
;Purpose:
;  Basic example on how to use mms_part_products to generate particle
;  spectrograms and moments from level 2 MMS HPCA and FPI distributions.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-04 15:46:21 -0700 (Fri, 04 Nov 2016) $
;$LastChangedRevision: 22309 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/deprecated/mms_part_products_crib.pro $
;
;-


;==========================================================
; FPI - L2
;==========================================================

  ;clear data
  del_data,'*'

  ;setup
  probe='1'      ;1, 2, 3, 4
  species='e'    ;e, i
  rate='brst'    ;brst, fast
  level = 'l2'

  ;use short time range for data due to high resolution
  ;use longer time range for support data to ensure we have enough to work with
  timespan, '2015-10-16/13:05:40', 30, /sec
  trange = timerange()
  support_trange = trange + [-60,60]
 
  ;load particle data
  mms_load_fpi, probe=probe, trange=trange, data_rate=rate, level=level, datatype='d'+species+'s-dist'
                
  ;load state data (needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, trange=support_trange

  ;load magnetic field data
  mms_load_fgm, probe=probe, trange=support_trange, level=level
 
  ;tplot names for L2 particle data, magnetic field vector, and spacecraft position
  name = 'mms'+probe+'_d'+species+'s_dist_'+rate
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  pos_name = 'mms' + probe+ '_defeph_pos'
 
  ;generate products
  mms_part_products, name, trange=trange, $
                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
                     outputs=['phi','theta','energy','pa','gyro']

  ;plot spectrograms
  tplot,name+'_'+['energy','theta','phi','pa','gyro']
  tlimit,trange
  
  stop

  ;plot moments
  ; !!!!!! words of caution <------ by egrimes, 4/7/2016:
  ; While you can use mms_part_products to generate particle moments for FPI from
  ; the distributions, these calculations are currently missing several important
  ; components, including photoelectron removal and S/C potential corrections.
  ; The official moments released by the team include these, and are the scientific
  ; products you should use in your analysis
  ; 
  ; tplot, name+'_'+['density', 'avgtemp']
  ; stop
  ; 
  ;  The following example shows how to load the FPI moments 
  ;  released by the team (des-moms, dis-moms datatypes)
  mms_load_fpi, probe=probe, trange=trange, data_rate=rate, level=level, datatype='d'+species+'s-moms'
  tplot, 'mms' + probe + '_d'+species+'s_numberdensity_dbcs_brst'

  stop


;==========================================================
; HPCA - L2
;==========================================================

  ;clear data
  del_data,'*'

  ;setup
  probe = '1'          ;1, 2, 3, 4
  species = 'hplus'    ;hplus, heplus, heplusplus, oplus, oplusplus
  data_rate = 'srvy'   ;srvy, brst
  level = 'l2'
  
  timespan, '2015-10-16/13:02:30', 5, /min
  trange = timerange()
  
  ;load particle data
  mms_load_hpca, probe=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

  ;load state data (needed for coordinate transforms and field aligned coordinates)
  mms_load_state, probes=probe, trange=trange

  ;load magnetic field data (for field aligned coordinates)
  mms_load_fgm, probe=probe, trange=trange, level=level
 
  ;tplot names for L2 particle data, magnetic field vector, and spacecraft position
  name =  'mms'+probe+'_hpca_'+species+'_phase_space_density'
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  pos_name = 'mms' + probe+ '_defeph_pos'
  
  ;generate products
  mms_part_products, name, trange=trange,$
                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
                     outputs=['energy','phi','theta','pa','gyro','moments']
                     
  ;generate products (experimental option)
  ;  The /no_regrid option uses a regular transformation on the HPCA to avoid the more general spherical interpolation
  ;    The main benefit of the /no_regrid keyword is to reduce the runtime of mms_part_products
  ;  mms_part_products, name, trange=trange,/no_regrid, $
  ;                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
  ;                     outputs=['energy','phi','theta','pa','gyro','moments']


  ;plot spectrograms
  tplot,name+'_'+['energy','theta','phi','pa','gyro']

  stop

  ;plot moments
  tplot, name+'_'+['density', 'avgtemp']
  
  stop




end