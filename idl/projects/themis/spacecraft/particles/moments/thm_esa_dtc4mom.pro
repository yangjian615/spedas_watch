;just a messy helper function to set the dead time value in ESA common
;blocks to 0
Pro temp_set_dead0, sc, mode, iflag, eflag, unset = unset

;All of the ESA common blocks defined
  common tha_454, tha_454_ind, tha_454_dat
  common tha_455, tha_455_ind, tha_455_dat
  common tha_456, tha_456_ind, tha_456_dat
  common tha_457, tha_457_ind, tha_457_dat
  common tha_458, tha_458_ind, tha_458_dat
  common tha_459, tha_459_ind, tha_459_dat

  common thb_454, thb_454_ind, thb_454_dat
  common thb_455, thb_455_ind, thb_455_dat
  common thb_456, thb_456_ind, thb_456_dat
  common thb_457, thb_457_ind, thb_457_dat
  common thb_458, thb_458_ind, thb_458_dat
  common thb_459, thb_459_ind, thb_459_dat

  common thc_454, thc_454_ind, thc_454_dat
  common thc_455, thc_455_ind, thc_455_dat
  common thc_456, thc_456_ind, thc_456_dat
  common thc_457, thc_457_ind, thc_457_dat
  common thc_458, thc_458_ind, thc_458_dat
  common thc_459, thc_459_ind, thc_459_dat

  common thd_454, thd_454_ind, thd_454_dat
  common thd_455, thd_455_ind, thd_455_dat
  common thd_456, thd_456_ind, thd_456_dat
  common thd_457, thd_457_ind, thd_457_dat
  common thd_458, thd_458_ind, thd_458_dat
  common thd_459, thd_459_ind, thd_459_dat

  common the_454, the_454_ind, the_454_dat
  common the_455, the_455_ind, the_455_dat
  common the_456, the_456_ind, the_456_dat
  common the_457, the_457_ind, the_457_dat
  common the_458, the_458_ind, the_458_dat
  common the_459, the_459_ind, the_459_dat

  common saved_dead_values, ion_dead, el_dead
  If(keyword_set(unset)) Then Begin
    Case sc Of
      'a':Begin
        Case mode Of
          'f':Begin
            If(is_struct(tha_454_dat)) Then tha_454_dat.dead = ion_dead
            If(is_struct(tha_457_dat)) Then tha_457_dat.dead = el_dead
          End
          'r':Begin
            If(is_struct(tha_455_dat)) Then tha_455_dat.dead = ion_dead
            If(is_struct(tha_458_dat)) Then tha_458_dat.dead = el_dead
          End
          'b':Begin
            If(is_struct(tha_456_dat)) Then tha_456_dat.dead = ion_dead
            If(is_struct(tha_459_dat)) Then tha_459_dat.dead = el_dead
          End
        Endcase
      End
      'b':Begin
        Case mode Of
          'f':Begin
            If(is_struct(thb_454_dat)) Then thb_454_dat.dead = ion_dead
            If(is_struct(thb_457_dat)) Then thb_457_dat.dead = el_dead
          End
          'r':Begin
            If(is_struct(thb_455_dat)) Then thb_455_dat.dead = ion_dead
            If(is_struct(thb_458_dat)) Then thb_458_dat.dead = el_dead
          End
          'b':Begin
            If(is_struct(thb_456_dat)) Then thb_456_dat.dead = ion_dead
            If(is_struct(thb_459_dat)) Then thb_459_dat.dead = el_dead
          End
        Endcase
      End
      'c':Begin
        Case mode Of
          'f':Begin
            If(is_struct(thc_454_dat)) Then thc_454_dat.dead = ion_dead
            If(is_struct(thc_457_dat)) Then thc_457_dat.dead = el_dead
          End
          'r':Begin
            If(is_struct(thc_455_dat)) Then thc_455_dat.dead = ion_dead
            If(is_struct(thc_458_dat)) Then thc_458_dat.dead = el_dead
          End
          'b':Begin
            If(is_struct(thc_456_dat)) Then thc_456_dat.dead = ion_dead
            If(is_struct(thc_459_dat)) Then thc_459_dat.dead = el_dead
          End
        Endcase
      End
      'd':Begin
        Case mode Of
          'f':Begin
            If(is_struct(thd_454_dat)) Then thd_454_dat.dead = ion_dead
            If(is_struct(thd_457_dat)) Then thd_457_dat.dead = el_dead
          End
          'r':Begin
            If(is_struct(thd_455_dat)) Then thd_455_dat.dead = ion_dead
            If(is_struct(thd_458_dat)) Then thd_458_dat.dead = el_dead
          End
          'b':Begin
            If(is_struct(thd_456_dat)) Then thd_456_dat.dead = ion_dead
            If(is_struct(thd_459_dat)) Then thd_459_dat.dead = el_dead
          End
        Endcase
      End
      'e':Begin
        Case mode Of
          'f':Begin
            If(is_struct(the_454_dat)) Then the_454_dat.dead = ion_dead
            If(is_struct(the_457_dat)) Then the_457_dat.dead = el_dead
          End
          'r':Begin
            If(is_struct(the_455_dat)) Then the_455_dat.dead = ion_dead
            If(is_struct(the_458_dat)) Then the_458_dat.dead = el_dead
          End
          'b':Begin
            If(is_struct(the_456_dat)) Then the_456_dat.dead = ion_dead
            If(is_struct(the_459_dat)) Then the_459_dat.dead = el_dead
          End
        Endcase
      End
    Endcase
  Endif Else Begin
    iflag = 1b & eflag = 1b
    Case sc Of
      'a':Begin
        Case mode Of
          'f':Begin
            If(is_struct(tha_454_dat)) Then Begin
              ion_dead = tha_454_dat.dead
              tha_454_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(tha_457_dat)) Then Begin
              el_dead = tha_457_dat.dead
              tha_457_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'r':Begin
            If(is_struct(tha_455_dat)) Then Begin
              ion_dead = tha_455_dat.dead
              tha_455_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(tha_458_dat)) Then Begin
              el_dead = tha_458_dat.dead
              tha_458_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'b':Begin
            If(is_struct(tha_456_dat)) Then Begin
              ion_dead = tha_456_dat.dead
              tha_456_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(tha_459_dat)) Then Begin
              el_dead = tha_459_dat.dead
              tha_459_dat.dead = 0.0
            Endif Else eflag = 0b
          End
        Endcase
      End
      'b':Begin
        Case mode Of
          'f':Begin
            If(is_struct(thb_454_dat)) Then Begin
              ion_dead = thb_454_dat.dead
              thb_454_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thb_457_dat)) Then Begin
              el_dead = thb_457_dat.dead
              thb_457_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'r':Begin
            If(is_struct(thb_455_dat)) Then Begin
              ion_dead = thb_455_dat.dead
              thb_455_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thb_458_dat)) Then Begin
              el_dead = thb_458_dat.dead
              thb_458_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'b':Begin
            If(is_struct(thb_456_dat)) Then Begin
              ion_dead = thb_456_dat.dead
              thb_456_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thb_459_dat)) Then Begin
              el_dead = thb_459_dat.dead
              thb_459_dat.dead = 0.0
            Endif Else eflag = 0b
          End
        Endcase
      End
      'c':Begin
        Case mode Of
          'f':Begin
            If(is_struct(thc_454_dat)) Then Begin
              ion_dead = thc_454_dat.dead
              thc_454_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thc_457_dat)) Then Begin
              el_dead = thc_457_dat.dead
              thc_457_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'r':Begin
            If(is_struct(thc_455_dat)) Then Begin
              ion_dead = thc_455_dat.dead
              thc_455_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thc_458_dat)) Then Begin
              el_dead = thc_458_dat.dead
              thc_458_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'b':Begin
            If(is_struct(thc_456_dat)) Then Begin
              ion_dead = thc_456_dat.dead
              thc_456_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thc_459_dat)) Then Begin
              el_dead = thc_459_dat.dead
              thc_459_dat.dead = 0.0
            Endif Else eflag = 0b
          End
        Endcase
      End
      'd':Begin
        Case mode Of
          'f':Begin
            If(is_struct(thd_454_dat)) Then Begin
              ion_dead = thd_454_dat.dead
              thd_454_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thd_457_dat)) Then Begin
              el_dead = thd_457_dat.dead
              thd_457_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'r':Begin
            If(is_struct(thd_455_dat)) Then Begin
              ion_dead = thd_455_dat.dead
              thd_455_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thd_458_dat)) Then Begin
              el_dead = thd_458_dat.dead
              thd_458_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'b':Begin
            If(is_struct(thd_456_dat)) Then Begin
              ion_dead = thd_456_dat.dead
              thd_456_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(thd_459_dat)) Then Begin
              el_dead = thd_459_dat.dead
              thd_459_dat.dead = 0.0
            Endif Else eflag = 0b
          End
        Endcase
      End
      'e':Begin
        Case mode Of
          'f':Begin
            If(is_struct(the_454_dat)) Then Begin
              ion_dead = the_454_dat.dead
              the_454_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(the_457_dat)) Then Begin
              el_dead = the_457_dat.dead
              the_457_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'r':Begin
            If(is_struct(the_455_dat)) Then Begin
              ion_dead = the_455_dat.dead
              the_455_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(the_458_dat)) Then Begin
              el_dead = the_458_dat.dead
              the_458_dat.dead = 0.0
            Endif Else eflag = 0b
          End
          'b':Begin
            If(is_struct(the_456_dat)) Then Begin
              ion_dead = the_456_dat.dead
              the_456_dat.dead = 0.0
            Endif Else iflag = 0b
            If(is_struct(the_459_dat)) Then Begin
              el_dead = the_459_dat.dead
              the_459_dat.dead = 0.0
            Endif Else eflag = 0b
          End
        Endcase
      End
    Endcase
  Endelse
