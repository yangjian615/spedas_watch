;+
;NAME:
; mvn_gen_overplot
;PURPOSE:
; MAVEN PFP GEN Quicklook Plot
;CALLING SEQUENCE:
; mvn_gen_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      l0_input_file = l0_input_file, _extra=_extra
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
;           'mvn_gen_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; noload_data = If set, assume that all of the data is loaded, and
;               just plot.
;Quicklook Tplot Panels
;-------------------------
;STATIC
; variables:
;mvn_sta_C0_P1A_E
;mvn_sta_C6_P1D_M
;     mass spectrogram
;     energy spectrogram
;SWIA
;     energy spectrogram
;SWEA
;     energy spectrogram
;     pitch angle distribution (at 280 eV)
;SEP
;     energy line plot electrons
;     energy line plot ions
;LPW
;     wave power (LF+MF+HF)
;     IV-spectra+SC, potential+HTIME (see note)
;EUV
;     EUV diodes + temperature
;MAG
;     Bx, By, Bz, |B|
;     RMS panel
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-07-10 14:28:52 -0700 (Thu, 10 Jul 2014) $
; $LastChangedRevision: 15550 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_gen_overplot.pro $
;-
Pro mvn_gen_overplot, date = date, time_range = time_range, $
                      makepng=makepng, device = device, $
                      directory = directory, $
                      l0_input_file = l0_input_file, $
                      noload_data = noload_data, $
                      _extra=_extra

mvn_qlook_init, device = device

;First load the data, if requested
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else Begin
   filex = mvn_l0_db2file(date)
Endelse
If(~keyword_set(noload_data)) Then Begin
    mvn_load_all_qlook, l0_input_file = filex,  device = device, _extra=_extra
Endif
;Re-init here
mvn_qlook_init, device = device

;Create a sc potential variable to overplot
get_data, 'SC_pot', data = dddd
If(is_string(dddd)) Then Begin
    ndddd = n_elements(dddd)
    cj = 0
    For j = 0, ndddd-1 Do Begin
       get_data, dddd[j], data = dj
       If(is_struct(dj)) Then Begin
          If(cj Eq 0) Then Begin
             y = replicate(dj.y[0], n_elements(dj.y), ndddd)
             x = dj.x
             y[*, 0] = dj.y
          Endif Else y[*, j] = data_cut(dddd[j], x)
          cj = cj+1
       Endif 
    Endfor
    If(cj Gt 0) Then Begin
       y = total(temporary(y), 2)/float(ndddd)
       store_data, 'scpot_av', data = {x:x, y:y}
       cc = get_colors()
       swe_v1 = scpot_overlay('scpot_av', 'swe_espec', sc_line_color  = cc.white)
       if(is_string(swe_v1)) then begin ;if this fails, then options creates a structure
          options, swe_v1, 'yrange', [5.0, 5000.0]
          options, swe_v1, 'ystyle', 1
       endif else swe_v1 = 'swe_espec'
       swi_v = scpot_overlay('scpot_av', 'mvn_swis_en_counts', sc_line_color  = cc.white)
       if(is_string(swi_v)) then begin
          options, swi_v, 'yrange', [5.0, 50000.0]
          options, swi_v, 'ystyle', 1
       endif else swi_v = 'mvn_swis_en_counts'
    Endif Else Begin
       swe_v1 = 'swe_espec'
       swi_v = 'mvn_swis_en_counts'
    Endelse
Endif Else Begin
    swe_v1 = 'swe_espec'
    swi_v = 'mvn_swis_en_counts'
Endelse


varlist=[swe_v1, 'swe_pad', swi_v, 'mvn_sta_C0_P1A_E','mvn_sta_C6_P1D_M', $
         'mvn_SEPS_QL', 'mvn_lpw_euv_ql','mvn_lpw_wave_spec_ql', $
         'mvn_lpw_IV1_pasV2_ql','htime', 'mvn_ql_mag1']

;Set ytitle options here for each variable
options, swe_v1, 'ytitle', 'SWE!CE spec'
options, 'swe_pad', 'ytitle', 'SWE!CEPAD-280'
options, swi_v, 'ytitle', 'SWIA!CE spec'
options, 'mvn_lpw_spec_hf_pas', 'ytitle', 'LPW-HF'
options, 'mvn_lpw_spec_?f_pas', 'ysubtitle', '(Hz)'
options, 'mvn_lpw_spec_?f_pas', 'ztitle', 'Pwr(LSB)'
options, 'mvn_lpw_spec_hf_pas', 'ytitle', 'LPW-HF'
options, 'mvn_lpw_spec_mf_pas', 'ytitle', 'LPW-MF'
options, 'mvn_lpw_spec_lf_pas', 'ytitle', 'LPW-LF'
options, 'mvn_lpw_swp1_IV', 'ytitle', 'LPW!CSWP1'
options, 'mvn_lpw_euv', 'ytitle', 'EUV'
options, 'mvn_lpw_swp2_IV', 'ytitle', 'LPW!CSWP2'
options, 'htime', 'ytitle', 'HSBM'
options, 'mvn_lpw_euv_temp_C', 'ytitle', 'EUV-Temp'
options, 'mvn_lpw_euv_temp_C', 'ysubtitle', '(raw)'
options, 'mvn_lpw_euv', 'ysubtitle', '(raw)'
options, 'mvn_ql_mag1', 'ytitle', 'MAG-B1'


varlist = mvn_qlook_vcheck(varlist, tr = tr, /blankp)
If(varlist[0] Eq '')  Then Begin
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
tplot, varlist, title = 'MAVEN PFP Quicklook '+date

If(keyword_set(makepng)) Then Begin
    If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    p1  = strsplit(file_basename(filex), '_',/extract)
    d0 = time_double(time_string(p1[4]))
    tr = tr > d0
    fname = pdir+mvn_qlook_filename('pfp', tr, _extra=_extra)
    makepng, fname
Endif

Return
End