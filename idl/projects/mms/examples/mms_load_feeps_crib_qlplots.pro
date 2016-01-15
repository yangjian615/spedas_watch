;+
; MMS FEEPS quicklook plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-14 16:09:30 -0800 (Thu, 14 Jan 2016) $
; $LastChangedRevision: 19740 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_feeps_crib_qlplots.pro $
;-

probe = '1'
timespan, '2015-12-15', 1
width = 950
height = 1000
; options:
; 1) intensity
; 2) count_rate
; 3) counts
type = 'count_rate'

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = ''

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

mms_load_feeps, probe=probe, data_rate='srvy', datatype='electron', suffix='_electrons'
mms_load_feeps, probe=probe, data_rate='srvy', datatype='ion', suffix='_ions'
mms_feeps_pad, probe = probe, datatype = 'electron', suffix='_electrons', energy=[71, 600], data_units = type
mms_feeps_pad, probe = probe, datatype = 'ion', suffix='_ions', energy=[96, 600], data_units = type

; we use the B-field data at the top of the plot, and the position data in GSM coordinates
; loaded from the QL DFG files
mms_load_dfg, probes=probe, level='ql', /no_attitude_data

; ephemeris data - set the label to show along the bottom of the tplot
eph_gsm = 'mms'+probe+'_ql_pos_gsm'

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

options, eph_gsm+'_re_0',ytitle='X-GSM (Re)'
options, eph_gsm+'_re_1',ytitle='Y-GSM (Re)'
options, eph_gsm+'_re_2',ytitle='Z-GSM (Re)'
options, eph_gsm+'_re_3',ytitle='R (Re)'
position_vars = eph_gsm+'_re_'+['3', '2', '1', '0']

if ~postscript then window, xsize=width, ysize=height

tplot_options, 'xmargin', [15, 15]

tplot, 'mms'+probe+['_dfg_srvy_gsm_dmpa', $
                    '_epd_feeps_top_'+type+'_sensorID_3_electrons_clean', $
                    '_epd_feeps_bottom_'+type+'_sensorID_6_ions_clean', $
                    '_epd_feeps_*keV_pad' $
                    ], var_label=position_vars

stop
end
