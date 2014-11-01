;+
;PROCEDURE: 
;	mvn_swe_n1d
;PURPOSE:
;	Determines density from 1D energy spectra.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_n1d
;INPUTS: 
;KEYWORDS:
;   PANS:   Named variable to return tplot panels created.
;
;   DDD:    Calculate density from 3D distributions (allows bin
;           masking).  Typically lower cadence and coarser energy
;           resolution.
;
;   ABINS:  Anode bin mask -> 16 elements (0 = off, 1 = on)
;
;   DBINS:  Deflector bin mask -> 6 elements (0 = off, 1 = on)
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-28 10:20:22 -0700 (Tue, 28 Oct 2014) $
; $LastChangedRevision: 16052 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_n1d.pro $
;
;-

pro mvn_swe_n1d, pans=pans, ddd=ddd, abins=abins, dbins=dbins, mom=mom

  compile_opt idl2

  @mvn_swe_com

  mass = mass_e                    ; electron rest mass [eV/(km/s)^2]
  c1 = (mass/(2D*!dpi))^1.5D
  c2 = (2d5/(mass*mass))
  c3 = 4D*!dpi*1d-5*sqrt(mass/2D)  ; assume isotropic electron distribution
  
  if keyword_set(mom) then mom = 1 else mom = 0

; Get energy spectra from SPEC or 3D distributions

  if keyword_set(ddd) then begin

    if (data_type(swe_3d) ne 8) then begin
      print,"No 3D data."
      return
    endif
    if not keyword_set(abins) then abins = replicate(1B, 16)
    if not keyword_set(dbins) then dbins = replicate(1B, 6)
   
    t = swe_3d.time
    npts = n_elements(t)
    dens = fltarr(npts)
    temp = dens
    dsig = dens
    tsig = dens
    obins = reform(abins # dbins, 96)
    ondx = where(obins eq 1B, ocnt)
    onorm = float(ocnt)
    obins = replicate(1B, 64) # obins

    energy = fltarr(64, npts)
    eflux = energy
    cnts = energy
    sig2 = energy
    sc_pot = fltarr(npts)

    for i=0L,(npts-1L) do begin
      ddd = mvn_swe_get3d(t[i], units='counts')
      counts = ddd.data
      var = ddd.var
      ddd = conv_units(ddd,'eflux')
      
      energy[*,i] = ddd.energy[*,0]
      eflux[*,i] = total(ddd.data*obins,2)/onorm
      cnts[*,i] = total(counts*obins,2)
      sig2[*,i] = total(var*obins,2)
      sc_pot[i] = ddd.sc_pot
    endfor

  endif else begin

    if (data_type(mvn_swe_engy) ne 8) then mvn_swe_makespec

    t = mvn_swe_engy.time
    npts = n_elements(t)
    dens = fltarr(npts)
    temp = dens
    dsig = dens
    tsig = dens
  
    mvn_swe_convert_units, mvn_swe_engy, 'counts'
    cnts = mvn_swe_engy.data
    sig2 = mvn_swe_engy.var   ; variance w/ dig. noise

    mvn_swe_convert_units, mvn_swe_engy, 'eflux'    
    energy = mvn_swe_engy.energy
    eflux = mvn_swe_engy.data
    sc_pot = mvn_swe_engy.sc_pot
  endelse

  E = energy[*,0]
  dE = E
  dE[0] = abs(E[1] - E[0])
  for i=1,62 do dE[i] = abs(E[i+1] - E[i-1])/2.
  dE[63] = abs(E[63] - E[62])

  Emin = 2.*sc_pot

  sdev = eflux * (sqrt(sig2)/(cnts > 1.))

  for i=0L,(npts-1L) do begin
    F = eflux[*,i]
    S = sdev[*,i]
    j = where(E gt Emin[i], count)

    if (count gt 0L) then begin
      if (mom) then begin
        phi = sc_pot[i]
        if (n_elements(erange) gt 1) then begin
          Emin = min(erange, max=Emax)
          j = where((E ge Emin) and (E le Emax), n_e)
        endif else j = where(E gt phi, n_e)

        prat = (phi/E[j]) < 1.
        dens[i] = c3*total(dE[j]*sqrt(1. - prat)*(E[j]^(-1.5))*F[j])

        Fmax = max(F[j],k,/nan)
        Emax = E[j[k]]
        temp[i] = Emax/2.
        
      endif else begin
        p = swe_maxbol()
        p.pot = sc_pot[i]
        Fmax = max(F[j],k,/nan)
        Emax = E[j[k]]
        p.t = Emax/2.
        p.n = Fmax/(4.*c1*c2*sqrt(p.t)*exp((p.pot/p.t) - 2.))
        Elo = Emax*0.8 < ((Emax/2.) > Emin[i])
        j = where((E gt Elo) and (E lt Emax*3.))

        fit,E[j],F[j],dy=S[j],func='swe_maxbol',par=p,names='N T',p_sigma=sig,/silent

        j = where(E gt Emax*2.)
        E_halo = E[j]
        F_halo = F[j] - swe_maxbol(E_halo, par=p)
        prat = (p.pot/E_halo) < 1.

        N_halo = c3*total(dE[j]*sqrt(1. - prat)*(E_halo^(-1.5))*F_halo)

        dens[i] = p.n + N_halo
        temp[i] = p.t
      
        dsig[i] = sig[0]
        tsig[i] = sig[1]
      endelse
    endif else begin
      dens[i] = !values.f_nan
      temp[i] = !values.f_nan
    endelse
    
  endfor
  
; Create TPLOT variables

  if keyword_set(ddd) then mode = '3d' else mode = 'spec'
  dname = 'mvn_swe_' + mode + '_dens'
  tname = 'mvn_swe_' + mode + '_temp'

  ddata = {x:t, y:dens, dy:dsig, ytitle:'Ne [cm!u-3!n]'}
  store_data,dname,data=ddata
  options,dname,'ynozero',1

  tdata = {x:t, y:temp, dy:tsig, ytitle:'Te [eV]'}
  store_data,tname,data=tdata
  options,tname,'ynozero',1

  pans = [dname, tname]
  
  return

end
