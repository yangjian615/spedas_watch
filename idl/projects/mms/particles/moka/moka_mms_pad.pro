;+
;Procedure:
;  moka_mms_pad
;
;Purpose:
;  Returns a pitch-angle-distribution from MMS FPI data (angle vs energy plot)
;  as well as energy spectrum in the omni, para, perp and anti-para directions.
;
;Calling Sequence:
;  structure = moka_mms_pad(bname, tname [,index] [,trange=trange] [,units=units],[,/norm],
;                                        [,nbin=nbin], [,vname=vname] [,/structure])
;
; INPUT:
;   bname: magnetic field, tplot-variable name, use burst data
;   tname: FPI data, tplot-variable such as "mms?_des_dist_brst"
;   index: (NOW DEPRECATED! after a struggle with apj2016_egyspec.pro)
;   trange:  Two element time range to constrain the requested data (See also mms_get_fpi_dist)
;   nbin: number of bins in the pitch-angle direction
;   vname: bulk flow velocity for frame transformation, tplot-variable name,
;          vname & tname should have the same data_rate
;   norm: Set this keyword for normalizing the data at each energy bin
;   units: units for the pitch-angle-distribution (pad). The default is 'eflux', but
;          phase-space-density 'df' is always used for energy spectrum.
;   pr___0: pitch angle range for the "para" spectrum, default = [0,45]
;   pr__90: pitch angle range for the "perp" spectrum, default = [45,135]
;   pr_180: pitch angle range for the "anti-para" spectrum, default = [135,180]
;
;Output:
;   a structure containing the result
;
;Example:
;  MMS> trange = '2015-11-04/'+['04:57:49','04:57:50']
;  MMS> tname = 'mms3_des_dist_brst'
;  MMS> bname = 'mms3_fgm_b_dmpa_brst_l2_bvec'
;  MMS> vname = 'mms3_des_bulk_dbcs_brst'
;  MMS> pad = moka_mms_pad(bname, tname, trange, vname=vname)
;  MMS> plotxyz,pad.PA, pad.EGY, pad.DATA,/noisotropic,/ylog,zlog=1,$
;               xrange=[0,180],zrange=[1e+5,1e+9],xtitle='pitch angle',ytitle='energy'
;
;History:
;  Created by Mitsuo Oka on 2016-05-15
;  Fixed energy bin mistake 2017-01-28 
;  Fixed para and anti-para mistake (thanks to R. Mistry) 2017-03-14
;  
;$LastChangedBy: moka $
;$LastChangedDate: 2017-04-01 12:05:33 -0700 (Sat, 01 Apr 2017) $
;$LastChangedRevision: 23077 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/moka/moka_mms_pad.pro $
;-
FUNCTION moka_mms_pad, bname, tname, trange, units=units, nbin=nbin, vname=vname, $
  norm=norm, ename=ename, pr___0 = pr___0, pr__90 = pr__90, pr_180=pr_180,$
  daPara=da,daPerp=da2,oclreal=oclreal, single_time=single_time, $
  vlm=vlm; An additional frametransformation
  compile_opt idl2

  ;------------
  ; initialize
  ;------------
  if undefined(tname) then message,'Please specify FPI data.'
  if undefined(bname) then message,'Please specify mag data.'
  if undefined(trange) then message, 'Please specify trange.'
  if undefined(nbin) then nbin = 18 ; Number of pitch-angle bins
  if undefined(da)    then da = 45.
  if undefined(da2)   then da2= 45.
  if undefined(pr___0) then pr___0 = [0., da]; para pitch-angle range
  if undefined(pr__90) then pr__90 = [90.-da2, 90.+da2]; perp pitch-angle range
  if undefined(pr_180) then pr_180 = [180.-da, 180.]; anti-para pitch-angle range


  if size(tname,/type) eq 7 then begin; if 'tname' is string...
    distime = mms_get_dist(tname,/time)
    if (time_double(trange[1]) lt distime[0]) or (max(distime) lt time_double(trange[0])) then begin
      stop
      message,'trange is out of '+tname+' time range.'
    endif
    dist    = mms_get_dist(tname,index,trange=trange,/structure)
    spc = strmid(tname,6,1)
  endif else stop
  
  USEERR = 0
  if ~undefined(ename) then begin
    if size(ename,/type) eq 7 then begin; if 'ename' is string...
      distErr = mms_get_dist(ename,index,trange=trange,/structure)
      USEERR = 1
    endif else stop
  endif

  units_lc = undefined(units) ? 'eflux' : strlowcase(units)
  units_gl = strmatch(units_lc,'eflux') ? 'eV/(cm!U2!N s sr eV)' : 's!U3!N / km!U6!N' 
  nmax = n_elements(dist)
  tr = [dist[0].TIME, dist[nmax-1].END_TIME]
  dr = !dpi/180.d0
  rd = 1.d0/dr

  ;-----------------------------
  ; Pitch-angle Bins
  ;-----------------------------
  kmax  = nbin
  pamin = 0.
  pamax = 180.
  dpa   = (pamax-pamin)/double(kmax); bin size
  wpa   = pamin + findgen(kmax)*dpa + 0.5*dpa; bin center values
  pa_bin = [pamin + findgen(kmax)*dpa, pamax]

  ;-----------------------------
  ; Energy Bins
  ;-----------------------------
  wegy  = dist[0].ENERGY[*,0,0]
  jmax  = n_elements(wegy)
  egy_bin = 0.5*(wegy + shift(wegy,-1))
  egy_bin[jmax-1] = 2.*wegy[jmax-1]-egy_bin[jmax-2]
  egy_bin0        = 2.*wegy[     0]-egy_bin[     0] > 0
  egy_bin = [egy_bin0, egy_bin] 

  ;----------------
  ; Prep
  ;----------------
  pad = fltarr(jmax, kmax)
  mmax  = 4
  f_dat = fltarr(jmax,mmax); Four elements for para, perp, anti-para and omni directions
  f_psd = fltarr(jmax,mmax)
  f_err = fltarr(jmax,mmax)
  f_cnt = fltarr(jmax,mmax)
  count_pad   = lonarr(jmax, kmax); number of events in each bin
  count_dat = lonarr(jmax, mmax)
  
  ;------------------------------------
  ; Magnetic field & Bulk Velocity
  ;------------------------------------
  bnrm = double(moka_tplot_average(bname, tr,norm=1)); .... Normalized!
  if undefined(vname) then begin
    Vbulk = [0.d0,0.d0,0.d0]
  endif else begin
    get_data,vname,data=DV
  endelse
  Vbulk_para = 0.d0
  Vbulk_perp = 0.d0
  Vbulk_vxb  = 0.d0
  Vbulk_exb  = 0.d0

  ;----------------
  ; Main Loop
  ;----------------

  for n=0,nmax-1 do begin

    ;----------------
    ;Sanitize Data.
    ;----------------
    if USEERR then begin
      moka_mms_clean_data,dist[n],output=data,units=units_lc,disterr=distErr[n]
    endif else begin
      moka_mms_clean_data,dist[n],output=data,units=units_lc
    endelse

    ;------------------------
    ; Bulk Velocity
    ;------------------------
    if ~undefined(vname) then begin
      result = min(DV.x-data.TIME,m,/nan,/abs)
      Vbulk = double(reform(DV.y[m,*]))
    endif
    vbpara =  bnrm[0]*Vbulk[0]+bnrm[1]*Vbulk[1]+bnrm[2]*Vbulk[2]
    vbperp = Vbulk - vbpara
    vbperp_abs = sqrt(vbperp[0]^2+vbperp[1]^2+vbperp[2]^2)
    vxb = [-Vbulk[1]*bnrm[2]+Vbulk[2]*bnrm[1],-Vbulk[2]*bnrm[0]+Vbulk[0]*bnrm[2],-Vbulk[0]*bnrm[1]+Vbulk[1]*bnrm[0]]
    vxbabs = sqrt(vxb[0]^2+vxb[1]^2+vxb[2]^2)
    vxbnrm = vxb/vxbabs
    exb = [vxb[1]*bnrm[2]-vxb[2]*bnrm[1],vxb[2]*bnrm[0]-vxb[0]*bnrm[2],vxb[0]*bnrm[1]-vxb[1]*bnrm[0]]
    exbabs = sqrt(exb[0]^2+exb[1]^2+exb[2]^2)
    exbnrm = exb/exbabs
    Vbulk_para += vbpara
    Vbulk_perp += vbperp_abs
    Vbulk_vxb  += vxbnrm[0]*Vbulk[0]+vxbnrm[1]*Vbulk[1]+vxbnrm[2]*Vbulk[2]
    Vbulk_exb  += exbnrm[0]*Vbulk[0]+exbnrm[1]*Vbulk[1]+exbnrm[2]*Vbulk[2]

    ;------------------------------------
    ; Particle Velocities & Pitch Angles
    ;------------------------------------
    
    ; Spherical to Cartesian
    erest = data.mass * !const.c^2 / 1e6; convert mass from eV/(km/s)^2 to eV
    vabs = !const.c * sqrt( 1 - 1/((data.ENERGY/erest + 1)^2) )  /  1000.;velocity in km/s
    sphere_to_cart, vabs, data.theta, data.phi, vx, vy, vz
    
    ; Frame transformation
