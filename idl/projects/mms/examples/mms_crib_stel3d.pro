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
;$LastChangedDate: 2016-02-09 18:23:40 -0800 (Tue, 09 Feb 2016) $
;$LastChangedRevision: 19926 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_crib_stel3d.pro $
;-


;IMPORTANT NOTES =======================================================
; 
;  -STEL3D does not currently support subsecond resolution data. 
;   For now, it will only store the last sample from each second.
;
;  -Data in counts is not available so eflux data is used instead.
;
;  -ASCII files will be very large (~10 mb/sec for FPI ion)
;
;  -Data must have at least 3 distributions within the time range.
;
;  -Time range must be a string and fully qualified.
;     e.g.  '2008-2-1' should be '2008-02-01/00:00:00'
;
;======================================================================




; FPI ------------------------------------------------------------------------
;
;probe='1'
;species='i'
;trange='2015-08-15/12:50:' + ['00','03']  ;this will be ~30mb
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


;write to ascii file compatible with stel3d
file = 'mms_part_test_file.txt'
mms_part_write_ascii, dist, filename=file


;required by stel3d
thm_init


stel3d, file, trange=trange


;compare with first sample's original (non-interpolated) data
;spd_part_vis, dist


end