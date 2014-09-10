;+
;PROCEDURE:   mvn_swe_sumplot
;PURPOSE:
;  Plots information generated by MAVEN SWEA APID's.
;
;  See 'mvn_swe_load_l0.pro' for details.
;
;USAGE:
;  mvn_swe_sumplot
;
;INPUTS:
;
;KEYWORDS:
;
;       VNORM:        Subtract nominal values from all housekeeping voltages and plot all
;                     voltage differences in a single panel.  Default = 1 (yes).
;
;       CMDCNT:       Plot the SWEA command counter.
;
;       SFLG:         Plot Energy Spectra and PAD's as spectrograms.  Default = 1 (yes).
;
;       PAD_E:        PAD energy to plot.  Default = 280 eV.
;
;       PAD_SMO:      Number of PAD energy bins to smooth over.
;
;       A4_SUM:       Force sum mode for A4 and A5.  Not needed for EM or for FM post ATLO.
;
;       EUNITS:       Units for plotting energy spectra (A4 and A5).  Default = 'crate'.
;
;       TFIRST:       Earliest time to plot.  (Used for realtime plotting loop.)
;
;       TITLE:        Title of TPLOT window.
;
;       TSPAN:        Maximum number of hours to plot.  Default = plot all data.
;
;       APID:         APID's to plot.  Housekeeping (APID 28) is always plotted.  3D
;                     distributions (A0 and A1) are never plotted.  (Use swe_3d_snap to
;                     display A0 and A1.)  This keyword controls plotting of A2-A5.
;                     Default: ['A2','A4'].
;
;       HSK:          String array indicating additional housekeeping panels to plot
;                     (e.g., HSK = ['MCPHV'] during HV ramps).  Default = [''].
;
;       LUT:          Plot the active LUT.
;
;       SIFCTL:       Plot SIF control register bits.
;
;       TIMING:       Plot packet timing.  Useful to identify instrument mode and
;                     dropped packets.  Default = 0 (no).
;
;       PNG:          Create a PNG image and place it in the default location.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:44:22 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15670 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sumplot.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro mvn_swe_sumplot, vnorm=vnorm, cmdcnt=cmdcnt, sflg=sflg, pad_e=pad_e, a4_sum=a4_sum, $
                     tfirst=tfirst, title=title, tspan=tspan, apid=apid, hsk=hsk, $
                     lut=lut, timing=timing, sifctl=sifctl, tplot_vars_out=pans, $
                     eunits=eunits, png=png, pad_smo=smo

  @mvn_swe_com

  if not keyword_set(vnorm) then vflg = 1 else vflg = fix(vflg)
  if not keyword_set(sflg) then sflg = 1 else sflg = fix(sflg)
  if not keyword_set(pad_e) then pad_e = 280.
  if not keyword_set(smo) then smo = 1
  if keyword_set(a4_sum) then a4_sum = 1 else a4_sum = 0
  if (data_type(eunits) ne 7) then eunits = 'crate'
  if keyword_set(tfirst) then tfirst = time_double(tfirst) else tfirst = 0D
  if keyword_set(timing) then tflg = 1 else tflg = 0
  if keyword_set(png) then dopng = 1 else dopng = 0
  
  if not keyword_set(apid) then apid = ['A2','A4']
  
  plotap = replicate(0,6)
  for i=0,(n_elements(apid)-1) do begin
    case apid[i] of
      'A0' : print,"Plot A0 with swe_3d_snap"
      'A1' : print,"Plot A1 with swe_3d_snap,/archive"
      'A2' : plotap[2] = 1
      'A3' : plotap[3] = 1
      'A4' : plotap[4] = 1
      'A5' : plotap[5] = 1
      else : ; do nothing
    endcase
  endfor
  
  tsp = [0D]
  pans = ['']
  pdT = ['']
  pdC = ['']
  TClab = replicate('',8)
  TCcol = round(findgen(8)*(247./7.)) + 7
  Vlab = TClab
  Tlab = TClab[0:2]

  dTmax = 10.
  dCmax = 10.