End
        
;+
;NAME:
; thm_esa_dtc4mom
;PURPOSE:
; calculates a dead-time correction value for ESA particle moments,
; which then can be applied to on-board MOM data.
;CALLING SEQUENCE:
; thm_esa_dtc4mom, probe=probe, trange=trange
;INPUT:
; All via keyword
;OUTPUT:
; None explicit, a number of tplot variables are created.
;KEYWORDS:
; probe='a','b','c','d' or 'e'
; trange = an input time range, otherwise the current time range is
;          used.
; noload = if set, make the assumption that the data is there, and
;          don't load it
; use_esa_mode = 'f','r', or 'b', use this mode for the ESA data to get
;                the dead time correction, the default is 'f'
; scpot_correct = if set, use thm_load_esa_pot to correct for SC
;                 potential in moments. The default is to avoid the correction
;HISTORY:
; 10-may-2011, jmm, jimm@ssl.berkeley.edu
; 27-may-2011, jmm, This version deletes the temporary ESA moments
; $LastChangedBy: aaflores $
; $LastChangedDate: 2013-09-10 12:07:56 -0700 (Tue, 10 Sep 2013) $
; $LastChangedRevision: 13010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_esa_dtc4mom.pro $
;-

Pro thm_esa_dtc4mom, probe = probe, trange = trange, noload = noload, $
                     use_esa_mode = use_esa_mode, scpot_correct = scpot_correct, $
                     out_suffix = out_suffix, keep_temp_moments = keep_temp_moments, $
                     no_despike = no_despike, nsig_despike = nsig_despike, _extra = _extra

  thm_init                      ;this program can be called at start
  vprobes = ['a', 'b', 'c', 'd', 'e']
  If(keyword_set(probe)) Then Begin
    probes = thm_check_valid_name(strlowcase(probe), vprobes, /include_all)
    If(is_string(probes) Eq 0) Then Begin
      dprint, 'No valid probe input: '+probe
      Return
    Endif
  Endif Else probes = vprobes

  If(keyword_set(trange) && n_elements(trange) Eq 2) $
    Then tr = timerange(trange) Else tr = timerange()

  If(is_string(use_esa_mode)) Then Begin
    mode = strlowcase(strcompress(use_esa_mode, /remove_all))
  Endif Else mode = 'f'

  Case mode Of
    'f': datat = ['peif', 'peef']
    'r': datat = ['peir', 'peer']
    'b': datat = ['peib', 'peeb']
    Else: Begin
      dprint, "Please use 'f', 'r', or 'b' for mode, Setting mode to 'f'"
      datat = ['peif', 'peef']
    End
  Endcase

  If(n_elements(trange) Eq 2) Then tr0 = time_double(trange) $
  Else tr0 = timerange()        ;should be defined already, since this is only called after MOM data is loaded
