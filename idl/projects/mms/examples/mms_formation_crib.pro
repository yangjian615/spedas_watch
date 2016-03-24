;+
; MMS spacecraft formation crib sheet
;
;  This script shows how to create 3D plots of the S/C formation
;    at a given time
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-23 15:39:31 -0700 (Wed, 23 Mar 2016) $
; $LastChangedRevision: 20567 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_formation_crib.pro $
;-

; https://lasp.colorado.edu/mms/sdc/public/data/sdc/mms_formation_plots/mms_formation_plot_20160108023624.png
time = '2016-1-08/2:36'

; without XY-plane projections
mms_mec_formation_plot, time

stop

; with the XY projections
mms_mec_formation_plot, time, /xy_projection

stop

; with XY projections and the tetrahedron quality factor
mms_mec_formation_plot, time, /xy_projection, /quality

end


