;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS HPCA and FPI data using spd_slice2d.
;
;  Run as script or copy-paste to command line.
;
;
;Notes:
;
;  *** This is a work in progress ***
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-10-02 20:00:08 -0700 (Fri, 02 Oct 2015) $
;$LastChangedRevision: 18994 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_slice2d_crib.pro $
;-



;======================================================================
; FPI
;--------
;  -Look directions may be incorrect at the moment!
;  -FPI data is large and can be very memory intensive!  It is recommended 
;   that no more than a few minutes of data is loaded at a time for ions
;   and less for electrons.
;  -Only available with burst data.
;======================================================================


;setup
;---------------------------------------------
probe='1'
species='i'
trange=['2015-8-15/12:50','2015-8-15/12:51']


;load data into tplot
;---------------------------------------------
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
              probe=probe, trange=trange

tname =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'


;reformat data from tplot variable into compatible 3D structures
;  -the larger the time range the more memory the structures will require
;  -this will return a pointer to help save memory 
;---------------------------------------------
dist = mms_get_fpi_dist(tname)


;generate and plot 2D slice
;  -rotations based on B & V data require tplot support vars
;  -some plot annotations will need to be set manually for now
;---------------------------------------------

time = '2015-8-15/12:50' ;start time of slice
window = 2 ;window (sec) over which to average

;get slice
slice = spd_slice2d(dist, time=time, window=window) ;geometric interpolation
;slice = spd_slice2d(dist, time=time, window=window, /three) ;3D interpolation
;slice = spd_slice2d(dist, time=time, window=window, /two) ;2D interpolation

;set annotations
slice.coord = 'GSE'
slice.units = 'f (sec^3 / cm^6)' 

;plot
spd_slice2d_plot, slice




stop


;======================================================================
; HPCA
;--------
;  -Azimuths have not been synchronized with sun data and are currently
;   measured from an arbitrary point.
;  -Spacecraft spin and sweep times are assumed to be ideal.
;  -Only tested with burst data.
;======================================================================


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