;set this to get through the ESA data load
  timespan, tr0[0], tr0[1]-tr0[0], /seconds

  If(keyword_set(out_suffix)) Then osfx = out_suffix Else osfx = ''
;ii are the instrument types for MOM data, vv are the different
;moments that will need to be dealt with
  ii = ['peim', 'peem']
  vv = ['density', 'flux', 'mftens', 'eflux', 'velocity', $
        'ptens', 'ptot']

;for each probe
  np = n_elements(probes)
  For j = 0, np-1 Do Begin
    sc = probes[j] & thx = 'th'+sc
;here check to see if the appropriate data has been loaded, and load
;if necessary
    have_i_data = thm_part_check_trange(sc, datat[0], tr0)
    have_e_data = thm_part_check_trange(sc, datat[1], tr0)
    If(~keyword_set(noload)) Then Begin
        If(have_i_data Eq 0) Then thm_load_esa_pkt, probe = sc, trange = tr0, datatype = datat[0], $
           suffix = '_temp4dtc'
        If(have_e_data Eq 0) Then thm_load_esa_pkt, probe = sc, trange = tr0, datatype = datat[1], $
           suffix = '_temp4dtc'
    Endif
;Set dead time to zero
    temp_set_dead0, sc, mode, iflag, eflag
;you need the potential for the moments
    If(keyword_set(scpot_correct)) Then Begin
      If((sc Eq 'b') And $
         (time_double(tr[0]) Gt time_double('2010-10-13'))) Then Begin
        thm_load_esa_pot, sc = sc, datatype = 'mom'
      Endif Else thm_load_esa_pot, sc = sc
      scpot_suffix = '_esa_pot'
    Endif Else scpot_suffix = ''
