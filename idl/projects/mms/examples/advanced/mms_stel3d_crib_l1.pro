;+
;Purpose:
;  Crib demonstrating usage of stel3d tool with level 1 MMS particle data
;
;
;Notes:
;  See also:
;     mms_stel3d_crib_l2
;  Compatible with modified tool at:
;     .../spedas_gui/stel_3d/stel_3d_pro_20150811/pro/
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-04-01 12:14:17 -0700 (Fri, 01 Apr 2016) $
;$LastChangedRevision: 20703 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_stel3d_crib_l1.pro $
;-


;IMPORTANT NOTES =======================================================
; 
;  -Data must have at least 3 distributions within the time range.
;
;======================================================================



;=============================================================
; FPI - L1  (non-public data)
;=============================================================

probe='1'
species='i'
level = 'l1b'

data_rate = 'fast'
trange='2015-08-15/12:' + ['50','51']  ;fast

;data_rate = 'brst'
;trange='2015-08-15/12:50:' + ['00','02'] ;brst

;load data into tplot
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
              probe=probe, trange=trange

;load data into standard structures
name = 'mms'+probe+'_d'+species+'s_'+data_rate +'SkyMap_dist'
dist = mms_get_fpi_dist(name, trange=trange)

;convert structures to stel3d data model
data = spd_dist_to_hash(dist)


;load bfield (cyan vector) and velocity (yellow vector) support data
mms_load_fgm, instrument='dfg', probe=probe, trange=trange, level='ql'
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', $
              probe=probe, trange=trange

bfield = 'mms'+probe+'_dfg_srvy_dmpa_bvec'
velocity = 'mms'+probe+'_d'+species+'s_bulk'

;combine separate velocity components
join_vec, velocity + ['X','Y','Z'], velocity


;once GUI is open select PSD from Units menu
stel3d, data=data, trange=trange, bfield=bfield, velocity=velocity


stop



;=============================================================
; HPCA - L1  (non-public data)
;=============================================================

probe = '1'
level = 'l1b'
species = 'hplus'

data_rate = 'brst'
trange = '2015-10-20/' + ['05:56:30','05:59:00']  ;brst

;data_rate = 'srvy'
;trange = '2015-11-16/' + ['06:32:00','06:40:00']  ;brst/srvy

;load particle data & azimuth values
mms_load_hpca, probe=probe, trange=trange, data_rate=data_rate, level=level, $
               datatype='ion', varformat='*_phase_space_density'          
mms_load_hpca, probe=probe, trange=trange, $
               data_rate=data_rate, level='l1a', datatype='spinangles', $
               varformat='*_angles_per_ev_degrees'

;load data into standard structures
tname = 'mms'+probe[0]+'_hpca_'+species+'_phase_space_density'
dist = mms_get_hpca_dist(tname)

;convert structures to stel3d data model
data = spd_dist_to_hash(dist)


;load bfield (cyan vector) and velocity (yellow vector) support data
mms_load_fgm, instrument='dfg', probe=probe, trange=trange, level='ql'
mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, $
               datatype='moments', varformat='*_hplus_ion_bulk_velocity'

bfield = 'mms'+probe+'_dfg_srvy_dmpa_bvec'
velocity = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'


;once GUI is open select PSD from Units menu
stel3d, data=data, trange=trange, bfield=bfield, velocity=velocity



end