;+
;NAME:
; mvn_gen_multipng_plot
;PURPOSE:
; Creates full day, and single orbit plots 
; Note that the data must have already been plotted for this
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
; Hacked from thm_gen_multipngplot, 15-oct-2014, jmm,
; jimm@ssl.berkeley.edu
; Switched to plot singel orbit plots, 24-apr-2015, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-04-22 17:37:04 -0700 (Wed, 22 Apr 2015) $
; $LastChangedRevision: 17402 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_gen_multipngplot.pro $
;-
Pro mvn_gen_multipngplot, filename_in, directory = directory, _extra = _extra

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
  makepng,dir+filename_proto+'_'+ymd, /no_expose, _extra = _extra

;Orbit plots, filename_proto+'_'+orbit_number+'_'+yymmddhhmmss

; Get all orbits for this day
  get_data, 'mvn_orbnum', data = dorb
  If(~is_struct(dorb)) Then Begin
     orbdata = mvn_orbit_num()
     store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
                 dlimit={ytitle:'Orbit'}
     get_data, 'mvn_orbnum', data = dorb
  Endif
  norbits = n_elements(dorb.x)
  tr0 = date_double+[0.0d0, 86400.0d0]
  If(tr0[0] Ge dorb.x[0] And $
     tr0[1] Le dorb.x[norbits-1]) Then Begin
     o1 = max(where(dorb.x Le tr0[0]))
     o2 = min(where(dorb.x ge tr0[1]))
     tbins = dorb.x[o1:o2]
     onums = dorb.y[o1:o2-1]
     norb = n_elements(tbins)-1
     For j = 0, norb-1 Do Begin
        trj = tbins[j:j+1]
        tplot, trange = trj
        trjstr = time_string(trj[0], format=6)
        orbno = 'o'+string(onums[j], format = '(i5.5)')
        makepng, dir+filename_proto+'_'+orbno+'_'+trjstr, /no_expose, _extra = _extra
     Endfor
  Endif
;reset the time range to the full day
  tlimit, 0, 0
  Return
End