; SWEA Housekeeping (APID 28)
;
; Digital Housekeeping Register bit definitions
;
;   Bit    Definition
; ------------------------------------------------------------
;     0    Command Parity Error in previous step
;     1    Command Framing Error in previous step
;     2    NR Supply Enable
;     3    MCP Supply Enable
;     4    NR Supply Arm
;     5    MCP Supply Arm
;     6    HV Enable Allow
;     7    Spare (set to zero)
;     8    LUT write error
;     9    DAC write error
;    10    Test Pulser Enable
;    11    Actuator State (always zero)
;    12    Spare (set to zero)
;    13    Spare (set to zero)
;    14    Spare (set to zero)
;    15    Spare (set to zero)
; ------------------------------------------------------------
;
; SIF Control bit definitions
;
; Digital Housekeeping Register bit definitions
;   Normal science operation is bits 0 and 15 on, all others off.
;
;   Bit    Definition
; ------------------------------------------------------------
;     0    HV enable allow      (same as HSKREG[6])
;     1    HV sync enable       (always zero - never used)
;     2    Test pulser enable   (same as HSKREG[10])
;     3    Spare (set to zero)
;     4    Spare (set to zero)
;     5    Spare (set to zero)
;     6    Spare (set to zero)
;     7    Spare (set to zero)
;     8    Analyzer diagnostic mode
;     9    Deflector 1 diagnostic mode
;    10    Deflector 2 diagnostic mode
;    11    V0 diagnostic mode
;    12    Spare (set to zero)
;    13    Spare (set to zero)
;    14    Spare (set to zero)
;    15    Sweep Enable
; ------------------------------------------------------------

  if (data_type(swe_hsk) eq 8) then begin
    tmin = min(swe_hsk.time, max=tmax)
    tsp = [tsp, tmin, tmax]

    if (vflg) then vnorm = [28., 12., 5., 3.3, 2.5] else vnorm = replicate(0.,5)

    store_data,'LVPST' ,data={x:swe_hsk.time, y:swe_hsk.LVPST}
    store_data,'MCPHV' ,data={x:swe_hsk.time, y:swe_hsk.MCPHV}
    store_data,'NRV'   ,data={x:swe_hsk.time, y:swe_hsk.NRV}
    store_data,'ANALV' ,data={x:swe_hsk.time, y:swe_hsk.ANALV}
    store_data,'DEF1V' ,data={x:swe_hsk.time, y:swe_hsk.DEF1V}
    store_data,'DEF2V' ,data={x:swe_hsk.time, y:swe_hsk.DEF2V}
    store_data,'V0V'   ,data={x:swe_hsk.time, y:swe_hsk.V0V}
    store_data,'ANALT' ,data={x:swe_hsk.time, y:swe_hsk.ANALT}
    store_data,'P12V'  ,data={x:swe_hsk.time, y:(swe_hsk.P12V-vnorm[1])}
    store_data,'N12V'  ,data={x:swe_hsk.time, y:(swe_hsk.N12V+vnorm[1])}
    store_data,'MCP28V',data={x:swe_hsk.time, y:(swe_hsk.MCP28V-vnorm[0])}
    store_data,'NR28V' ,data={x:swe_hsk.time, y:(swe_hsk.NR28V-vnorm[0])}
    store_data,'DIGT'  ,data={x:swe_hsk.time, y:swe_hsk.DIGT}
    store_data,'P2P5DV',data={x:swe_hsk.time, y:(swe_hsk.P2P5DV-vnorm[4])}
    store_data,'P5DV'  ,data={x:swe_hsk.time, y:(swe_hsk.P5DV-vnorm[2])}
    store_data,'P3P3DV',data={x:swe_hsk.time, y:(swe_hsk.P3P3DV-vnorm[3])}
    store_data,'P5AV'  ,data={x:swe_hsk.time, y:(swe_hsk.P5AV-vnorm[2])}
    store_data,'N5AV'  ,data={x:swe_hsk.time, y:(swe_hsk.N5AV+vnorm[2])}
    store_data,'P28V'  ,data={x:swe_hsk.time, y:(swe_hsk.P28V-vnorm[0])}

   store_data,'TV_frame',data={x:[0D], y:replicate(-100.,1,7), v:findgen(7)} 
 
    if (vflg) then begin

     options,'P28V',  'color',TCcol[0]   ; magenta
      options,'P12V',  'color',TCcol[1]   ; blue
      options,'N12V',  'color',TCcol[2]   ; cyan
      options,'P5AV',  'color',TCcol[3]   ; green
      options,'N5AV',  'color',TCcol[4]   ; yellow
      options,'P5DV',  'color',TCcol[5]   ; orange
      options,'P3P3DV','color',TCcol[6]   ; red

      store_data,'VoltsC',data=['TV_frame','P28V','P12V','N12V', $
                                'P5AV','N5AV','P5DV','P3P3DV']  ; skipping P2P5DV
      
      ylim,'VoltsC',-5,5,0
      options,'VoltsC','ytitle','Volts'
      options,'VoltsC','yticks',2
      options,'VoltsC','yminor',5
      options,'VoltsC','labflag',1
      options,'VoltsC','labels',['+28 V','+12 V','-12 V','+5 V','-5 V','5 DV','3.3 DV']
      vpans = ['VoltsC']

   endif else begin

     options,'P12V',  'color',TCcol[0]   ; magenta
      options,'N12V',  'color',TCcol[1]   ; blue
      options,'MCP28V','color',TCcol[2]   ; cyan
      options,'NR28V', 'color',TCcol[3]   ; green
      options,'P28V',  'color',TCcol[4]   ; yellow

     options,'P2P2DV','color',TCcol[0]   ; magenta
      
      options,'P3P3DV','color',TCcol[1]   ; blue
      options,'P5DV',  'color',TCcol[2]   ; cyan
      options,'P5AV',  'color',TCcol[3]   ; green
      options,'N5AV',  'color',TCcol[4]   ; yellow
      options,'NRV',   'color',TCcol[5]   ; orange
  
      store_data,'VoltsA',data=['TV_frame','P12V','N12V','MCP28V','NR28V','P28V']
      store_data,'VoltsB',data=['TV_frame','P2P5DV','P3P3DV','P5DV','P5AV','N5AV','NRV']

      ylim,'VoltsA',-15,35,0
      options,'VoltsA','yminor',5
      options,'VoltsA','labflag',1
      options,'VoltsA','labels',['+12 V','-12 V','MCP 28V','NR 28V','+28 V','','']

     ylim,'VoltsB',-6,6,0
      options,'VoltsB','yticks',2
      options,'VoltsB','yminor',6
      options,'VoltsB','labflag',1
      options,'VoltsB','labels',['+2.5 DV','+3.3 DV','+5 DV','+5 V','-5 V','NRV','']

     vpans = ['VoltsA','VoltsB']

   endelse

    store_data,'Temps',data=['TV_frame','LVPST','ANALT','DIGT']
    options,'ANALT','color',TCcol[0]  ; magenta
    options,'DIGT', 'color',TCcol[1]  ; blue
    options,'LVPST','color',TCcol[2]  ; cyan
