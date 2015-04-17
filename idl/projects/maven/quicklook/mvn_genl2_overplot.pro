;+
;NAME:
; mvn_genl2_overplot
;PURPOSE:
; MAVEN PFP GEN Quicklook Plot
;CALLING SEQUENCE:
; mvn_genl2_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      l0_input_file = l0_input_file, multipngplot = multipngplot, $
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
;           'mvn_gen_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; noload_data = If set, assume that all of the data is loaded, and
;               just plot.
; multipngplot = if set, then make multiple plots of 2 and 6 hour
;               duration, in addition to the regular png plot
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
;NGIMS
;     CSN, OSNT, OSNB, OSI
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; CHanged to use thara's mvn_pl_pfp_tplot.pro, 2015-04-14, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-04-15 15:47:19 -0700 (Wed, 15 Apr 2015) $
; $LastChangedRevision: 17333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_genl2_overplot.pro $
;-
Pro mvn_genl2_overplot, orbit_number = orbit_number, $
                        date = date, time_range = time_range, $
                        makepng=makepng, device = device, $
                        directory = directory, $
                        multipngplot = multipngplot, $
                        _extra=_extra

  mvn_qlook_init, device = device

;First load the data
;Orbit number
  orbdata = mvn_orbit_num()
  If(keyword_set(orbit_number)) Then Begin
     orb_range = minmax(orbit_number)
     If(n_elements(orbit_number) Eq 1) Then orb_range[1]=orb_range[1]+1
     tr0 = interpol(orbdata.peri_time, orbdata.num, orb_range)
  Endif Else If(keyword_set(time_range)) Then Begin
     tr0 = time_double(time_range) & tr0x = tr0
  Endif Else If(keyword_set(date)) Then Begin
     tr0 = time_double(date)+[0.0d0, 86400.0d0] & tr0x = tr0
  Endif Else Begin
     dprint, 'Need orbit_number, date or time_range input keywords set'
     Return
  Endelse

  mvn_ql_pfp_tplot, tr0

;In the mvn_ql_pfp_tplot program, bvec may be one of two variables
  get_data, 'mvn_mag_l1_bmso_1sec', data = dddb
  If(is_struct(dddb)) Then bvec = 'mvn_mag_l1_bmso_1sec' $
  Else bvec = 'mvn_mag_l1_bpl_1sec'

;Re-init here
  mvn_qlook_init, device = device

;Get a burst_data_bar
  mvn_bb = mvn_qlook_burst_bar(tr0[0], (tr0[1]-tr0[0])/86400.0d0, /outline, /from_l2)
  varlist = ['mvn_sep1_B-O_Eflux_Energy', 'mvn_sep2_B-O_Eflux_Energy', $
             'mvn_sta_c0_e', 'mvn_sta_c6_m', 'mvn_swis_en_eflux', $
             'mvn_swe_etspec', 'mvn_mag_bamp', bvec, 'alt2', mvn_bb]

  varlist = mvn_qlook_vcheck(varlist, tr = tr, /blankp)
  If(varlist[0] Eq '')  Then Begin
     dprint, 'No data, Returning'
     Return
  Endif

;load orbit data into a tplot variable
  store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
              dlimit={ytitle:'Orbit'}

;Remove gap between plot panels
  tplot_options, 'ygap', 0.0d0

;Get the date-time range
  d0 = time_string(tr0[0])
  d1 = time_string(tr0[1])

;plot the data
  tplot, varlist, title = 'MAVEN PFP Quicklook '+d0+'-'+d1, var_label = 'mvn_orbnum'
  tlimit, tr0[0], tr0[1]

  If(keyword_set(multipngplot) && keyword_set(date)) Then makepng = 1b
  If(keyword_set(makepng)) Then Begin
     If(keyword_set(directory)) Then pdir = directory Else pdir = './'
     fname = pdir+mvn_qlook_filename('pfp', tr, _extra=_extra)
     If(keyword_set(multipngplot) && keyword_set(date)) Then mvn_gen_multipngplot, fname, directory = pdir $
     Else makepng, fname
  Endif

  Return
End
