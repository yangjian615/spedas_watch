;+
;NAME:
; mvn_gen_multipng_plot
;PURPOSE:
; Creates full day, 6 hour and 2 hour png files for data for a given
; day, Note that the data must have already been plotted for this
; routine to work properly. It calls tplot without arguments.
;CALLING SEQUENCE:
; mvn_gen_multipng_plot, filename_proto, date, directory=directory
;INPUT:
; filename_in = the first part of the eventual filename, e.g.,
;               'mvn_pfp_ql_yyyymmdd'
;OUTPUT:
; png files, with names directory+filename_proto+yyddmm_hshf.png,
; where hshf refers to start and end hours for the plot.
;KEYWORDS:
; directory = the output directory, remember the trailing slash....
;HISTORY:
; Hacked from thm_gen_multipngplot, 15-oct-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-12-10 16:22:29 -0800 (Wed, 10 Dec 2014) $
; $LastChangedRevision: 16447 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_gen_multipngplot.pro $
;-
Pro mvn_gen_multipngplot, filename_in, directory = directory,  _extra = _extra

;Extract the date
  f0 = strsplit(file_basename(filename_in), '_', /extract)
  date0 = f0[n_elements(f0)-1]
  date = time_string(date0)
  year = strmid(date, 0, 4)
  month = strmid(date, 5, 2)
  day = strmid(date, 8, 2)
  ymd = year+month+day

  filename_proto = strjoin(f0[0:2], '_')

  date_double = time_double(date[0])
  if keyword_set(directory) then begin
    dir = directory[0]
    dir = strtrim(dir, 2)
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Ne '/' And ll Ne '\') Then dir = dir+'/'
  endif else dir = './'
;Full day plot
  tplot
;  makepng,dir+filename_proto+'_'+ymd+'_0024',/no_expose,_extra =
;  _extra
  makepng,dir+filename_proto+'_'+ymd,/no_expose,_extra = _extra
;six-hour plots
  For j = 0, 3 Do Begin
    hrs0 = 6*j
    hrs1 = 6*j+6
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    tplot, trange = tr0
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;two-hour plots
  For j = 0, 11 Do Begin
    hrs0 = 2*j
    hrs1 = 2*j+2
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    tplot, trange = tr0
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;reset the time range to the full day
  tlimit, 0, 0
  Return
End