;    ylim,'Temps',20,35,0
    ylim,'Temps',0,0,0
;    options,'Temps','yticks',3
;    options,'Temps','yminor',5
    options,'Temps','labflag',1
    options,'Temps','labels',['ANALT','DIGT','LVPST','','','','']
  
    store_data,'HSKREG',data={x:swe_hsk.time, y:transpose(swe_hsk.HSKREG), v:indgen(16)}
    options,'HSKREG','spec',1
    ylim,'HSKREG',0,12,0
    zlim,'HSKREG',0,1,0
    options,'HSKREG','yticks',3
    options,'HSKREG','yminor',4
    options,'HSKREG','ytitle','Dig HSK'
    options,'HSKREG','x_no_interp',1
    options,'HSKREG','y_no_interp',1
    options,'HSKREG','no_color_scale',1
    options,'HSKREG','panel_size',0.5

    dchsk = swe_hsk.npkt - shift(swe_hsk.npkt,1)
    dthsk = swe_hsk.time - shift(swe_hsk.time,1)
    store_data,'dchsk',data={x:swe_hsk[1:*].time, y:dchsk[1:*]}
    store_data,'dthsk',data={x:swe_hsk[1:*].time, y:dthsk[1:*]}
    options,'dchsk','ytitle','dN (28)'
    options,'dchsk','psym',5
    options,'dthsk','ytitle','dT (28)'
    options,'dthsk','psym',5
    options,'dthsk','ynozero',1
    options,'dchsk','color',TCcol[0]
    options,'dthsk','color',TCcol[0]

    dCmax = dCmax > max(dchsk,/nan)
    dTmax = dTmax > max(dthsk,/nan)

    pans = [pans,'HSKREG',vpans,'Temps']
    pdC = [pdC,'dchsk']
    pdT = [pdT,'dthsk']
    TClab[0] = '28'

  endif

