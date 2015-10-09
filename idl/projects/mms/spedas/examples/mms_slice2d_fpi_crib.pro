;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS FPI data using spd_slice2d.
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
;$LastChangedDate: 2015-10-08 13:37:49 -0700 (Thu, 08 Oct 2015) $
;$LastChangedRevision: 19035 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_slice2d_fpi_crib.pro $
;-



;======================================================================
; FPI
;--------
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


;load particle data into tplot
;---------------------------------------------
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
              probe=probe, trange=trange

name =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'


;reformat data from tplot variable into compatible 3D structures
;  -this will return a pointer to the structure array in order to save memory 
;---------------------------------------------
dist = mms_get_fpi_dist(name)


;load support data for later examples
;---------------------------------------------
mms_load_dfg, probe=probe, trange=trange, level='ql'

mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-moms', $
              probe=probe, trange=trange

bname = 'mms'+probe+'_dfg_srvy_gse_bvec'
vname = 'mms'+probe+'_d'+species+'s_bulk'
join_vec, vname + ['X','Y','Z'], vname


;basic slice
;  -some plot annotations will need to be set manually for now
;---------------------------------------------

time = '2015-8-15/12:50' ;start time of slice
window = 2 ;window (sec) over which to average

;get slice
;  -geometric interpolation is slow but shows bin boundaries
;  -3d/2d interpolation show smooth contours
slice = spd_slice2d(dist, time=time, window=window) ;geometric interpolation
;slice = spd_slice2d(dist, time=time, window=window, /three) ;3D interpolation
;slice = spd_slice2d(dist, time=time, window=window, /two) ;2D interpolation

;set annotations (temporary)
slice.coord = 'GSE'
slice.units = 'f (sec^3 / cm^6)' 

;plot
spd_slice2d_plot, slice

stop


;field/velocity aligned slice
;  -the plot's x axis is parallel to the B field
;  -the plot's y axis is defined by the bulk velocity
;---------------------------------------------
slice = spd_slice2d(dist, time=time, window=window, /three, $
                    rotation='bv', mag_data=bname, vel_data=vname)

;set annotations (temporary)
slice.units = 'f (sec^3 / cm^6)'

;plot
spd_slice2d_plot, slice


end