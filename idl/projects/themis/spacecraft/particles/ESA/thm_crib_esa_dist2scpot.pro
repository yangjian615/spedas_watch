;+
;	Batch File: THM_CRIB_ESA_DIST2SCPOT
;
;	Purpose:  Demonstrates the use of THM_ESA_EST_DIST2SCPOT.
;	The program THM_ESA_EST_DIST2SCPOT estimates the spacecraft
;	potential using the ESA electron distribution. The SC
;	potential is estimated by comparison of the slope of the low
;	energy electron flux with the expected slope of secondary electrons
;
;	Calling Sequence:
;	.run thm_crib_esa_dist2scpot, or using cut-and-paste.
;
;	Arguements:  None.
;
;	Notes: None.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-13 13:08:35 -0700 (Mon, 13 Jul 2015) $
; $LastChangedRevision: 18103 $
; $URL $
;-

;for a given date and probe, 

date = '2015-06-07'
probe = 'a'

;The default is to process the full day, using PEER data
thm_esa_est_dist2scpot, date, probe

;the output tplot variable is: th(probe)_est_scpot:

tplot, ['tha_pxxm_pot', 'tha_est_scpot']
stop

;If you set the /plot keyword, then a diagnostic plot will appear
thm_esa_est_dist2scpot, date, probe, /plot
stop

;In the top panel, the ESA count distribution is overplotted by the
;'PXXM_POT' variable, i.e., the on-board estimate for the potential,
;on the bottom panel the estimated SC potential is overplotted.

;thm_esa_est_dist2scpot also accepte the trange keyword, if this
;is set, the date is ignored, and the date variable is reset to the
;value in trange
thm_esa_est_dist2scpot, date, probe, trange = '2015-06-07/'+['15:00','19:00']
stop

;The default is to use PEER data, this can be changed to use 'PEEF' or
;'PEEB' data, using the esa_datatype keyword
thm_esa_est_dist2scpot, date, probe, esa_datatype = 'peef'
stop

;For fun, try the /random_dp keyword. THis will pick a random date and
;probe, and plot the results.

thm_esa_est_dist2scpot, date, probe, /random_dp
stop

;to look at spectra, and the potential estimates for a simgle time,
;use the program thm_esa_testspec3d2.pro

thm_esa_test_spec3d2, date, probe
stop

;click on the plot to choose the time, the result is a plot of the
;peef, peer and peeb distributions for the time. A vertical black line
;shows the PXXM_POT potential value, and the vertical red line shows
;the value estimated from the distribution.

;You can also input a time, using the time_in keyword, Note that if
;the date and probe values have changed, you'll need to read
;ion the data by setting the /init keyword:

;Here we create a set of plots to compare to to figure 9 of the THEMIS
;ESA First Results paper: McFadden etal, 2008SSRv..141..477M

thm_esa_test_spec3d2, '2007-05-28','c', /init, time_in = '2007-05-28/17:24:21'
makepng, 'thc_test_spec3d2_20070528'
thm_esa_test_spec3d2, '2007-06-20','c', /init, time_in = '2007-06-20/23:33:10'
makepng, 'thc_test_spec3d2_20070620'
thm_esa_test_spec3d2, '2007-11-10','c', /init, time_in = '2007-11-10/18:31:52'
makepng, 'thc_test_spec3d2_20071110'
thm_esa_test_spec3d2, '2007-05-28','a', /init, time_in = '2007-05-28/12:30:17'
makepng, 'tha_test_spec3d2_20070528'
stop


;use_dist2scpot is a keyword that can be used in THM_LOAD_ESA_POT:
timespan, '2015-06-07'
thm_load_esa_pot, probe = 'a', /use_dist2scpot

;The output is in the 'tha_esa_pot' variable. Here use copy_data to
;copy this variable to a new variable for comparisons with the default
;sc_pot
copy_data, 'tha_esa_pot', 'tha_esa_pot_dist2scpot'

;Get the default sc potential
thm_load_esa_pot, probe = 'a'
copy_data, 'tha_esa_pot', 'tha_esa_pot_def'
tplot, ['tha_esa_pot_dist2scpot', 'tha_esa_pot_def']

;The default tha_esa_pot has a high value from 1500 to 1900,
;unsupported by the values from the electron distribution, which are
;at the low energy end of the energy grid.

stop

;The Spacecraft potential is used in calculating the electron density,
;to compare the ground-processed density for different sc_pot options,
;use the sc_pot_name keyword in thm_part_moments. The default in
;thm_part_moments is to use the pxxm_pot variable:
thm_load_esa_pkt, probe='a'
thm_part_moments, probe='a', inst=['peer','peir'], suffix = '_pxxm'
thm_part_moments, probe='a', inst=['peer','peir'], sc_pot_name='tha_esa_pot_def', suffix = '_def'
thm_part_moments, probe='a', inst=['peer','peir'], sc_pot_name='tha_esa_pot_dist2scpot', suffix = '_dist2scpot'

;Densities
tplot, ['tha_peer_density_def', 'tha_peer_density_dist2scpot', 'tha_peer_density_pxxm']
;Note that the factor of 5 drop in density present in the default (top) and
;PXXM_POT (bottom) plots from 1500 to 1900 does not show up in the
;dist2scpot (middle) plot.
stop



End ;for now