; 3D Distributions, Survey (APID A0)
; Don't plot data (which is done with swe_3d_snap), just plot packet stats


  if (data_type(a0) eq 8) then begin      
    tmin = min(a0.time, max=tmax)
    tsp = [tsp, tmin, tmax]

    if (n_elements(a0) gt 1L) then begin
      dca0 = a0.npkt - shift(a0.npkt,1)
      dta0 = a0.time - shift(a0.time,1)
      store_data,'dca0',data={x:a0[1:*].time, y:dca0[1:*]}
      store_data,'dta0',data={x:a0[1:*].time, y:dta0[1:*]}
      options,'dca0','ytitle','dN (A0)'
      options,'dca0','psym',5
      options,'dta0','ytitle','dT (A0)'
      options,'dta0','psym',5
      options,'dta0','ynozero',1
      options,'dca0','color',TCcol[1]
      options,'dta0','color',TCcol[1]
      
      dCmax = dCmax > max(dca0,/nan)
      dTmax = dTmax > max(dta0,/nan)

      pdC = [pdC,'dca0']
      pdT = [pdT,'dta0']
      TClab[1] = 'A0'
    endif
  endif

; 3D Distributions, Archive (APID A1)
; Don't plot data (which is done with swe_3d_snap), just plot packet stats


  if (data_type(a1) eq 8) then begin
    tmin = min(a1.time, max=tmax)
    tsp = [tsp, tmin, tmax]

    if (n_elements(a2) gt 1L) then begin
      dca1 = a1.npkt - shift(a1.npkt,1)
      dta1 = a1.time - shift(a1.time,1)
      store_data,'dca1',data={x:a1[1:*].time, y:dca1[1:*]}
      store_data,'dta1',data={x:a1[1:*].time, y:dta1[1:*]}
      options,'dca1','ytitle','dN (A1)'
      options,'dca1','psym',5
      options,'dta1','ytitle','dT (A1)'
      options,'dta1','psym',5
      options,'dta1','ynozero',1
      options,'dca1','color',TCcol[2]
      options,'dta1','color',TCcol[2]
      
      dCmax = dCmax > max(dca1,/nan)
      dTmax = dTmax > max(dta1,/nan)

      pdC = [pdC,'dca1']
      pdT = [pdT,'dta1']
      TClab[2] = 'A1'

   endif
  endif