;now get moments - without dead time corrections
    For i = 0, 1 Do Begin
      If(i Eq 0) Then flag = iflag Else flag = eflag
      If(flag) Then Begin
        thm_part_moments, probe = sc, instrument = datat[i], $
          scpot_suffix = scpot_suffix, moments = vv, tplotsuffix = '_temp4dtc_0'
;'ptot' variable
        get_data, thx+'_'+datat[i]+'_ptens_temp4dtc_0', data = ptd, dlimits = dl
        If(is_struct(ptd)) Then Begin
          ptot = total(ptd.y[*, 0:2], 2)/3.0
          store_data, thx+'_'+datat[i]+'_ptot_temp4dtc_0', data = {x:ptd.x, y:ptot}, $
            dlimits = dl
        Endif
      Endif
    Endfor
;Reset the dead times
    temp_set_dead0, sc, mode, /unset
;now get moments - with dead time corrections
    For i = 0, 1 Do Begin
      If(i Eq 0) Then flag = iflag Else flag = eflag
      If(flag) Then Begin
        thm_part_moments, probe = sc, instrument = datat[i], $
          scpot_suffix = scpot_suffix, moments = vv, tplotsuffix = '_temp4dtc'
;'ptot' variable
        get_data, thx+'_'+datat[i]+'_ptens_temp4dtc', data = ptd, dlimits = dl
        If(is_struct(ptd)) Then Begin
          ptot = total(ptd.y[*, 0:2], 2)/3.0
          store_data, thx+'_'+datat[i]+'_ptot_temp4dtc', data = {X:ptd.x, y:ptot}, $
            dlimits = dl
        Endif
      Endif
    Endfor

    ;;; Calling tplot_force_monotonic to repair repeats in tplot variables *_temp4dtc
    tplot_force_monotonic,'*_temp4dtc',/forward

