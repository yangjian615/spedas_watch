;+
;NAME:
; mvn_lpw_overplot
;PURPOSE:
; MAVEN PFP LPW Quicklook Plot
;CALLING SEQUENCE:
; mvn_lpw_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      l0_input_file = l0_input_file, noload_data = noload_data, $
;      _extra=_extra
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; Plots, on the screen or in a png file
;KEYWORDS:
; date = If set, a plot for the input date.
; time_range = If set, plot this time range, note that this supercedes
;              the date keyword, if both are set, the time range is
;              attempted.
; l0_input_file = A filename for an input file, if this is set, the
;                 date and time_range keywords are ignored.
; makepng = If set, make a png file, with filename
;           'mvn_lpw_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; noload_data = if set, don't load data
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-03-26 14:17:04 -0700 (Wed, 26 Mar 2014) $
; $LastChangedRevision: 14676 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_lpw_overplot.pro $
Pro mvn_lpw_overplot, date = date, time_range = time_range, $
                      makepng=makepng, device = device, directory = directory, $
                      l0_input_file = l0_input_file, $
                      noload_data = noload_data, $
                      _extra=_extra

mvn_qlook_init, device = device

;First load the data
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else Begin
   filex = mvn_l0_db2file(date)
Endelse
If(~keyword_set(noload_data)) Then Begin
   del_data, '*'
   mvn_lpw_load, filex, filetype='L0', tplot_var='all'
   mvn_lpw_ql_instr_page
Endif


varlist = ['mvn_lpw_euv','mvn_lpw_euv_temp_C','mvn_lpw_hsk_temp',$
           'modes','mvn_lpw_spec_hf_pas','mvn_lpw_spec_mf_pas',$
           'mvn_lpw_spec_lf_pas', 'E12','SC_pot','mvn_lpw_swp1_IV',$
           'mvn_lpw_swp2_IV','htime']

varlist0 = varlist
;You need a time range for the data, Assuming that everything comes
;from one kind of packet, you should be ok, but check all variables
;just in case
varlist = mvn_qlook_vcheck(varlist, tr = tr)
If(varlist[0] Eq '') Then Begin
    dprint, 'No data, Returning'
    Return
Endif

;Remove gap between plot panels
tplot_options, 'ygap', 0.0d0

;Get the date
p1  = strsplit(file_basename(filex), '_',/extract)
date = p1[4]
d0 = time_double(time_string(date))
tr = tr > d0
;plot the data
tplot, varlist, title = 'MAVEN LPW Quicklook '+date

If(keyword_set(makepng)) Then Begin
    If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    fname = pdir+mvn_qlook_filename('lpw', tr, _extra=_extra)
    makepng, fname
Endif

Return
End