; PAD Spectra, Survey (APID A2)

  if (data_type(a2) eq 8) then begin
    tmin = min(a2.time, max=tmax)
    tsp = [tsp, tmin, tmax]

    n_e = swe_ne[a2.group]               ; number of energy channels
    dt = 2D*swe_duty/(6D*double(n_e))    ; integration time for each energy/deflector bin
                                         ; each PAD bin accumulates for one deflector bin

    npkt = n_elements(a2)                ; number of packets
    x = dblarr(npkt)
    y = fltarr(npkt,16)
    for i=0L,(npkt-1L) do begin
      de = min(abs(swe_swp[0:(n_e[i]-1),a2[i].group] - pad_e),j)
      x[i] = a2[i].time + 1.95D*(double(j) + 0.5D)/double(n_e[i])  ; center time
      a2dat = smooth(a2[i].data,[1,smo])                           ; smooth in energy
      y[i,*] = transpose(a2dat[*,j])/dt[i]                         ; count rate
    endfor

; Correct for deadtime.

    yc = y/(1. - swe_dead*y)
    

   pad_s = strtrim(string(round(pad_e)),2)
    pname = 'swe_a2_' + pad_s
 
    store_data,pname,data={x:x, y:yc, v:findgen(16)}
    options,pname,'ytitle',('E PAD (' + pad_s + ')')
    if (sflg) then begin
      options,pname,'spec',1
      ylim,pname,0,0,0
      zlim,pname,0,0,1
      options,pname,'x_no_interp',1
      options,pname,'y_no_interp',1
    endif else begin
      options,pname,'spec',0
      ylim,pname,0,0,1
    endelse
    
    mvn_swe_magdir, a2.time, a2.Baz, a2.Bel, Baz, Bel
    Baz = Baz*!radeg
    Bel = Bel*!radeg + 90.
    
    Bdir = fltarr(n_elements(a2),2)
    Bdir[*,0] = Baz
    Bdir[*,1] = Bel

    mname = 'swe_mag_svy'
    store_data,mname,data={x:(a2.time + 1.5D), y:Bdir, z:[0,1]}
    ylim,mname,0,360,0
    options,mname,'ytitle','SWE MAG'
    options,mname,'yticks',4
    options,mname,'yminor',4
    options,mname,'labels',['AZ','EL+90']
    options,mname,'labflag',1
    options,mname,'psym',3

    if (n_elements(a2) gt 1L) then begin
      dca2 = a2.npkt - shift(a2.npkt,1)
      dta2 = a2.time - shift(a2.time,1)
      store_data,'dca2',data={x:a2[1:*].time, y:dca2[1:*]}
      store_data,'dta2',data={x:a2[1:*].time, y:dta2[1:*]}
      options,'dca2','ytitle','dN (A2)'
      options,'dca2','psym',5
      options,'dta2','ytitle','dT (A2)'
      options,'dta2','psym',5
      options,'dta2','ynozero',1
      options,'dca2','color',TCcol[3]
      options,'dta2','color',TCcol[3]
      
      dCmax = dCmax > max(dca2,/nan)
      dTmax = dTmax > max(dta2,/nan)

      pdC = [pdC,'dca2']
      pdT = [pdT,'dta2']
      TClab[3] = 'A2'
    endif
    
    if (plotap[2]) then pans = [pans,pname,mname]

  endif

; PAD Spectra, Archive (APID A3)
 
  if (data_type(a3) eq 8) then begin
    tmin = min(a3.time, max=tmax)
    tsp = [tsp, tmin, tmax]

    n_e = swe_ne[a3.group]               ; number of energy channels
    dt = 2D*swe_duty/(6D*double(n_e))    ; integration time for each energy/deflector bin
                                         ; each PAD bin accumulates for one deflector bin

    npkt = n_elements(a3)                ; number of packets
    x = dblarr(npkt)
    y = fltarr(npkt,16)
    for i=0L,(npkt-1L) do begin
      if (n_e[i] gt 0.) then begin
        de = min(abs(swe_swp[0:(n_e[i]-1),a3[i].group] - pad_e),j)
        x[i] = a3[i].time + 1.95D*(double(j) + 0.5D)/double(n_e[i])  ; center time
        a3dat = smooth(a3[i].data,[1,smo])                           ; smooth in energy
        y[i,*] = transpose(a3dat[*,j])/dt[i]                         ; count rate
      
      endif
    endfor

