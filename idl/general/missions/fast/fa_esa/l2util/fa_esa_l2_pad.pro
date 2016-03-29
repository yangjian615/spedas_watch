;+
;NAME:
;fa_esa_l2_pad
;CALLING SEQUENCE:
;pdist = fa_esa_l2_pad(type)
;PURPOSE:
;Create FAST ESA pitch angle spectrum, from L2 input, callable from
;get_pa_spec.pro
;INPUT:
;type = one of ['ies', 'ees', 'ieb', 'eeb']
;OUTPUT:
;spec = tplot variable name for pitch angle spectra in the given energy range
;KEYWORDS: (all from get_pa_spec.pro, but the interpretation may be
;           different because there are no 'counts')
;       trange: A time range, if set takes precedence over t1 and t2
;               below, defaults to timerange()
;	T1:		start time, seconds since 1970, defaults to timerange()[0]
;	T2:		end time, seconds since 1970, defaults to timerange()[1]
;	ENERGY:		fltarr(2)		energy range to sum over
;	EBINRANGE:	intarr(2)		energy bin range to sum over
;	EBINS:		bytarr(dat.nenergy)	energy bins to sum over
;	gap_time: 	time gap big enough to signify a data gap 
;			(default 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	NAME:  		New name of the Data Quantity
;
;HISTORY:
; 2016-03-21, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-03-28 15:56:35 -0700 (Mon, 28 Mar 2016) $
; $LastChangedRevision: 20609 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2_pad.pro $
;-
Function fa_esa_l2_pad, type, $
                        T1=t1, $
                        T2=t2, $
                        ENERGY=energy, $
                        EBINRANGE=ebinrange, $
                        EBINS=ebins, $
                        gap_time=gap_time, $ 
                        no_data=no_data, $
                        name = name, $
                        _extra=_extra
;next define the common blocks
  common fa_information, info_struct

  typex = strlowcase(strcompress(/remove_all, type[0]))
  Case typex of
     'ies': Begin
        common fa_ies_l2, get_ind_ies, all_dat_ies
        all_dat = all_dat_ies
     End
     'ees': Begin
        common fa_ees_l2, get_ind_ees, all_dat_ees
        all_dat = all_dat_ees
     End
     'ieb': Begin
        common fa_ieb_l2, get_ind_ieb, all_dat_ieb
        all_dat = all_dat_ieb
     End
     'eeb': Begin
        common fa_eeb_l2, get_ind_eeb, all_dat_eeb
        all_dat = all_dat_eeb
     End
  Endcase

;One data type
  If(size(all_dat, /type) Ne 8) Then Begin
     message, /info, 'No '+typex+' Data structure'
     Return, ''
  Endif

;Get time intervals
  If(keyword_set(trange)) Then Begin
     tr = time_double(trange)
  Endif Else Begin
     If(keyword_set(t1) or keyword_set(t2)) Then Begin
        If(keyword_set(t1)) Then t1 = time_double(t1) Else Begin
           tr0 = timerange()
           t1 = time_double(tr0[0])
        Endelse
        If(keyword_set(t2)) Then t2 = time_double(t2) Else Begin
           tr0 = timerange()
           t2 = time_double(tr0[1])
        Endelse
        tr = [t1, t2]
     Endif Else tr = timerange()
  Endelse

  ntimes = n_elements(all_dat.time)
;Grab data in time range
  ss = where(all_dat.time Ge tr[0] And all_dat.time Lt tr[1], nss)
  If(nss Eq 0) Then Begin
     dprint, 'No '+typex+' data in time range: '
     print, time_string(tr)
     Return, ''
  Endif

;If nothing is set, then default to all bins, wt is a weight factor
  nbins = n_elements(all_dat.energy_full[0, *, 0])
  nab = n_elements(all_dat.energy_full[0, 0, *])
  wt = 1.0+fltarr(nbins, nab)

;If bins keywords are set, use them
  If(keyword_set(ebins)) Then Begin
     wt[*] = 0.0 & wt[ebins, *] = 1.0
  Endif
  If(keyword_set(ebinrange)) Then Begin
     ebr = minmax(ebinrange)
     nbd = ebr[1]-ebr[0]+1
     sbins = ebr[0]+indgen(nbd)
     wt[*] = 0.0 & wt[sbins, *] = 1.0
  Endif

;Use a loop
  eflux_out = fltarr(nss, na)
  pad_out = eflux_out
  For j = 0, nss-1 Do Begin
     efullj = all_dat.energy_full[ss[j], *, 0] > 0
     If(~keyword_set(energy)) Then Begin
        sbins = where(wt[*, 0] Gt 0, nsbins)
        dej = max(efullj[sbins])-min(efullj[sbins])
     Endif Else Begin
        wt[*] = 0.0
        sbins0 = where(efullj Gt energy[0] And $
                       efullj Lt energy[1], n0)
;The energy array is monotonically decreasing
        If(n0 Gt 0) Then Begin
           sbins1 = sbins0      ;will concatenate to this
           wt0 = 1.0+fltarr(n0)
;test to see if a partial bin is included. Note that etmp0 is the
;largest bin value fully included in the energy range, and etmp1 is
;the smallest.
           etmp0 = efullj[sbins0[0]]
           etmp1 = efullj[sbins0[n0-1]]
           If(sbins0[0] Gt 0) Then Begin
              If(energy[1] Gt etmp0) Then Begin
                 s1 = sbins0[0]-1
                 wt1 = (energy[1]-etmp0)/ $
                       (efullj[s1]-etmp0)
                 sbins1 = [s1, sbins0]
                 wt0 = [wt1, wt0]
              Endif
           Endif
           If(sbins0[n0-1] Lt nj-1) Then Begin
              If(energy[0] Lt etmp1) Then begin
                 s1 = sbins0[n0-1]+1
                 wt1 = (etmp1-energy[0])/ $
                       (etmp1-efullj[s1])
                 sbins1 = [sbins1, s1]
                 wt0 = [wt0, wt1]
              Endif
           Endif
           For k = 0, nab-1 Do wt[sbins1, k] = wt0
;Reset sbins variable
           sbins = where(wt[*, 0] Gt 0, nsbins)
;need the de for the given energy range
           dej = energy[1]-energy[0]
        Endif Else Begin
;Energy may be out of range
           If((erange[0] Gt efullj[0] And erange[1] Gt efullj[0]) Or $
              (erange[0] Lt efullj[nbins-1] And erange[1] Lt efullj[nbins-1])) Then Begin
              dprint, 'Energy range out of range: '
              print, erange
              Return, ''
           Endif Else Begin
              sbins = (min(where(erange[0] Gt efullj)) > 0) < nbins-1
              sbins = sbins[0]
              wt[sbins] = 1.0
              dej = all_dat.denergy_full[ss[j], sbins, 0]              
           Endelse
        Endelse
     Endelse
;contract eflux variable
     If(n_elements(sbins) Eq 1) Then Begin
        eflux_out[j, *] = reform(all_dat.eflux[ss[j], sbins[0], *])
        pad_out[j, *] = reform(all_dat.pitch_angle[ss[j], sbins[0], *])
     Endif Else Begin
        eflux_out[j, *] = total(reform(all_dat.eflux[ss[j], *, *]* $
                                       all_dat.denergy_full[ss[j], *, *])*wt)/dej
        pad_out[j, *] = total(reform(all_dat.pitch_angle[ss[j], *, *]* $
                                     all_dat.denergy_full[ss[j], *, *])*wt)/dej
     Endelse
  Endfor

;setup tplot variable
  If(is_string(name)) Then name_o_tplot = name $
  Else name_o_tplot = 'fa_'+typex+'_l2_pad'
  store_data, name_o_tplot, data = {x:(all_dat.time[ss]+all_dat.end_time[ss])/2,y:eflux_out,v:pad_out}
;  zlim,name_o_tplot, 1.e1, 1.e6, 1
;  ylim,name_o_tplot, 5., 40000., 1
  options, name_o_tplot, 'ztitle', 'Eflux PAD'
  options, name_o_tplot, 'ytitle',type+': eV'
  options, name_o_tplot, 'spec', 1
  options, name_o_tplot, 'x_no_interp', 1
  options, name_o_tplot, 'y_no_interp', 1
  options, name_o_tplot, datagap = 5

  Return, name_o_tplot
End