;Now get corrections
    If(keyword_set(nsig_despike)) Then nsg = nsig_despike Else nsg = 0.5
    vv = [vv, 'ptot']
    If(iflag) Then Begin
      tvars = thx+'_'+datat[0]+'_'+vv+'_temp4dtc'
      tvars0 = tvars+'_0'
      tvars_dtc = thx+'_'+datat[0]+'_'+vv+'_dtc'+osfx
      For k = 0, n_elements(vv)-1 Do Begin
        get_data, tvars[k], data = dd
        get_data, tvars0[k], data = dd0
        dtc = dd.y/dd0.y
;despike dtc
        If(~keyword_set(no_despike)) Then Begin
            ndim = n_elements(dtc[0,*])
            For ll = 0, ndim -1 Do Begin
                flag = dydt_spike_test(dd.x-dd.x[0], abs(dtc[*, ll]), nsig = nsg)
                spike_ss = where(flag Eq 1, nspike) & ok_ss = where(flag Eq 0, nok)
                If(nok Lt 3) Then Begin
                    dprint, dlevel=2, 'Data for '+thx+datat[0]+'_'+vv[k]+' is all spikes, '+$
                      'suggests larger value of nsig_despike needed. Not despiking'
                Endif Else Begin
                    If(nspike Gt 0) Then Begin ;interpolate over spike values
                        dtc[*,ll] = interpol(dtc[ok_ss,ll], dd.x[ok_ss], dd.x)
                    Endif 
                Endelse
            Endfor
        Endif
        store_data, tvars_dtc[k], data = {x:dd.x, y:dtc}
      Endfor
    Endif
    If(eflag) Then Begin
      tvars = thx+'_'+datat[1]+'_'+vv+'_temp4dtc'
      tvars0 = tvars+'_0'
      tvars_dtc = thx+'_'+datat[1]+'_'+vv+'_dtc'+osfx
      For k = 0, n_elements(vv)-1 Do Begin
        get_data, tvars[k], data = dd
        get_data, tvars0[k], data = dd0
        dtc = dd.y/dd0.y
 ;despike dtc
        If(~keyword_set(no_despike)) Then Begin
            ndim = n_elements(dtc[0,*])
            For ll = 0, ndim -1 Do Begin
                flag = dydt_spike_test(dd.x-dd.x[0], abs(dtc[*, ll]), nsig = nsg)
                spike_ss = where(flag Eq 1, nspike) & ok_ss = where(flag Eq 0, nok)
                If(nok Lt 3) Then Begin
                    dprint, dlevel=2, 'Data for '+thx+datat[1]+'_'+vv[k]+' is all spikes, '+$
                      'suggests larger value of nsig_despike needed. Not despiking'
                Endif Else Begin
                    If(nspike Gt 0) Then Begin ;interpolate over spike values
                        dtc[*,ll] = interpol(dtc[ok_ss,ll], dd.x[ok_ss], dd.x)
                    Endif 
                Endelse
            Endfor
        Endif
       store_data, tvars_dtc[k], data = {x:dd.x, y:dtc}
      Endfor
    Endif
;Delete temporary moments
    If(~keyword_set(keep_temp_moments)) Then Begin
        del_data, '*_temp4dtc'
        del_data, '*_temp4dtc_0'
    Endif
    options, thx+'*_dtc'+osfx, 'ynozero', 1
  Endfor
  Return
End