; Correct for deadtime.

    yc = y/(1. - swe_dead*y)
    

   pad_s = strtrim(string(round(pad_e)),2)
    pname = 'swe_a3_' + pad_s
 
    store_data,pname,data={x:x, y:yc, v:findgen(16)}
    options,pname,'ytitle',('E PAD (' + pad_s + ')')
    if (sflg) then begin
      options,pname,'spec',1
      ylim,pname,0,0,0
      zlim,pname,0,0,1
      options,pname,'x_no_interp',1
      options,pname,'y_no_interp',1
    endif else begin
      options,pname,'spec',0
      ylim,pname,0,0,1
    endelse
    
    mvn_swe_magdir, a3.time, a3.Baz, a3.Bel, Baz, Bel
    Baz = Baz*!radeg
    Bel = Bel*!radeg + 90.
    
    Bdir = fltarr(n_elements(a3),2)
    Bdir[*,0] = Baz
    Bdir[*,1] = Bel

    mname = 'swe_mag_arc'
    store_data,mname,data={x:(a3.time + 1.5D), y:Bdir, z:[0,1]}
    ylim,mname,0,360,0
    options,mname,'yticks',4
    options,mname,'yminor',4
    options,mname,'labels',['AZ','EL']
    options,mname,'labflag',1
    options,mname,'psym',3

    if (n_elements(a3) gt 1L) then begin
      dca3 = a3.npkt - shift(a3.npkt,1)
      dta3 = a3.time - shift(a3.time,1)
      store_data,'dca3',data={x:a3[1:*].time, y:dca3[1:*]}
      store_data,'dta3',data={x:a3[1:*].time, y:dta3[1:*]}
      options,'dca3','ytitle','dN (A3)'
      options,'dca3','psym',5
      options,'dta3','ytitle','dT (A3)'
      options,'dta3','psym',5
      options,'dta3','ynozero',1
      options,'dca3','color',TCcol[4]
      options,'dta3','color',TCcol[4]
      
      dCmax = dCmax > max(dca3,/nan)
      dTmax = dTmax > max(dta3,/nan)

      pdC = [pdC,'dca3']
      pdT = [pdT,'dta3']
      TClab[4] = 'A3'
    endif

    if (plotap[3]) then pans = [pans,pname,mname]

  endif

; Energy Spectra, Survey (APID A4)

  if (data_type(a4) eq 8) then begin
    if (data_type(mvn_swe_engy) ne 8) then mvn_swe_getspec
    mvn_swe_convert_units, mvn_swe_engy, eunits

    x = mvn_swe_engy.time
    y = transpose(mvn_swe_engy.data)

    tmin = min(x, max=tmax)
    tsp = [tsp, tmin, tmax]
    
    v = swe_swp[*,0]
    Emin = min(v, max=Emax)

    ename = 'swe_a4'
    store_data,ename,data={x:x, y:y, v:v}

    if (sflg) then begin
      options,ename,'spec',1
      ylim,ename,Emin,Emax,1
      options,ename,'ytitle','Energy (eV)'
      options,ename,'yticks',0
      options,ename,'yminor',0
      zlim,ename,0,0,1
      options,ename,'ztitle',strupcase(eunits)
      options,ename,'y_no_interp',1
      options,ename,'x_no_interp',1
    endif else begin
      options,ename,'spec',0
      ylim,ename,1,1e6,1
      options,ename,'ytitle',strupcase(eunits)
      options,ename,'yticks',0
      options,ename,'yminor',0
    endelse

    if (n_elements(a4) gt 1L) then begin
      dca4 = a4.npkt - shift(a4.npkt,1)
      dta4 = a4.time - shift(a4.time,1)
      store_data,'dca4',data={x:a4[1:*].time, y:dca4[1:*]}
      store_data,'dta4',data={x:a4[1:*].time, y:dta4[1:*]}
      options,'dca4','ytitle','dN (A4)'
      options,'dca4','psym',5
      options,'dta4','ytitle','dT (A4)'
      options,'dta4','psym',5
      options,'dta4','ynozero',1
      options,'dca4','color',TCcol[5]
      options,'dta4','color',TCcol[5]

      dCmax = dCmax > max(dca4,/nan)
      dTmax = dTmax > max(dta4,/nan)

      pdC = [pdC,'dca4']
      pdT = [pdT,'dta4']
      TClab[5] = 'A4'
    endif
    
    if (plotap[4]) then pans = [pans,ename]
    
  endif

