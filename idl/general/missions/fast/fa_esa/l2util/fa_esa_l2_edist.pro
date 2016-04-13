;+
;NAME:
;fa_esa_l2_edist
;CALLING SEQUENCE:
;edist = fa_esa_l2_edist(type)
;PURPOSE:
;Create FAST ESA energy spectrum, from L2 input
;INPUT:
;type = one of ['ies', 'ees', 'ieb', 'eeb']
;OUTPUT:
;edist = tplot variable name for energy spectrum in the given pitch
;        angle range
;KEYWORDS: (all from get_pa_spec.pro, but the interpretation may be
;           different because there are no 'counts')
;       trange: A time range, if set takes precedence over t1 and t2
;               below, defaults to timerange()
;	T1:		start time, seconds since 1970, defaults to timerange()[0]
;	T2:		end time, seconds since 1970, defaults to timerange()[1]
;	PARANGE:		fltarr(2)		pitch angle range to sum over
;	gap_time: 	time gap big enough to signify a data gap 
;			(default 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	NAME:  		New name of the Data Quantity
;
;HISTORY:
; 2016-04-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-04-12 14:57:35 -0700 (Tue, 12 Apr 2016) $
; $LastChangedRevision: 20788 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2_edist.pro $
;-
Function fa_esa_l2_edist, type, $
                          T1=t1, $
                          T2=t2, $
                          parange=parange, $
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

;Use a loop
  eflux_out = fltarr(nss, nbins)
  energy_out = eflux_out
  For j = 0, nss-1 Do Begin
;Since the pitch angle varies with energy, you'll need a loop
;over energy
     For k = 0, nbins-1 Do Begin
        If(keyword_set(parange)) Then Begin
           pajk = reform(all_dat.pitch_angle[ss[j], k, *])
;pitch angle wraps, so sort
           pajk = pajk[where(pajk Gt 0, njk)] ;dump fill values
           ssjk = sort[pajk]
           xxx = where(parange Gt 360, nxxx)
           If(nxxx Gt 0) Then parange[xxx]=parange[xxx] mod 360.0
           yyy = where(parange Lt 0, nyyy)
           If(nyyy gt 0) Then parange[yyy]=parange[yyy]+360.0

           s1 = value_locate(pajk, parange)
           If(s1[1] Eq s1[0]) Then Begin
              wt[k, ssjk[s1[0]]] = 1.0
           Endif Else Begin
              wtf = wt[k, *]
              pajk2 = [pajk, 360.0+pajk] ;use this because of wrapping
              If(s1[1] Gt s1[0]) Then Begin
                 wtf[s1[0]:s1[1]] = 1.0
              Endif Else Begin ;here it's tricky
                 wtf[s1[0]:*] = 1.0
                 wtf[0:s1[1]] = 1.0
              Endelse
;The first bin may be partial
              If(pajk2[s1[0]] Eq parange[0]) Then wts10 = 1.0 $
              Else wts10 = (pajk2[i+1]-parange[0])/(pajk2[i+1]-pajk2[i])
              wtf[s1[0]] = wts10
;There may be an extra partial bin after s1[1]
              If(parange[1] Gt pajk2[s1[1]]) Then Begin
                 wts11 = (parange[1]-pajk2[s1[1]])/(pajk2[s1[1]+1]-pajk2[s1[1]])
                 If(s1[1] Eq njk-1) Then wtf[0] = wts11 $
                 Else wtf[s1[1]+1] = wts11
              Endif
           Endelse
;unsort
           wt[k, ssjk] = wtf
        Endif
     Endfor
;contract eflux variable
     eflux_out[j, *] = total(reform(all_dat.eflux[ss[j], *, *]* $
                                    all_dat.domega[ss[j], *, *])*wt)
     energy_out[j, *] = all_dat.energy_full[aa[j], *, 0]
  Endfor

;setup tplot variable
  If(is_string(name)) Then name_o_tplot = name $
  Else name_o_tplot = 'fa_'+typex+'_l2_edist'
  store_data, name_o_tplot, data = {x:(all_dat.time[ss]+all_dat.end_time[ss])/2,y:eflux_out,v:energy_out}
;  zlim,name_o_tplot, 1.e1, 1.e6, 1
;  ylim,name_o_tplot, 5., 40000., 1
  options, name_o_tplot, 'ztitle', 'Eflux'
  options, name_o_tplot, 'ytitle',type+': eV'
  options, name_o_tplot, 'spec', 1
  options, name_o_tplot, 'x_no_interp', 1
  options, name_o_tplot, 'y_no_interp', 1
  options, name_o_tplot, datagap = 5

  Return, name_o_tplot
End
