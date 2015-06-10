;+
;NAME:
; thm_esa_test_dist2scpot
;PURPOSE:
; For a given probe and date, estimates the SC potential from PEER
; data, and plots it.
;CALLING SEQUENCE:
; thm_esa_test_dist2scpot, date, probe, no_init = no_init, $
;                          random_dp = random_dp, plot = plot
;INPUT:
; date = a date, e.g., '2008-01-05'
; probe = a probe, e.g., 'c'
;OUTPUT:
; a tplot variable 'th'+probe+'_est_scpot' is created
; If /random_dp is set, then date and probe are output 
;KEYWORDS:
; no_init = if set, do not read in a new set of data
; random_dp = if set, the input date and probe are randomized, note
;             that this keyword is unused if no_init is set.
; plot = if set, plot a comparison of the estimated sc_pot wht the
;        value obtained from the esa L2 cdf (originally from
;        thm_load_esa_pot)
;
;HISTORY:
; 31-may-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-06-08 12:48:28 -0700 (Mon, 08 Jun 2015) $
; $LastChangedRevision: 17829 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_test_dist2scpot.pro $

Pro thm_esa_test_dist2scpot, date, probe, no_init = no_init, random_dp = random_dp

  If(~keyword_set(no_init)) Then Begin
     del_data, '*'
     If(keyword_set(random_dp)) Then Begin
        probes = ['a', 'b', 'c', 'd', 'e']
        index = fix(5*randomu(seed))
        probe = probes[index]
;start in 2008
        t0 = time_double('2008-01-01')
        t1 = time_double(time_string(systime(/sec), /date))
        dt = t1-t0
        date = time_string(t0+dt*randomu(seed), /date)
     Endif
     sc = probe
     timespan, date
     print, 'date: ', date
     print, 'Probe: ', strupcase(sc)
     thm_load_esa_pkt, probe = sc
     thm_load_esa_pot, efi_datatype = 'mom', probe = sc
  Endif Else sc = probe

;Use peer data for this
  thx = 'th'+sc
  get_data, thx+'_peer_en_counts', data = dr
  If(~is_struct(dr)) Then Begin
     message, /info, 'No PEER data'
     Return
  Endif

  ntimes = n_elements(dr.x)
  scpot = fltarr(ntimes)
  For j = 0, ntimes-1 Do Begin
     t = dr.x[j]
     Case sc of
        'a': dj = get_tha_peer(t)
        'b': dj = get_thb_peer(t)
        'c': dj = get_thc_peer(t)
        'd': dj = get_thd_peer(t)
        'e': dj = get_the_peer(t)
     Endcase
     scpot[j] = thm_esa_dist2scpot(dj)
  Endfor

  store_data, thx+'_est_scpot', data = {x:dr.x, y:scpot}
;  options, thx+'_est_scpot', 'color', 6
;  store_data, thx+'_scpot_comp', data = thx+['_peer_sc_pot', '_est_scpot']
 
  If(keyword_set(plot)) Then Begin
     thm_spec_lim4overplot, thx+'_peer_en_counts', zlog = 1, ylog = 1, /overwrite, ymin = 2.0
     scpot_overlay1 = scpot_overlay(thx+'_peer_sc_pot', thx+'_peer_en_counts', sc_line_thick = 2.0, suffix = 'EST', /use_yrange)
     scpot_overlay2 = scpot_overlay(thx+'_est_scpot', thx+'_peer_en_counts', sc_line_thick = 2.0, /use_yrange)

     window, xs = 1024, ys = 1024
;  tplot, thx+['_peer_en_counts', '_scpot_comp']
     tplot, [scpot_overlay1, scpot_overlay2]
  Endif
End