;    if undefined(vlmpot) then begin
      if ~undefined(vname) then begin; Plasma rest-frame
        vx -= Vbulk[0]
        vy -= Vbulk[1]
        vz -= Vbulk[2]
      endif
;    endif else begin; Another frame (under development)
;      bvec = double(moka_tplot_average(bname, tr,norm=0))
;      moka_mms_vlm, vx, vy, vz, Vbulk, bvec, vlm
;    endelse
    
    ; Pitch angles
    dp  = (bnrm[0]*vx + bnrm[1]*vy + bnrm[2]*vz)/sqrt(vx^2+vy^2+vz^2)
    idx = where(dp gt  1.d0, ct) & if ct gt 0 then dp[idx] =  1.d0
    idx = where(dp lt -1.d0, ct) & if ct gt 0 then dp[idx] = -1.d0
    pa  = rd*acos(dp)
    
    ; Cartesian to Spherical
    cart_to_sphere, vx, vy, vz, vnew, theta, phi, /ph_0_360
    data.energy = erest*(1.d0/sqrt(1.d0-(vnew*1000.d0/!const.c)^2)-1.d0); eV
    data.phi    = phi
    data.theta  = theta
    data.pa     = pa

    ;------------------------
    ; DISTRIBUTE
    ;------------------------
    imax = n_elements(data.data_dat)
    
    for i=0,imax-1 do begin; for each particle
      
      ; Find energy bin
      result = min(egy_bin-data.energy[i],j,/abs)
      if egy_bin[j] gt data.energy[i] then j -= 1
      if j eq jmax then j -= 1
      
      ; Find pitch-angle bin
      result = min(pa_bin-data.pa[i],k,/abs)
      if pa_bin[k] gt data.pa[i] then k -= 1
      if k eq kmax then k -= 1
      
      ; pitch-angle distribution
      pad[j,k] += data.data_dat[i] 
      count_pad[j,k] += 1L

      ; energy spectrum (para, perp, anti-para)
      m = -1
      if (pr__90[0] le data.pa[i]) and (data.pa[i] le pr__90[1]) then begin
        m = 1
      endif else begin
        if (pr___0[0] le data.pa[i]) and (data.pa[i] le pr___0[1]) then m=0
        if (pr_180[0] le data.pa[i]) and (data.pa[i] le pr_180[1]) then m=2
      endelse
      if (m ge 0) and (m le 2) then begin
        f_dat[j,m] += data.data_dat[i]
        f_psd[j,m] += data.data_psd[i]
        f_err[j,m] += data.data_err[i]
        f_cnt[j,m] += data.data_cnt[i]
        count_dat[j,m] += 1L
      endif

      ; energy spectrum (omni-direction)
      m = 3
      f_dat[j,m] += data.data_dat[i]
      f_psd[j,m] += data.data_psd[i]
      f_err[j,m] += data.data_err[i]
      f_cnt[j,m] += data.data_cnt[i]
      count_dat[j,m] += 1L
      

    endfor; for each particle
  endfor; for n=0,nmax-1


  pad /= float(count_pad)
  f_dat /= float(count_dat)
  f_psd /= float(count_dat)
  f_err /= float(count_dat)
  f_cnt /= float(count_dat)
  
  vbulk_para /= float(nmax)
  vbulk_perp /= float(nmax)
  vbulk_vxb  /= float(nmax)
  vbulk_exb  /= float(nmax)

  ;---------------
  ; ANGLE PADDING
  ;---------------
  padnew = fltarr(jmax, kmax+2)
  padnew[0:jmax-1,1:kmax] = pad
  padnew[0:jmax-1,     0] = padnew[0:jmax-1,   1]
  padnew[0:jmax-1,kmax+1] = padnew[0:jmax-1,kmax]
  pad = padnew
  wpa_new = [wpa[0]-dpa,wpa,wpa[kmax-1]+dpa]
  wpa = wpa_new
  
  ;---------------
  ; NORMALIZE
  ;---------------
  padnorm = pad
  for j=0,jmax-1 do begin; for each energy
    peak = max(pad[j,0:kmax+1],/nan); find the peak
    if peak eq 0 then begin
      padnorm[j,0:kmax+1] = 0.
    endif else begin
      padnorm[j,0:kmax+1] /= peak
    endelse
  endfor
  if keyword_set(norm) then pad = padnorm
  
  ;----------------------------
  ; Effective one-count-level 
  ;----------------------------
  ; 'f_psd' is the PSD    averaged over time and angular ranges. 
  ; 'f_cnt' is the counts averaged over time and angular ranges. 
  ; 'count_dat is the total number of time and angular bins.  
  f_ocl = f_psd/(f_cnt*float(count_dat))

  ; Real one-count-level of the instrument in a sampling time and in an angular bin 
  if keyword_set(oclreal) then begin
    f_ocl = f_psd/f_cnt
  endif
  
  ;---------------
  ; OUTPUT
  ;---------------
    
  return, {egy:wegy, pa:wpa, data:transpose(pad), datanorm:transpose(padnorm), $
    numSlices: nmax, nbin:kmax, units:units_gl,$
    egyrange:[min(wegy),max(wegy)], parange:[min(wpa),max(wpa)], $
    spec___0:f_psd[*,0], spec__90:f_psd[*,1], spec_180:f_psd[*,2], spec_omn:f_psd[*,3], $
    cnts___0:f_cnt[*,0], cnts__90:f_cnt[*,1], cnts_180:f_cnt[*,2], cnts_omn:f_cnt[*,3], $
    oclv___0:f_ocl[*,0], oclv__90:f_ocl[*,1], oclv_180:f_ocl[*,2], oclv_omn:f_ocl[*,3], $
    eror___0:f_err[*,0], eror__90:f_err[*,1], eror_180:f_err[*,2], eror_omn:f_err[*,3], $
    trange:tr, vbulk_para:vbulk_para, vbulk_perp_abs:vbulk_perp, vbulk_vxb:vbulk_vxb, vbulk_exb:vbulk_exb, bnrm:bnrm, Vbulk:Vbulk}

END