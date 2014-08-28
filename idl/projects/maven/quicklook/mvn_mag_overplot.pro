;+
;NAME:
; mvn_mag_overplot
;PURPOSE:
; MAVEN PFP MAG Quicklook Plot
;CALLING SEQUENCE:
; mvn_mag_overplot, date = date, time_range = time_range, $
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
;           'mvn_mag_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; noload_data = if set, don't load data
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; Changed to call mvn_mag_ql_tsmaker2, 2014-03-21, may switch back
; next week
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-04-16 15:46:37 -0700 (Wed, 16 Apr 2014) $
; $LastChangedRevision: 14839 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_mag_overplot.pro $
Pro mvn_mag_overplot, date = date, time_range = time_range, $
                      makepng=makepng, device = device, directory = directory, $
                      l0_input_file = l0_input_file, $
                      noload_data = noload_data, _extra=_extra

mvn_qlook_init, device = device

;First load the data
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else Begin
   filex = mvn_l0_db2file(date)
Endelse
If(~keyword_set(noload_data)) Then Begin
    datafile = file_basename(filex)
    input_path = file_dirname(filex)
    data_output_path = './'     ;still used, but may not be used later
    plot_save_path='.'          ;not used here

    mvn_mag_ql, datafile=datafile, input_path=input_path, $
                data_output_path=data_output_path, plot_save_path=plot_save_path, $
                /tsmake, /mag1, /tplot, out_varname = out_varname1, $
                pkt_type = 'ccsds', /delete_save_file
    
    mvn_mag_ql, datafile=datafile, input_path=input_path, $
                data_output_path=data_output_path, plot_save_path=plot_save_path, $
                /tsmake, /mag2, /tplot, out_varname = out_varname2, $
                pkt_type = 'ccsds', /delete_save_file
    
    varlist = [out_varname1, out_varname2]
;You need a time range for the data, Assuming that everything comes
;from one kind of packet, you should be ok, but check all variables
;just in case

    varlist = mvn_qlook_vcheck(varlist, tr = tr)
    If(varlist[0] Eq '') Then Begin
        dprint, 'No data, Returning'
        Return
    Endif
 ;Here I am going to despike the data, using simple_despike_1d.pro
    nvars = n_elements(varlist)
    For j = 0, nvars-1 Do Begin
        get_data, varlist[j], data = dj
        For k = 0, n_elements(dj.y[0, *])-1 Do Begin
            djyk = simple_despike_1d(dj.y[*, k], width = 10)
            dj.y[*, k] = djyk
        Endfor
        store_data, varlist[j], data = dj
    Endfor
 Endif Else Begin
    varlist = ['mvn_ql_mag1', 'mvn_ql_mag2']
    varlist = mvn_qlook_vcheck(varlist, tr = tr)
    If(varlist[0] Eq '') Then Begin
        dprint, 'No data, Returning'
        Return
    Endif
 Endelse
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
tplot, varlist, title = 'MAVEN MAG Quicklook '+date

If(keyword_set(makepng)) Then Begin
    If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    fname = pdir+mvn_qlook_filename('mag', tr, _extra=_extra)
    makepng, fname
Endif

Return
End