; Energy Spectra, Archive (APID A5)

  if (data_type(a5) eq 8) then begin
    if (data_type(mvn_swe_engy_arc) ne 8) then mvn_swe_getspec
    mvn_swe_convert_units, mvn_swe_engy_arc, eunits

    x = mvn_swe_engy_arc.time
    y = transpose(mvn_swe_engy_arc.data)

    tmin = min(x, max=tmax)
    tsp = [tsp, tmin, tmax]

    ename = 'swe_a5'
    store_data,ename,data={x:x, y:y, v:findgen(64)}

    if (sflg) then begin
      options,ename,'spec',1
      ylim,ename,0,64,0
      options,ename,'ytitle','E Bin'
      options,ename,'yticks',4
      options,ename,'yminor',4
      zlim,ename,0,0,1
      options,ename,'ztitle',strupcase(eunits)
      options,ename,'y_no_interp',1
      options,ename,'x_no_interp',1
    endif else begin
      options,ename,'spec',0
      ylim,ename,1,1e6,1
      options,ename,'ytitle',strupcase(eunits)
      options,ename,'yticks',0
      options,ename,'yminor',0
    endelse

    if (n_elements(a5) gt 1L) then begin
      dca5 = a5.npkt - shift(a5.npkt,1)
      dta5 = a5.time - shift(a5.time,1)
      store_data,'dca5',data={x:a5[1:*].time, y:dca5[1:*]}
      store_data,'dta5',data={x:a5[1:*].time, y:dta5[1:*]}
      options,'dca5','ytitle','dN (A5)'
      options,'dca5','psym',5
      options,'dta5','ytitle','dT (A5)'
      options,'dta5','psym',5
      options,'dta5','ynozero',1
      options,'dca5','color',TCcol[6]
      options,'dta5','color',TCcol[6]

      dCmax = dCmax > max(dca5,/nan)
      dTmax = dTmax > max(dta5,/nan)

      pdC = [pdC,'dca5']
      pdT = [pdT,'dta5']
      TClab[6] = 'A5'

   endif
    
    if (plotap[5]) then pans = [pans,ename]

  endif

; Fast Housekeeping (APID A6)
; Don't plot data (which is done with swe_plot_fhsk), just plot packet stats

; For A6, just plot the packet times.

  if (data_type(a6) eq 8) then begin      
    tmin = min(a6.time, max=tmax)
    tsp = [tsp, tmin, tmax]

    if (n_elements(a6) gt 0L) then begin
      store_data,'dca6',data={x:a6.time, y:replicate(1,n_elements(a6))}
      store_data,'dta6',data={x:a6.time, y:replicate(6D,n_elements(a6))}
      options,'dca6','ytitle','dN (A6)'
      options,'dca6','psym',5
      options,'dta6','ytitle','dT (A6)'
      options,'dta6','psym',5
      options,'dta6','ynozero',1
      options,'dca6','color',TCcol[7]
      options,'dta6','color',TCcol[7]
      
      dCmax = dCmax > max(dca0,/nan)
      dTmax = dTmax > max(dta0,/nan)

      pdC = [pdC,'dca6']
      pdT = [pdT,'dta6']
      TClab[7] = 'A6'
    endif
  endif

