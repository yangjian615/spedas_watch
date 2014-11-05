;+
;PROCEDURE: 
;	mvn_swe_kp
;PURPOSE:
;	Calculates SWEA key parameters.  The result is stored in tplot variables,
;   and as a save file.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_kp, trange
;INPUTS: 
;	TRANGE:    Time range for processing.
;
;KEYWORDS:
;   PANS:      Named variable to return tplot variables created
;
;   MOM:       Calculate density using a moment.
;
;   DDD:       Calculate density from 3D distributions (allows bin
;              masking).  Default is to use SPEC data.  This option fits
;              a Maxwell-Boltzmann distribution to the core and performs
;              a moment calculation for the halo.  This provides corrections
;              for both spacecraft potential and scattered photoelectrons.
;
;   ABINS:     Anode bin mask - 16-element byte array (0 = off, 1 = on)
;              (Only effective if DDD is set.)
;
;   DBINS:     Deflector bin mask - 6-element byte array (0 = off, 1 = on)
;              (Only effective if DDD is set.)
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-11-02 14:53:27 -0800 (Sun, 02 Nov 2014) $
; $LastChangedRevision: 16116 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_kp.pro $
;
;-

pro mvn_swe_kp, trange, pans=pans, ddd=ddd, abins=abins, dbins=dbins, obins=obins, mom=mom

  compile_opt idl2

  @mvn_swe_com

