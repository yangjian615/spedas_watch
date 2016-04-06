;+
;Purpose:
;  Crib demonstrating usage of stel3d tool with public MMS particle data
;
;
;Notes:
;  See also:
;     mms_stel3d_crib_l1
;  Compatible with modified tool at:
;     .../spedas_gui/stel_3d/stel_3d_pro_20150811/pro/
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-04-01 12:14:17 -0700 (Fri, 01 Apr 2016) $
;$LastChangedRevision: 20703 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_stel3d_crib_l2.pro $
;-


;IMPORTANT NOTES =======================================================
; 
;  -Data must have at least 3 distributions within the time range.
;
;======================================================================



;=============================================================
; FPI - L2
;=============================================================

del_data,'*'

;setup
probe = '1'
species = 'i'
data_rate = 'brst'
level = 'l2'

;names of tplot variables that will contain particle data, bfield, and bulk velocity
name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate 
bfield = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
velocity = 'mms'+probe+'_d'+species+'s_bulk'

;use short time range for data due to high resolution (saves time/memory)
;use longer time range for support data to ensure we have enough to work with
timespan, '2015-10-20/05:56:30', 4, /sec
;timespan, '2015-11-18/02:10:00', 10, /sec

trange = timerange()
support_trange= trange + [-60,60]

;load data into tplot
mms_load_fpi, probe=probe, trange=trange, data_rate=data_rate, level=level, $
              datatype='d'+species+'s-dist'

;load data into standard structures
dist = mms_get_fpi_dist(name, trange=trange)

;convert structures to stel3d data model
data = spd_dist_to_hash(dist)

;load bfield (cyan vector) and velocity (yellow vector) support data
mms_load_fgm, probe=probe, trange=support_trange, level='l2'
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', $
              probe=probe, trange=support_trange

;combine separate velocity components
join_vec, velocity + ['x','y','z'] +'_dbcs_'+data_rate, velocity


;once GUI is open select PSD from Units menu
stel3d, data=data, trange=trange, bfield=bfield, velocity=velocity


stop


;=============================================================
; HPCA - L2
;=============================================================

del_data,'*'

;setup
probe = '1'
data_rate = 'srvy' ;only srvy available for l2
level = 'l2' ;'e'

;names of tplot variables that will contain particle data, bfield, and bulk velocity
tname = 'mms'+probe+'_hpca_hplus_phase_space_density'
bfield = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
velocity = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'

;use short time range for data due to high resolution (saves time/memory)
timespan, '2015-10-20/05:56:30', 1, /min
trange = timerange()

;load data into tplot
mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

;load data into standard structures
dist = mms_get_hpca_dist(tname)

;convert structures to stel3d data model
data = spd_dist_to_hash(dist)

;load bfield (cyan vector) and velocity (yellow vector) support data
mms_load_fgm, probe=probe, trange=trange, level='l2'
mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, $
               datatype='moments', varformat='*_hplus_ion_bulk_velocity'


;once GUI is open select PSD from Units menu
stel3d, data=data, trange=trange, bfield=bfield, velocity=velocity


stop



end