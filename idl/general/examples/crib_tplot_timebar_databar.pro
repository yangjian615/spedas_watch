;+
; NAME: crib_tplot_timebar_databar
; 
; PURPOSE:  Crib to demonstrate tplot timebar and databar commands  
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_timebar_databar
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot.pro  (basic tplot commands)
;           crib_tplot_layout.pro  (how to arrange plots within a window, and data within a plot)
;           crib_tplot_range.pro   (how to control the range and scaling of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;
; NOTES:
;  1.  As a rule of thumb, "tplot_options" controls settings that are global to any tplot
;   "options" controls settings that are specific to a tplot variable
;   
;  2.  If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-08-04 14:55:14 -0700 (Thu, 04 Aug 2016) $
; $LastChangedRevision: 21600 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_timebar_databar.pro $
;-

;This function is a helper function used in an example below
function km2re_callback,axis,index,value,level
  return,strtrim(string(value/6471.2,format='(F6.2)'),2)
end


;Setup
;-------------------------------------------------

;this line deletes data so we start the crib fresh
store_data,'*',/delete

;first we set a time and load some data.
timespan,'2008-03-23'

;loading spectral data
st_swea_load, /all

;loading line plot data (stereo moments)
st_part_moments, probe='a', /get_mom

st_position_load, probe='a'

;set new color scheme (for aesthetics)
init_crib_colors

;make sure we're using window 0
tplot_options, window=0
window, 0, xsize=700, ysize=800

;increasing the xmargin so it is easier to see the labels
tplot_options, 'xmargin', [18,18] ;18 characters on left side, 12 on right
tplot_options, 'ymargin', [8,4]   ;8 characters on the bottom, 4 on the top

;-------------------------------------------------


;basic plot for comparision
tplot,['sta_SWEA_en','sta_SWEA_mom_flux']


print,'  This first plot is the default, for reference. '
print,'Type ".c" to continue crib examples.'
stop

; add a dashed line at zero
timebar, 0.0, /databar, varname='sta_SWEA_mom_flux', linestyle=2

print,'Add a horizontal bar to mark data with the "timebar" routine and keyword /databar'
print,'Type ".c" to continue'
stop

; add a colored line at midday
timebar, '2008-03-23/12:00', varname='sta_SWEA_mom_flux', color = 6

print,'Add a vertical bar to mark data with the "timebar" routine'
print,'Type ".c" to continue'
stop

print, 'NEW!!!: Use options to add time and databars, and tplot_apply_timebar, tplot_apply_databar to plot. This is especially useful for updating plots if multiple variables need the time and/or databars'

options, ['sta_SWEA_en','sta_SWEA_mom_flux'], 'timebar', $
         ['2008-03-23/12:00', '2008-03-23/18:00']

tplot
tplot_apply_timebar

print, 'First, two timebars for both variables'
print,'Type ".c" to continue'
stop


options, ['sta_SWEA_en','sta_SWEA_mom_flux'], 'timebar', $
         {time: ['2008-03-23/12:00', '2008-03-23/18:00'], $
          color: 2, linestyle: 2, thick:2.0}
tplot
tplot_apply_timebar

print, 'Two timebars for both variables, with color, linestyle and thick set. Note that the input to options is a structure, necessary for setting color, linestyle and thick'
print,'Type ".c" to continue'
stop

print, 'Use options and tplot_apply_databar to  set up horizontal lines'
options, 'sta_SWEA_en', 'databar', {yval:100, color:0, thick:2.0}
options, 'sta_SWEA_mom_flux','databar', 0.0
tplot_apply_databar
print,'Type ".c" to continue'
stop

print, 'Reset, using tplot:'
tplot
print,'Type ".c" to continue'
stop

print, 'The options persist, to clear, use tplot_apply_timebar, or tplot_apply_databar, /clear (Use the varnames keyword for individual variables), and call tplot'
tplot_apply_timebar, /clear
tplot_apply_databar, /clear

tplot


print,'Type ".c" to continue'
stop

del_data, '*'
timespan, '2016-08-01'
thm_load_fit, probe='a'

print, "THEMIS EXAMPLE, set up zero lines for EFS, FGS data"

tplot, 'tha_fgs tha_efs'

options, 'tha_fgs tha_efs', 'databar', {yval:0.0, color:6, thick:2}
tplot_apply_databar

print,'Type ".c" to continue'
stop

print, 'Use tlimit to reset the time range, then reapply databars'
tlimit
tplot_apply_databar

print,'Type ".c" to continue'
stop

print, 'Set up multiple databars for FGS data'
options, 'tha_fgs', 'databar', {yval:[-10, 0, 10], color:[2,4,6], thick:2}
tplot_apply_databar

print,'Type ".c" to continue'
stop

print, 'Drop the zero line for tha_efs, and update'
tplot_apply_databar, varname = 'tha_efs', /clear
tplot
tplot_apply_databar




stop
print,"We're done!"


end
