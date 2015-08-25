;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS HPCA data using THEMIS routines.
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
;$LastChangedDate: 2015-08-24 15:57:34 -0700 (Mon, 24 Aug 2015) $
;$LastChangedRevision: 18601 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_part_slice2d_crib.pro $
;-


;setup
;---------------------------------------------
probe = '1'
level = 'l1b'
data_rate = 'brst' ;may have to use burst data due to azimuthal decimation

timespan, '2015-07-31'
trange = timerange()


;load data into tplot
;---------------------------------------------
mms_load_hpca, probes=probe, trange=trange, $
               data_rate=data_rate, level=level, datatype='vel_dist'


;use h+ dist function var for example
tname = 'mms'+probe[0]+'_hpca_hplus_vel_dist_fn'


;get pointer to formatted array of structures
;  -this will reformat data from the tplot variable into a format that is
;   compatible with the THEMIS particle routines
;---------------------------------------------
ptr = mms_get_hpca_dist(tname)


;now use new data structures as usual
;  -built in coordinate transformations will be invalid (e.g. dsl, gsm, gse)
;  -rotations should still work if data supplied with tplot variable
;   in correct coordinates (though not currently since arbitrary coords are used)
;  -some plot annotations will need to be set manually for now
;---------------------------------------------

;slice setup
slice_time = '2015-07-31/14:36' ;start time of slice
window = 10 ;window (sec) over which to average

;put through slice routine
thm_part_slice2d, ptr, slice_time=slice_time, timewin=window, part_slice=slice;, /three

;annotations that make sense
slice.coord = 'arbitrary'
title = slice.dist + ' ' + time_string(slice.trange[0]) + $
        ' -> '+strmid(time_string(slice.trange[1]),11,8)
ztitle = 'f (sec^3 / cm^6)'

;plot
thm_part_slice2d_plot, slice, title=title, ztitle=ztitle


end


