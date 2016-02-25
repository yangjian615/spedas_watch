;+
;Purpose:
;  Crib demonstrating usage of stel3d tool with MMS particle data
;
;
;Notes:
;  -Currently only compatible with modified tool at:
;    /spedas_gui/stel_3d/stel_3d_pro_20150811/pro
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-24 11:09:47 -0800 (Wed, 24 Feb 2016) $
;$LastChangedRevision: 20156 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_crib_stel3d.pro $
;-


;IMPORTANT NOTES =======================================================
; 
;  -Data in counts is not available so eflux data is used instead.
;
;  -Data must have at least 3 distributions within the time range.
;
;======================================================================




; FPI ------------------------------------------------------------------------
;
;probe='1'
;species='i'
;trange='2015-08-15/12:50:' + ['00','02']
;
;mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
;              probe=probe, trange=trange
;
;;load data into standard structures
;name =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'
;dist = mms_get_fpi_dist(name, trange=trange)
;
;-----------------------------------------------------------------------------



; HPCA -----------------------------------------------------------------------

probe = '1'
data_rate = 'brst'
trange = '2015-10-20/' + ['05:56:30','05:59:00']  ;brst
;data_rate = 'srvy'
;trange = '2015-11-16/' + ['06:32:00','06:40:00']  ;brst/srvy

;particle data & azimuth data
mms_load_hpca, probes=probe, trange=trange, $
               data_rate=data_rate, level='l1b', datatype='vel_dist'
mms_load_hpca, probe=probe, trange=trange, $
               data_rate=data_rate, level='l1a', datatype='spinangles', $
               varformat='*_angles_per_ev_degrees'

;load data into standard structures
tname = 'mms'+probe[0]+'_hpca_hplus_vel_dist_fn'
dist = mms_get_hpca_dist(tname)

;-----------------------------------------------------------------------------



;fill the counts field with eflux for now
mms_part_process, dist, dist_counts, units='eflux'


;convert to stel3d data model
data = spd_dist_to_hash(dist, counts=dist_counts)


;required by stel3d
thm_init


stel3d, data=data, trange=trange



end