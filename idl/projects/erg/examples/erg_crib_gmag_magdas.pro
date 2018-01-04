;+
; PROGRAM: erg_crib_gmag_magdas
;   This is an example crib sheet that will load MAGDAS magnetometer data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_gmag_magdas
;
; NOTE: See the rules of the road.
;       For more information, see http://magdas.serc.kyushu-u.ac.jp/
;
; Written by: T. Segawa, Feb 12, 2013
;             ERG-Science Center, STEL, Nagoya Univ.
;             erg-sc-core at st4a.stelab.nagoya-u.ac.jp
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2017-12-05 22:09:27 -0800 (Tue, 05 Dec 2017) $
;   $LastChangedRevision: 24403 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/examples/erg_crib_gmag_magdas.pro $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2008-04-03'

; load 1 sec resolution data
erg_load_gmag_magdas_1sec, site='onw daw'

; view the loaded data names
tplot_names

; reset viewport
tplot_options, 'region', [0.05, 0.0, 1.0, 1.0]
options, 'magdas_mag_onw_1sec_hdz','ytitle','MAGDAS!CONW'
options, 'magdas_mag_daw_1sec_hdz','ytitle','MAGDAS!CDAW'

; plot the H, D, and Z components
tplot, ['magdas_mag_*_1sec_hdz']

END
