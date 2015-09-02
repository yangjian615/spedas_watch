;+
;NAME:
; fa_load_esa_l2
;PURPOSE:
; Loads MVN FAST ESA L2 data for a given file(s), or time_range
;CALLING SEQUENCE:
; fa_load_esa_l2, files = files, trange=trange, sta_apid=sta_apid
;INPUT:
; All via keyword, if none are set, then the output of timerange() is
; used, which may prompt for a time interval
;KEYWORDS:
; datatype, type = ['ies','ieb', 'ees', 'eeb' ] is the default
; files = if set, then read from these files, otherwise, files are
;         figured out from the time range. Full path
;         please. Also,please use the same datatype
;  trange = read in the data from this time range, note that if both
;          files and time range are set, files takes precedence in
;          finding files.
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection.
;OUTPUT:
; No variables, data are loaded into common blocks
;HISTORY:
; 1-sep-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-09-01 11:34:22 -0700 (Tue, 01 Sep 2015) $
; $LastChangedRevision: 18683 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/cdf_load/fa_load_esa_l2.pro $
;-
Pro fa_load_esa_l2, datatype = datatype, type = type, $
   files = files, trange = trange, $
   no_time_clip = no_time_clip, $
   _extra = _extra

;fa_esa_init, initializes a system variable
  fa_esa_init
;Keep track of software versioning here
  sw_vsn = fa_esa_current_sw_version()
  sw_vsn_str = 'v'+string(sw_vsn, format='(i2.2)')

;The first step is to set up filenames, if there are any
  If(keyword_set(files)) Then Begin
     filex = file_search(files)
     If(~is_string(filex)) Then Begin
        dprint, 'No files:'+files
        Return
     Endif
  Endif Else Begin
     If(keyword_set(datatype)) Then Begin
        type = datatype
     Endif Else Begin
        If(~keyword_set(type)) then type=['ees','ies','eeb','ieb']
     Endelse
;Recursive call for different types
     If(n_elements(type) Gt 1) Then Begin
        For j = 0, n_elements(type)-1 Do fa_load_esa_l2, type=type[j], $
           trange = trange, no_time_clip = no_time_clip, _extra = _extra
        Return
     Endif
;Here we are loading one datatype now
     type = strlowcase(strcompress(/remove_all, type[0]))
     tr0 = timerange(trange)
;Need orbits, hacked from fa_load_esa_l1.pro
     start_orbit = long(fa_time_to_orbit(tr0[0]))
     end_orbit = long(fa_time_to_orbit(tr0[1]))
     orbits = indgen(end_orbit-start_orbit+1)+start_orbit
     orbits_str = strcompress(string(orbits,format='(i05)'), /remove_all)
     orbit_dir = strmid(orbits_str,0,2)+'000'
     relpathnames='l2/'+type+'/'+orbit_dir+'/fa_l2_'+type+'_'+orbits_str+'_'+vxx+'.cdf'
     filex=file_retrieve(relpathnames,_extra = !fast)
;Only files that exist here
     filex = file_search(filex)
     If(~is_string(filex)) Then Begin
        dprint, 'No files found for time range and type:'+type
        Return
     Endif
  Endelse

;Only unique files here
  filex_u = filex[bsort(filex)]
  filex = filex_u[uniq(filex_u)]
;Ok, load the files
  nfiles = n_elements(filex)
  dat = -1
  ck = 0
  For j = 0, nfiles-1 Do Begin
     datj = fa_esa_cmn_l2read(filex[j])
     If(is_struct(datj)) Then Begin
        If(~is_struct(dat)) Then dat = temporary(datj) $
        Else dat = fa_esa_cmn_concat(temporary(dat), temporary(datj))
     Endif
  Endfor
;Check time range
  If(~keyword_set(files) and ~keyword_set(no_time_clip)) Then Begin
     If(is_struct(dat)) Then dat = fa_esa_cmn_tclip(dat, tr0) $
     Else Begin
        dprint, 'No data for type: '+type[0]
     Endelse
  Endif
;Which type?
  Case type[0] of
     'ies': Begin
        common fa_ies_l2, get_ind_ies, all_dat_ies
        all_dat_ies = dat & get_ind_ies = 0L
     End
     'ees': Begin
        common fa_ees_l2, get_ind_ees, all_dat_ees
        all_dat_ees = dat & get_ind_ees = 0L
     End
     'ieb': Begin
        common fa_ieb_l2, get_ind_ieb, all_dat_ieb
        all_dat_ieb = dat & get_ind_ieb = 0L
     End
     'eeb': Begin
        common fa_eeb_l2, get_ind_eeb, all_dat_eeb
        all_dat_eeb = dat & get_ind_eeb = 0L
     End
  Endcase

  Return
End
