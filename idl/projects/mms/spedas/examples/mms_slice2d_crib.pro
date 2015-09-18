;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS HPCA data using spd_slice2d.
;
;  Run as script or copy-paste to command line.
;
;
;Notes:
;  **EXPERIMENTAL!**
;  
;  Caveats:
;    -Azimuths have not been synchronized with sun data and are currently
;     measured from an arbitrary point.
;    -Spacecraft spin and sweep times are assumed to be ideal.
;    -Only tested with burst data.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-16 20:14:13 -0700 (Wed, 16 Sep 2015) $
;$LastChangedRevision: 18812 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_slice2d_crib.pro $
;-


;setup
;---------------------------------------------
probe = '1'
level = 'l1b'
data_rate = 'brst' ;may have to use burst data due to azimuthal decimation

timespan, '2015-09-06/11:00', 1, /hour
trange = timerange()


;load data into tplot
;---------------------------------------------
mms_load_hpca, probes=probe, trange=trange, $
               data_rate=data_rate, level=level, datatype='vel_dist'


;use h+ dist function var for example
tname = 'mms'+probe[0]+'_hpca_hplus_vel_dist_fn'


;reformat data from tplot variable into compatible 3D structures
;  -for now these are not truly 3D structures as each represents only
;   a single azimuthal sweep
;---------------------------------------------
dist = mms_get_hpca_dist(tname)


;generate and plot 2D slice
;  -rotations based on B & V data require tplot support vars
;  -some plot annotations will need to be set manually for now
;---------------------------------------------

time = '2015-09-06/11:30' ;start time of slice
window = 10. ;window (sec) over which to average

;get slice
slice = spd_slice2d(dist, time=time, window=window)

;set annotations
slice.coord = 'arbitrary'
slice.units = 'f (sec^3 / cm^6)' 

;plot
spd_slice2d_plot, slice


end