; Process keywords

  if keyword_set(ddd) then ddd = 1 else ddd = 0
  if keyword_set(mom) then mom = 1 else mom = 0
  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne 6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then obins = reform(abins # dbins, 96)
  
  kp_path = getenv('ROOT_DATA_DIR') + 'maven/data/sci/swe/kp'
  froot = 'mvn_swe_kp_'
  
  finfo = file_info(kp_path)
  if (not finfo.exists) then begin
    print,"KP directory does not exist: ",kp_path
    return
  endif

; Load data one day at a time

  oneday = 86400D
  trange = minmax(time_double(trange))
  tstr = time_struct(trange)
  ndays = tstr[1].daynum - tstr[0].daynum + 1

  t0 = tstr[0]
  t0.hour = 0
  t0.min = 0
  t0.sec = 0
  t0.fsec = 0D
  t0.sod = 0D
  t0 = time_double(t0)
  
  for i=0,(ndays-1) do begin
    t1 = t0 + double(i)*oneday
    t2 = t1 + oneday

    mvn_swe_load_l0, [t1,t2]

; Calculate the energy shape parameter

    mvn_swe_shape_par, pans=pans

; Calculate the spacecraft potential

    mvn_swe_sc_pot

; Calculate the density and temperature

    if (ddd) then mvn_swe_n3d, obins=obins, pans=more_pans $
             else mvn_swe_n1d, mom=mom, pans=more_pans
    
    pans = [pans, more_pans]

; Determine the parallel and anti-parallel energy fluxes
;   Exclude bins that straddle 90 degrees pitch angle

    npts = n_elements(a2)
    t = dblarr(npts)
    eflux_pos_lo = fltarr(npts)
    eflux_pos_md = eflux_pos_lo
    eflux_pos_hi = eflux_pos_lo
    eflux_neg_lo = eflux_pos_lo
    eflux_neg_md = eflux_pos_lo
    eflux_neg_hi = eflux_pos_lo

    cnts_pos_lo = eflux_pos_lo
    cnts_pos_md = eflux_pos_lo
    cnts_pos_hi = eflux_pos_lo
    cnts_neg_lo = eflux_pos_lo
    cnts_neg_md = eflux_pos_lo
    cnts_neg_hi = eflux_pos_lo

    var_pos_lo = eflux_pos_lo
    var_pos_md = eflux_pos_lo
    var_pos_hi = eflux_pos_lo
    var_neg_lo = eflux_pos_lo
    var_neg_md = eflux_pos_lo
    var_neg_hi = eflux_pos_lo
 
    pad = mvn_swe_getpad(a2[0].time)
    energy = pad.energy[*,0]

    endx_lo = where((energy ge   5.) and (energy lt  100.), nlo)
    endx_md = where((energy ge 100.) and (energy lt  500.), nmd)
    endx_hi = where((energy ge 500.) and (energy lt 1000.), nhi)

    midpa = !pi/2.
  
    for i=0L,(npts-1L) do begin
      pad = mvn_swe_getpad(a2[i].time, units='counts')

      cnts = pad.data
      sig2 = pad.var   ; variance with digitization noise
      
      pad = conv_units(pad,'eflux')

      t[i] = pad.time 
    
      ipos = where(pad.pa_max[63,*] lt midpa, npos)
      ineg = where(pad.pa_min[63,*] gt midpa, nneg)
      eflux_pos = total(pad.data[*,ipos],2,/nan)/float(npos)
      eflux_neg = total(pad.data[*,ineg],2,/nan)/float(nneg)
      cnts_pos = total(cnts[*,ipos],2)
      cnts_neg = total(cnts[*,ineg],2)
      var_pos = total(sig2[*,ipos],2)
      var_neg = total(sig2[*,ineg],2)
    
      eflux_pos_lo[i] = total(eflux_pos[endx_lo],/nan)/float(nlo)
      eflux_pos_md[i] = total(eflux_pos[endx_md],/nan)/float(nmd)
      eflux_pos_hi[i] = total(eflux_pos[endx_hi],/nan)/float(nhi)
      cnts_pos_lo[i] = total(cnts_pos[endx_lo])
      cnts_pos_md[i] = total(cnts_pos[endx_md])
      cnts_pos_hi[i] = total(cnts_pos[endx_hi])
      var_pos_lo[i] = total(var_pos[endx_lo])
      var_pos_md[i] = total(var_pos[endx_md])
      var_pos_hi[i] = total(var_pos[endx_hi])

      eflux_neg_lo[i] = total(eflux_neg[endx_lo],/nan)/float(nlo)
      eflux_neg_md[i] = total(eflux_neg[endx_md],/nan)/float(nmd)
      eflux_neg_hi[i] = total(eflux_neg[endx_hi],/nan)/float(nhi)
      cnts_neg_lo[i] = total(cnts_neg[endx_lo])
      cnts_neg_md[i] = total(cnts_neg[endx_md])
      cnts_neg_hi[i] = total(cnts_neg[endx_hi])
      var_neg_lo[i] = total(var_neg[endx_lo])
      var_neg_md[i] = total(var_neg[endx_md])
      var_neg_hi[i] = total(var_neg[endx_hi])
    endfor

    sdev_pos_lo = eflux_pos_lo * (sqrt(var_pos_lo)/cnts_pos_lo)
    sdev_pos_md = eflux_pos_md * (sqrt(var_pos_md)/cnts_pos_md)
    sdev_pos_hi = eflux_pos_hi * (sqrt(var_pos_hi)/cnts_pos_hi)
    sdev_neg_lo = eflux_neg_lo * (sqrt(var_neg_lo)/cnts_neg_lo)
    sdev_neg_md = eflux_neg_md * (sqrt(var_neg_md)/cnts_neg_md)
    sdev_neg_hi = eflux_neg_hi * (sqrt(var_neg_hi)/cnts_neg_hi)

    store_data,'mvn_swe_efpos_5_100',data={x:t, y:eflux_pos_lo, dy:sdev_pos_lo}
    store_data,'mvn_swe_efpos_100_500',data={x:t, y:eflux_pos_md, dy:sdev_pos_md}
    store_data,'mvn_swe_efpos_500_1000',data={x:t, y:eflux_pos_hi, dy:sdev_pos_hi}
  
    store_data,'mvn_swe_efneg_5_100',data={x:t, y:eflux_neg_lo, dy:sdev_neg_lo}
    store_data,'mvn_swe_efneg_100_500',data={x:t, y:eflux_neg_md, dy:sdev_neg_md}
    store_data,'mvn_swe_efneg_500_1000',data={x:t, y:eflux_neg_hi, dy:sdev_neg_hi}
  
    eflux_lo = fltarr(npts,2)
    eflux_lo[*,0] = eflux_pos_lo
    eflux_lo[*,1] = eflux_neg_lo
    vname = 'mvn_swe_ef_5_100'
    store_data,vname,data={x:t, y:eflux_lo, v:[0,1]}
    ylim,vname,0,0,1
    options,vname,'labels',['pos','neg']
    options,vname,'labflag',1
  
    eflux_md = fltarr(npts,2)
    eflux_md[*,0] = eflux_pos_md
    eflux_md[*,1] = eflux_neg_md
    vname = 'mvn_swe_ef_100_500'
    store_data,vname,data={x:t, y:eflux_md, v:[0,1]}
    ylim,vname,0,0,1  
    options,vname,'labels',['pos','neg']
    options,vname,'labflag',1
  
    eflux_hi = fltarr(npts,2)
    eflux_hi[*,0] = eflux_pos_hi
    eflux_hi[*,1] = eflux_neg_hi
    vname = 'mvn_swe_ef_500_1000'
    store_data,vname,data={x:t, y:eflux_hi, v:[0,1]}
    ylim,vname,0,0,1  
    options,vname,'labels',['pos','neg']
    options,vname,'labflag',1
  
    pans = [pans, 'mvn_swe_efpos_5_100', 'mvn_swe_efpos_100_500', 'mvn_swe_efpos_500_1000', $
                  'mvn_swe_efneg_5_100', 'mvn_swe_efneg_100_500', 'mvn_swe_efneg_500_1000'   ]

; Store the results in tplot save/restore file(s)

    tstart = time_struct(t1)
    yyyy = string(tstart.year, format='(i4.4)')
    mm = string(tstart.month, format='(i2.2)')
    dd = string(tstart.date, format='(i2.2)')

    path = kp_path + '/' + yyyy
    finfo = file_info(path)
    if (not finfo.exists) then file_mkdir, path
    
    path = path + '/' + mm
    finfo = file_info(path)
    if (not finfo.exists) then file_mkdir, path

    fname = path + '/' + froot + yyyy + mm + dd

    tplot_save, pans, file=fname

  endfor

  return

end