; Gather panels, set limits, and plot
  
  store_data,'dC_lab',data={x:[0D], y:replicate(-1.,1,8), v:findgen(8)}
  options,'dC_lab','spec',0

  options,'dC_lab','psym',3
  options,'dC_lab','labflag',1
  options,'dC_lab','labels',TClab
  pdC[0] = 'dC_lab'
  pdT[0] = 'dC_lab'

  store_data,'dC',data=pdC
  store_data,'dT',data=pdT
  options,'dC','ytitle','dN'
  options,'dT','ytitle','dT'
  ylim,'dC',1,100,1
  ylim,'dT',1,1000,1

  if (tflg) then pans = [pans[1:*],'dC','dT']

  if keyword_set(lut) then begin
    nhsk = n_elements(swe_hsk)
    lutnum = swe_hsk.ssctl
    chksum = bytarr(nhsk)
    
    for i=0L,(nhsk-1L) do chksum[i] = swe_hsk[i].chksum[lutnum[i] < 3]
    indx = where(lutnum gt 3, count)
    if (count gt 0L) then chksum[indx] = 'FF'XB  ; table load during turn-on

    store_data,'CHKSUM',data={x:swe_hsk.time, y:chksum}
    ylim,'CHKSUM',0,256,0
    options,'CHKSUM','ytitle','LUT'
    options,'CHKSUM','yticks',4
    options,'CHKSUM','yminor',4
    options,'CHKSUM','psym',10
    pans = [pans, 'CHKSUM']
  endif
  
  if keyword_set(SIFCTL) then begin
    sifctl = transpose(swe_hsk.sifctl)
    store_data,'SIFCTL',data={x:swe_hsk.time, y:sifctl, v:indgen(16)}
    options,'SIFCTL','spec',1
    ylim,'SIFCTL',0,15,0
    zlim,'SIFCTL',0,1,0
    options,'SIFCTL','yticks',3
    options,'SIFCTL','yminor',5
    options,'SIFCTL','ytitle','SIFCTL'
    options,'SIFCTL','x_no_interp',1
    options,'SIFCTL','y_no_interp',1
    options,'SIFCTL','no_color_scale',1
    pans = [pans, 'SIFCTL']
  endif
  
  if keyword_set(cmdcnt) then begin
    dNcmd = swe_hsk.cmdcnt - shift(swe_hsk.cmdcnt,1)
    store_data,'dNcmd',data={x:swe_hsk[1:*].time, y:dNcmd[1:*]}
    options,'dNcmd','ytitle','dNcmd'
    options,'dNcmd','psym',10
    pans = [pans, 'dNcmd']
  endif

  if (n_elements(tsp) eq 1) then begin
    print,"No data."
  endif else begin
    tmin = min(tsp[1:*], max=tmax)
    tmin = tmin > tfirst
    if keyword_set(tspan) then tmin = tmin > (tmax - tspan*3600D)
    timefit,[tmin,tmax]
  endelse
  
  if (data_type(title) eq 7) then tplot_options,'title',title

  if (data_type(hsk) eq 7) then pans = [pans, strupcase(hsk)]
  
  if (n_elements(pans) eq 1) then begin
    print,"Nothing to plot!"
    return
  endif

  tplot,pans
  timebar,t_cfg,/line
  
  if (dopng) then begin
    tstr = time_struct(tmin)
    yyyy = string(tstr.year,format='(i4.4)')
    mm = string(tstr.month,format='(i2.2)')
    dd = string(tstr.date,format='(i2.2)')
    itype = 'png'
    path = getenv('ROOT_DATA_DIR') + 'maven/pfp/swe/ql/' + yyyy + '/' + mm + '/'
    pngname = 'mvn_swe_ql_' + yyyy + mm + dd + '.' + itype

    current_dev = !d.name

    set_plot,'z'
      print,"Writing png file: ",pngname," ... "
      loadct2,34
      device,set_resolution=[1200,800]
      tplot,pans
      timebar,t_cfg,/line
      img = tvrd()
      tvlct,red,green,blue,/get
      write_image,path+pngname,itype,img,red,green,blue
      print,"done"
    set_plot,current_dev
  endif
  
  return

end